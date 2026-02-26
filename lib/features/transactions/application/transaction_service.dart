import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/data/account_repository.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_model.dart';

part 'transaction_service.g.dart';

@riverpod
TransactionService transactionService(TransactionServiceRef ref) {
  return TransactionService(ref);
}

class TransactionService {
  final TransactionServiceRef ref;

  TransactionService(this.ref);

  /// Adds a real transaction (Debit or Credit) and updates related accounts.
  /// Follows the double-entry principle by adding a balancing split to 'system:external'.
  Future<void> addTransaction({
    required double amount, // Absolute value entered by user
    required TransactionType type,
    required String label,
    required DateTime date,
    required RealAccount realAccount,
    required VirtualAccount targetVirtualAccount, // The budget affected
    TransactionStep step = TransactionStep.completed,
    String? category,
    String? note,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final uuid = const Uuid();

    // Determine signs for the poles
    double realAmountSigned;
    double virtualAmountSigned;
    double counterpartyAmountSigned;
    String counterpartyAccountId = SystemAccounts.external;

    if (step == TransactionStep.pending &&
        (type == TransactionType.debit || type == TransactionType.credit)) {
      final committedAccount = await accountRepo.getVirtualAccountByType(
        user.uid,
        realAccount.id,
        VirtualAccountType.systemCommitted,
      );
      if (committedAccount == null)
        throw Exception("System committed account not found.");
      counterpartyAccountId = committedAccount.id;
    }

    switch (type) {
      case TransactionType.debit:
        // Movement: Internal Envelope -> External World (or Committed)
        realAmountSigned = step == TransactionStep.pending
            ? 0.0
            : -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
      case TransactionType.credit:
        // Movement: External World (or Committed) -> Internal Envelope
        realAmountSigned = step == TransactionStep.pending ? 0.0 : amount.abs();
        virtualAmountSigned = amount.abs();
        counterpartyAmountSigned = -amount.abs();
        break;
      default:
        // For provisions/transfers, use specialized methods (addTransfer)
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
    }

    final transaction = TransactionModel(
      id: uuid.v4(),
      ownerId: user.uid,
      realAccountId: realAccount.id,
      amount: realAmountSigned,
      type: type,
      transactionDate: date,
      label: label,
      category: category,
      note: note,
      status: TransactionStatus.none,
      step: step,
      splits: [
        // Internal Pole
        TransactionSplit(
          virtualAccountId: targetVirtualAccount.id,
          amount: virtualAmountSigned,
        ),
        // External Pole (Double-entry contra account)
        TransactionSplit(
          virtualAccountId: counterpartyAccountId,
          amount: counterpartyAmountSigned,
        ),
      ],
    );

    assert(transaction.isBalanced, "Transaction must be balanced");
    await repository.createTransaction(user.uid, transaction);
  }

  /// Adds a transaction split across multiple virtual accounts.
  /// Useful for "Ventilation" where a single expense affects multiple envelopes.
  Future<void> addSplitTransaction({
    required double totalAmount,
    required TransactionType type,
    required String label,
    required DateTime date,
    required RealAccount realAccount,
    required List<({VirtualAccount account, double amount})> splits,
    TransactionStep step = TransactionStep.completed,
    String? category,
    String? note,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    if (splits.isEmpty) throw Exception("At least one split is required");

    // Validate Total
    final sumSplits = splits.fold(0.0, (prev, s) => prev + s.amount);
    if ((sumSplits - totalAmount).abs() > 0.01) {
      throw Exception(
        "Total des ventilations ($sumSplits) ne correspond pas au montant total ($totalAmount)",
      );
    }

    final repository = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final uuid = const Uuid();

    // Prepare Splits
    List<TransactionSplit> transactionSplits = [];
    double counterpartyAmountSigned;
    String counterpartyAccountId = SystemAccounts.external;

    if (step == TransactionStep.pending &&
        (type == TransactionType.debit || type == TransactionType.credit)) {
      final committedAccount = await accountRepo.getVirtualAccountByType(
        user.uid,
        realAccount.id,
        VirtualAccountType.systemCommitted,
      );
      if (committedAccount == null)
        throw Exception("System committed account not found.");
      counterpartyAccountId = committedAccount.id;
    }

    if (type == TransactionType.debit) {
      // Debit: Envelopes decrease (negative), External increases (positive)
      // splits.amount is expected to be positive input by user
      for (final split in splits) {
        transactionSplits.add(
          TransactionSplit(
            virtualAccountId: split.account.id,
            amount: -split.amount.abs(),
          ),
        );
      }
      counterpartyAmountSigned = totalAmount.abs();
    } else if (type == TransactionType.credit) {
      // Credit: Envelopes increase (positive), External decreases (negative)
      for (final split in splits) {
        transactionSplits.add(
          TransactionSplit(
            virtualAccountId: split.account.id,
            amount: split.amount.abs(),
          ),
        );
      }
      counterpartyAmountSigned = -totalAmount.abs();
    } else {
      throw Exception("Split transactions only supported for Debit/Credit");
    }

    // Add Counterparty
    transactionSplits.add(
      TransactionSplit(
        virtualAccountId: counterpartyAccountId,
        amount: counterpartyAmountSigned,
      ),
    );

    final transaction = TransactionModel(
      id: uuid.v4(),
      ownerId: user.uid,
      realAccountId: realAccount.id,
      amount: type == TransactionType.debit
          ? (step == TransactionStep.pending ? 0.0 : -totalAmount.abs())
          : (step == TransactionStep.pending ? 0.0 : totalAmount.abs()),
      type: type,
      transactionDate: date,
      label: label,
      category: category,
      note: note,
      status: TransactionStatus.none,
      step: step,
      splits: transactionSplits,
    );

    assert(transaction.isBalanced, "Transaction must be balanced");
    await repository.createTransaction(user.uid, transaction);
  }

  /// Adds a balance adjustment (correction) for a virtual account.
  /// Moves funds between the account and 'system:external-adjustment'.
  Future<void> addAdjustment({
    required double
    adjustmentAmount, // Positive to increase balance, negative to decrease
    required String label,
    required RealAccount realAccount,
    required VirtualAccount targetVirtualAccount,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    final uuid = const Uuid();

    final transaction = TransactionModel(
      id: uuid.v4(),
      ownerId: user.uid,
      realAccountId: realAccount.id,
      amount: adjustmentAmount, // Adjusts real balance too
      type: adjustmentAmount >= 0
          ? TransactionType.credit
          : TransactionType.debit,
      transactionDate: DateTime.now(),
      label: "[Ajustement] $label",
      status: TransactionStatus.corrected,
      step: TransactionStep.completed,
      splits: [
        // The account being adjusted
        TransactionSplit(
          virtualAccountId: targetVirtualAccount.id,
          amount: adjustmentAmount,
        ),
        // The source of the adjustment (The "Error" or "Ajustement" pole)
        TransactionSplit(
          virtualAccountId: SystemAccounts.externalAdjustment,
          amount: -adjustmentAmount,
        ),
      ],
    );

    assert(transaction.isBalanced);
    await repository.createTransaction(user.uid, transaction);
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    await repository.deleteTransaction(user.uid, transaction);
  }

  /// Adds an internal transfer between two virtual accounts (envelopes).
  /// If between the same Real Account: Creates one transaction with amount 0.
  /// If between different Real Accounts: Creates two balanced transactions via 'system:external'.
  Future<void> addTransfer({
    required double amount,
    required String label,
    required DateTime date,
    required VirtualAccount sourceVirtualAccount,
    required VirtualAccount targetVirtualAccount,
    String? category,
    String? note,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    final uuid = const Uuid();

    if (sourceVirtualAccount.realAccountId ==
        targetVirtualAccount.realAccountId) {
      // Same account transfer (Purely internal)
      final transaction = TransactionModel(
        id: uuid.v4(),
        ownerId: user.uid,
        realAccountId: sourceVirtualAccount.realAccountId,
        amount: 0.0,
        type: TransactionType.transfer,
        transactionDate: date,
        label: label,
        category: category,
        note: note,
        status: TransactionStatus.transferred,
        step: TransactionStep.completed,
        splits: [
          TransactionSplit(
            virtualAccountId: sourceVirtualAccount.id,
            amount: -amount.abs(),
          ),
          TransactionSplit(
            virtualAccountId: targetVirtualAccount.id,
            amount: amount.abs(),
          ),
        ],
      );
      await repository.createTransaction(user.uid, transaction);
    } else {
      // Cross-account transfer (Two bank movements)
      // 1. Debit Source Account
      final txSource = TransactionModel(
        id: uuid.v4(),
        ownerId: user.uid,
        realAccountId: sourceVirtualAccount.realAccountId,
        amount: -amount.abs(),
        type: TransactionType.transfer,
        transactionDate: date,
        label: "[Transfert Out] $label",
        category: category,
        note: note,
        status: TransactionStatus.toTransfer,
        step: TransactionStep.completed,
        splits: [
          TransactionSplit(
            virtualAccountId: sourceVirtualAccount.id,
            amount: -amount.abs(),
          ),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: amount.abs(),
          ),
        ],
      );

      // 2. Credit Target Account
      final txTarget = TransactionModel(
        id: uuid.v4(),
        ownerId: user.uid,
        realAccountId: targetVirtualAccount.realAccountId,
        amount: amount.abs(),
        type: TransactionType.transfer,
        transactionDate: date,
        label: "[Transfert In] $label",
        category: category,
        note: note,
        status: TransactionStatus.transferred,
        step: TransactionStep.completed,
        splits: [
          TransactionSplit(
            virtualAccountId: targetVirtualAccount.id,
            amount: amount.abs(),
          ),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: -amount.abs(),
          ),
        ],
      );

      await repository.createTransactions(user.uid, [txSource, txTarget]);
    }
  }

  Future<void> updateTransaction({
    required TransactionModel originalTransaction,
    required double amount,
    required TransactionType type,
    required String label,
    required DateTime date,
    required RealAccount realAccount,
    required VirtualAccount targetVirtualAccount,
    TransactionStep? step,
    String? category,
    String? note,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);

    // Determine signs (same as addTransaction)
    double realAmountSigned;
    double virtualAmountSigned;
    double counterpartyAmountSigned;
    String counterpartyAccountId = SystemAccounts.external;

    final targetStep = step ?? originalTransaction.step;

    if (targetStep == TransactionStep.pending &&
        (type == TransactionType.debit || type == TransactionType.credit)) {
      final committedAccount = await accountRepo.getVirtualAccountByType(
        user.uid,
        realAccount.id,
        VirtualAccountType.systemCommitted,
      );
      if (committedAccount == null)
        throw Exception("System committed account not found.");
      counterpartyAccountId = committedAccount.id;
    }

    switch (type) {
      case TransactionType.debit:
        realAmountSigned = targetStep == TransactionStep.pending
            ? 0.0
            : -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
      case TransactionType.credit:
        realAmountSigned = targetStep == TransactionStep.pending
            ? 0.0
            : amount.abs();
        virtualAmountSigned = amount.abs();
        counterpartyAmountSigned = -amount.abs();
        break;
      default:
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
    }

    final updatedTransaction = TransactionModel(
      id: originalTransaction.id, // Keep same ID
      ownerId: user.uid,
      realAccountId: realAccount.id,
      amount: realAmountSigned,
      type: type,
      transactionDate: date,
      label: label,
      category: category,
      note: note,
      status: originalTransaction.status, // Keep status? Or reset?
      step: targetStep,
      splits: [
        TransactionSplit(
          virtualAccountId: targetVirtualAccount.id,
          amount: virtualAmountSigned,
        ),
        TransactionSplit(
          virtualAccountId: counterpartyAccountId,
          amount: counterpartyAmountSigned,
        ),
      ],
    );

    assert(updatedTransaction.isBalanced);
    await repository.updateTransaction(
      user.uid,
      originalTransaction,
      updatedTransaction,
    );
  }

  Future<void> updateSplitTransaction({
    required TransactionModel originalTransaction,
    required double totalAmount,
    required TransactionType type,
    required String label,
    required DateTime date,
    required RealAccount realAccount,
    required List<({VirtualAccount account, double amount})> splits,
    TransactionStep? step,
    String? category,
    String? note,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    if (splits.isEmpty) throw Exception("At least one split is required");

    final sumSplits = splits.fold(0.0, (prev, s) => prev + s.amount);
    if ((sumSplits - totalAmount).abs() > 0.01) {
      throw Exception(
        "Total des ventilations ($sumSplits) ne correspond pas au montant total ($totalAmount)",
      );
    }

    final repository = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);

    List<TransactionSplit> transactionSplits = [];
    double counterpartyAmountSigned;
    String counterpartyAccountId = SystemAccounts.external;

    final targetStep = step ?? originalTransaction.step;

    if (targetStep == TransactionStep.pending &&
        (type == TransactionType.debit || type == TransactionType.credit)) {
      final committedAccount = await accountRepo.getVirtualAccountByType(
        user.uid,
        realAccount.id,
        VirtualAccountType.systemCommitted,
      );
      if (committedAccount == null)
        throw Exception("System committed account not found.");
      counterpartyAccountId = committedAccount.id;
    }

    if (type == TransactionType.debit) {
      for (final split in splits) {
        transactionSplits.add(
          TransactionSplit(
            virtualAccountId: split.account.id,
            amount: -split.amount.abs(),
          ),
        );
      }
      counterpartyAmountSigned = totalAmount.abs();
    } else if (type == TransactionType.credit) {
      for (final split in splits) {
        transactionSplits.add(
          TransactionSplit(
            virtualAccountId: split.account.id,
            amount: split.amount.abs(),
          ),
        );
      }
      counterpartyAmountSigned = -totalAmount.abs();
    } else {
      throw Exception("Split transactions only supported for Debit/Credit");
    }

    transactionSplits.add(
      TransactionSplit(
        virtualAccountId: counterpartyAccountId,
        amount: counterpartyAmountSigned,
      ),
    );

    final updatedTransaction = TransactionModel(
      id: originalTransaction.id,
      ownerId: user.uid,
      realAccountId: realAccount.id,
      amount: type == TransactionType.debit
          ? (targetStep == TransactionStep.pending ? 0.0 : -totalAmount.abs())
          : (targetStep == TransactionStep.pending ? 0.0 : totalAmount.abs()),
      type: type,
      transactionDate: date,
      label: label,
      category: category,
      note: note,
      status: originalTransaction.status,
      step: targetStep,
      splits: transactionSplits,
    );

    assert(updatedTransaction.isBalanced);
    await repository.updateTransaction(
      user.uid,
      originalTransaction,
      updatedTransaction,
    );
  }

  /// Confirms a pending transaction, changing its step to completed and moving its
  /// counterparty split from 'Solde Engagé' to 'system:external'.
  Future<void> confirmTransaction(TransactionModel originalTransaction) async {
    if (originalTransaction.step != TransactionStep.pending) {
      return; // Nothing to confirm
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);

    // Swap the counterparty split to external
    final newSplits = originalTransaction.splits.map((s) {
      if (s.isSystem) {
        return TransactionSplit(
          virtualAccountId: SystemAccounts.external,
          amount: s.amount,
        );
      }
      return s;
    }).toList();

    // The real amount now actually impacts the bank account
    double newAmount = 0.0;
    if (originalTransaction.type == TransactionType.debit) {
      // Find the envelope split to know the total amount
      final envelopeSplit = newSplits.firstWhere((s) => !s.isSystem);
      newAmount = envelopeSplit.amount; // Already negative
    } else if (originalTransaction.type == TransactionType.credit) {
      final envelopeSplit = newSplits.firstWhere((s) => !s.isSystem);
      newAmount = envelopeSplit.amount; // Already positive
    }

    // Edge case if splits are complex (split transaction): sum of non-system
    if (newSplits.length > 2) {
      newAmount = newSplits
          .where((s) => !s.isSystem)
          .fold(0.0, (p, s) => p + s.amount);
    }

    final updatedTransaction = TransactionModel(
      id: originalTransaction.id,
      ownerId: originalTransaction.ownerId,
      realAccountId: originalTransaction.realAccountId,
      amount: newAmount,
      type: originalTransaction.type,
      transactionDate: originalTransaction.transactionDate,
      label: originalTransaction.label,
      note: originalTransaction.note,
      payee: originalTransaction.payee,
      category: originalTransaction.category,
      status: originalTransaction.status,
      step: TransactionStep.completed, // Finalized!
      externalEntityId: originalTransaction.externalEntityId,
      valueDate: originalTransaction.valueDate,
      visibilityDate: originalTransaction.visibilityDate,
      syncDate: originalTransaction.syncDate,
      provisionDate: originalTransaction.provisionDate,
      splits: newSplits,
      importHash: originalTransaction.importHash,
    );

    assert(updatedTransaction.isBalanced);
    await repository.updateTransaction(
      user.uid,
      originalTransaction,
      updatedTransaction,
    );
  }

  /// Cancels a transaction, reversing its financial impact and marking it as cancelled.
  Future<void> cancelTransaction(TransactionModel originalTransaction) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);

    // To cancel without losing the record, we zero out the amounts and change the step.
    // The repository will handle reversing the original transaction's impact
    // and applying the new (zero) impact.
    final updatedTransaction = TransactionModel(
      id: originalTransaction.id,
      ownerId: originalTransaction.ownerId,
      realAccountId: originalTransaction.realAccountId,
      amount: 0.0, // Zero impact
      type: originalTransaction.type,
      transactionDate: originalTransaction.transactionDate,
      label: originalTransaction.label,
      category: originalTransaction.category,
      note: originalTransaction.note,
      status: originalTransaction.status,
      step: TransactionStep.cancelled,
      externalEntityId: originalTransaction.externalEntityId,
      valueDate: originalTransaction.valueDate,
      visibilityDate: originalTransaction.visibilityDate,
      syncDate: originalTransaction.syncDate,
      provisionDate: originalTransaction.provisionDate,
      importHash: originalTransaction.importHash,
      // Zero out all splits
      splits: originalTransaction.splits
          .map(
            (s) => TransactionSplit(
              virtualAccountId: s.virtualAccountId,
              amount: 0.0,
            ),
          )
          .toList(),
    );

    assert(updatedTransaction.isBalanced);
    await repository.updateTransaction(
      user.uid,
      originalTransaction,
      updatedTransaction,
    );
  }
}
