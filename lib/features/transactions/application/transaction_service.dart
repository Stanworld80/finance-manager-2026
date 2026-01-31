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

    // Determine signs
    double realAmountSigned;
    double virtualAmountSigned;

    switch (type) {
      case TransactionType.debit:
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        break;
      case TransactionType.credit:
        realAmountSigned = amount.abs();
        virtualAmountSigned = amount.abs();
        break;
      case TransactionType.provision:
      case TransactionType.transfer:
        // Internal operations don't usually change the Real Account Balance directly
        // in the simple sense of "Bank Transaction".
        // A provision is internal.
        // A transfer could be real (wire) or internal.
        // For this method, we assume it's handling the "Add Transaction" UI which is for Bank Lines.
        // So we default to debit for now if mapped here.
        realAmountSigned = -amount.abs();
        virtualAmountSigned = -amount.abs();
        break;
    }

    final transaction = TransactionModel(
      id: uuid.v4(),
      ownerId: user.uid,
      realAccountId: realAccount.id,
      amount: realAmountSigned,
      type: type,
      transactionDate: date, // Renamed from date
      label: label,
      category: category,
      note: note,
      status: TransactionStatus.none, // Default for manual entry
      step: TransactionStep.completed, // Default for manual entry
      splits: [
        TransactionSplit(
          virtualAccountId: targetVirtualAccount.id,
          amount: virtualAmountSigned,
        ),
      ],
    );

    await repository.createTransaction(user.uid, transaction);
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(transactionRepositoryProvider);
    await repository.deleteTransaction(user.uid, transaction);
  }
}
