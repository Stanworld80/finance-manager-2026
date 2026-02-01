import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../../accounts/domain/account_models.dart';
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
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    final uuid = const Uuid();

    // Determine signs for the poles
    double realAmountSigned;
    double virtualAmountSigned;
    double counterpartyAmountSigned;

    switch (type) {
      case TransactionType.debit:
        // Movement: Internal Envelope -> External World
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        counterpartyAmountSigned = amount.abs();
        break;
      case TransactionType.credit:
        // Movement: External World -> Internal Envelope
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
      step: TransactionStep.completed,
      splits: [
        // Internal Pole
        TransactionSplit(
          virtualAccountId: targetVirtualAccount.id,
          amount: virtualAmountSigned,
        ),
        // External Pole (Double-entry contra account)
        TransactionSplit(
          virtualAccountId: SystemAccounts.external,
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
    final uuid = const Uuid();

    // Prepare Splits
    List<TransactionSplit> transactionSplits = [];
    double counterpartyAmountSigned;

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

    // Add Counterparty (External)
    transactionSplits.add(
      TransactionSplit(
        virtualAccountId: SystemAccounts.external,
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
      step: TransactionStep.completed,
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

      await repository.createTransaction(user.uid, txSource);
      await repository.createTransaction(user.uid, txTarget);
    }
  }
}
