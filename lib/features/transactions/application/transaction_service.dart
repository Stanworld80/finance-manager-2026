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
    String? category,
    String? note,
    TransactionStep step = TransactionStep.completed,
    TransactionStatus status = TransactionStatus.none,
    String? recurringTransactionId,
    String? externalEntityId,
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
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
      case TransactionType.credit:
        // Movement: External World (or Committed) -> Internal Envelope
        realAmountSigned = amount.abs();
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
      recurringTransactionId: recurringTransactionId,
      externalEntityId: externalEntityId,
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
    String? category,
    String? note,
    TransactionStep step = TransactionStep.completed,
    TransactionStatus status = TransactionStatus.none,
    String? recurringTransactionId,
    String? externalEntityId,
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
          ? -totalAmount.abs()
          : totalAmount.abs(),
      type: type,
      transactionDate: date,
      label: label,
      category: category,
      note: note,
      status: TransactionStatus.none,
      step: step,
      recurringTransactionId: recurringTransactionId,
      externalEntityId: externalEntityId,
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

  Future<void> deleteTransaction({
    required TransactionModel transaction,
    bool deleteLinked = true,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    
    // Si c'est un virement lié et qu'on doit supprimer l'autre côté
    if (deleteLinked && transaction.linkedTransactionId != null) {
      final linkedTx = await repository.getTransactionById(
          user.uid, transaction.linkedTransactionId!);
      
      if (linkedTx != null) {
        // Pour éviter une récursion infinie ou une corruption on passe cascade
        // Normalement un runTransaction groupé serait parfait, mais la méthode 
        // deleteTransactions du repo n'existe pas encore.
        // Faisons la suppression séquentielle ou via ajout d'une méthode repo deleteTransactions.
        // En attendant, appel simple :
        await repository.deleteTransaction(user.uid, linkedTx);
      }
    }

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
    TransactionStep step = TransactionStep.completed,
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
        step: step,
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
      final idSource = uuid.v4();
      final idTarget = uuid.v4();

      // 1. Debit Source Account
      final txSource = TransactionModel(
        id: idSource,
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
        linkedTransactionId: idTarget,
        splits: [
          TransactionSplit(
            virtualAccountId: sourceVirtualAccount.id,
            amount: -amount.abs(),
          ),
          TransactionSplit(
            virtualAccountId: SystemAccounts.transferTransit,
            amount: amount.abs(),
          ),
        ],
      );

      // 2. Credit Target Account
      final txTarget = TransactionModel(
        id: idTarget,
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
        linkedTransactionId: idSource,
        splits: [
          TransactionSplit(
            virtualAccountId: targetVirtualAccount.id,
            amount: amount.abs(),
          ),
          TransactionSplit(
            virtualAccountId: SystemAccounts.transferTransit,
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
    String? externalEntityId,
    bool updateLinked = true,
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

    if (originalTransaction.linkedTransactionId != null) {
      counterpartyAccountId = SystemAccounts.transferTransit;
    }

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
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
      case TransactionType.credit:
        realAmountSigned = amount.abs();
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
      status: originalTransaction.status,
      step: targetStep,
      recurringTransactionId: originalTransaction.recurringTransactionId,
      linkedTransactionId: originalTransaction.linkedTransactionId,
      externalEntityId:
          externalEntityId ?? originalTransaction.externalEntityId,
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

    // Update Linked Transaction
    if (updateLinked && originalTransaction.linkedTransactionId != null) {
      final linkedTx = await repository.getTransactionById(
          user.uid, originalTransaction.linkedTransactionId!);
      if (linkedTx != null) {
        final newLinkedRealAmountSigned = -realAmountSigned;

        final newLinkedSplits = linkedTx.splits.map((s) {
           if (s.virtualAccountId == SystemAccounts.transferTransit) {
              return TransactionSplit(virtualAccountId: s.virtualAccountId, amount: -newLinkedRealAmountSigned);
           } else {
              return TransactionSplit(virtualAccountId: s.virtualAccountId, amount: newLinkedRealAmountSigned);
           }
        }).toList();

        String rawLabel = label;
        if (rawLabel.startsWith("[Transfert Out] ")) rawLabel = rawLabel.substring(16);
        if (rawLabel.startsWith("[Transfert In] ")) rawLabel = rawLabel.substring(15);
        final linkedLabel = "[Transfert ${newLinkedRealAmountSigned > 0 ? 'In' : 'Out'}] $rawLabel";

        final updatedLinkedTx = TransactionModel(
          id: linkedTx.id,
          ownerId: linkedTx.ownerId,
          realAccountId: linkedTx.realAccountId,
          amount: newLinkedRealAmountSigned,
          type: linkedTx.type, // type shouldn't change for linked, but it's fine
          transactionDate: date,
          label: linkedLabel,
          category: category,
          note: note,
          status: linkedTx.status,
          step: linkedTx.step,
          recurringTransactionId: linkedTx.recurringTransactionId,
          linkedTransactionId: linkedTx.linkedTransactionId,
          splits: newLinkedSplits,
          externalEntityId: linkedTx.externalEntityId,
        );

        await repository.updateTransaction(user.uid, linkedTx, updatedLinkedTx);
      }
    }
  }

  Future<void> unlinkTransactions({
    required TransactionModel transaction,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    if (transaction.linkedTransactionId == null) return;

    final repository = ref.read(transactionRepositoryProvider);

    final linkedTx = await repository.getTransactionById(
          user.uid, transaction.linkedTransactionId!);

    final newSplitsOriginal = transaction.splits.map((s) {
      if (s.virtualAccountId == SystemAccounts.transferTransit) {
        return TransactionSplit(virtualAccountId: SystemAccounts.external, amount: s.amount);
      }
      return s;
    }).toList();

    String cleanLabel(String lbl) {
      String r = lbl;
      if (r.startsWith("[Transfert Out] ")) r = r.substring(16);
      if (r.startsWith("[Transfert In] ")) r = r.substring(15);
      return r;
    }

    final tx1 = TransactionModel(
      id: transaction.id,
      ownerId: transaction.ownerId,
      realAccountId: transaction.realAccountId,
      amount: transaction.amount,
      type: transaction.type,
      transactionDate: transaction.transactionDate,
      label: cleanLabel(transaction.label ?? ""),
      note: transaction.note,
      category: transaction.category,
      status: transaction.status,
      step: transaction.step,
      recurringTransactionId: transaction.recurringTransactionId,
      linkedTransactionId: null, // Unlinked
      splits: newSplitsOriginal,
    );

    TransactionModel? tx2;
    if (linkedTx != null) {
      final newSplitsLinked = linkedTx.splits.map((s) {
        if (s.virtualAccountId == SystemAccounts.transferTransit) {
          return TransactionSplit(virtualAccountId: SystemAccounts.external, amount: s.amount);
        }
        return s;
      }).toList();

      tx2 = TransactionModel(
        id: linkedTx.id,
        ownerId: linkedTx.ownerId,
        realAccountId: linkedTx.realAccountId,
        amount: linkedTx.amount,
        type: linkedTx.type,
        transactionDate: linkedTx.transactionDate,
        label: cleanLabel(linkedTx.label ?? ""),
        note: linkedTx.note,
        category: linkedTx.category,
        status: linkedTx.status,
        step: linkedTx.step,
        recurringTransactionId: linkedTx.recurringTransactionId,
        linkedTransactionId: null, // Unlinked
        splits: newSplitsLinked,
      );
    }

    await repository.updateTransaction(user.uid, transaction, tx1);
    if (tx2 != null && linkedTx != null) {
      await repository.updateTransaction(user.uid, linkedTx, tx2);
    }
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
    String? externalEntityId,
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
          ? -totalAmount.abs()
          : totalAmount.abs(),
      type: type,
      transactionDate: date,
      label: label,
      category: category,
      note: note,
      status: originalTransaction.status,
      step: targetStep,
      recurringTransactionId: originalTransaction.recurringTransactionId,
      externalEntityId:
          externalEntityId ?? originalTransaction.externalEntityId,
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
    final accountRepo = ref.read(accountRepositoryProvider);

    final committedAccount = await accountRepo.getVirtualAccountByType(
      user.uid,
      originalTransaction.realAccountId,
      VirtualAccountType.systemCommitted,
    );
    if (committedAccount == null) {
      throw Exception("System committed account not found.");
    }
    final committedAccountId = committedAccount.id;

    // Swap the counterparty split to external
    final newSplits = originalTransaction.splits.map((s) {
      if (s.virtualAccountId == committedAccountId || s.isSystem) {
        return TransactionSplit(
          virtualAccountId: SystemAccounts.external,
          amount: s.amount,
        );
      }
      return s;
    }).toList();

    final updatedTransaction = TransactionModel(
      id: originalTransaction.id,
      ownerId: originalTransaction.ownerId,
      realAccountId: originalTransaction.realAccountId,
      amount: originalTransaction.amount,
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

  /// Provisions a planned transaction, changing its step to pending and moving its
  /// counterparty split from 'system:external' to 'Solde Engagé'.
  Future<void> provisionTransaction(
    TransactionModel originalTransaction,
  ) async {
    if (originalTransaction.step != TransactionStep.planned &&
        originalTransaction.step != TransactionStep.scheduled) {
      return;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);

    final committedAccount = await accountRepo.getVirtualAccountByType(
      user.uid,
      originalTransaction.realAccountId,
      VirtualAccountType.systemCommitted,
    );
    if (committedAccount == null) {
      throw Exception("System committed account not found.");
    }
    final committedAccountId = committedAccount.id;

    // Swap the counterparty split to solde_engage
    final newSplits = originalTransaction.splits.map((s) {
      if (s.isSystem && s.virtualAccountId == SystemAccounts.external) {
        return TransactionSplit(
          virtualAccountId: committedAccountId,
          amount: s.amount,
        );
      }
      return s;
    }).toList();

    final updatedTransaction = TransactionModel(
      id: originalTransaction.id,
      ownerId: originalTransaction.ownerId,
      realAccountId: originalTransaction.realAccountId,
      amount: originalTransaction.amount,
      type: originalTransaction.type,
      transactionDate: originalTransaction.transactionDate,
      label: originalTransaction.label,
      note: originalTransaction.note,
      payee: originalTransaction.payee,
      category: originalTransaction.category,
      status: originalTransaction.status,
      step: TransactionStep.pending, // Now pending!
      externalEntityId: originalTransaction.externalEntityId,
      valueDate: originalTransaction.valueDate,
      visibilityDate: originalTransaction.visibilityDate,
      syncDate: originalTransaction.syncDate,
      provisionDate: DateTime.now(), // set provision date
      splits: newSplits,
      importHash: originalTransaction.importHash,
      recurringTransactionId: originalTransaction.recurringTransactionId,
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
