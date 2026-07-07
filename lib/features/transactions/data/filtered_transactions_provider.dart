import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

// State to hold filter options
class TransactionFilterState {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? realAccountId;
  final String? searchQuery;

  TransactionFilterState({
    this.startDate,
    this.endDate,
    this.realAccountId,
    this.searchQuery,
  });

  TransactionFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? realAccountId,
    String? searchQuery,
  }) {
    return TransactionFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      realAccountId: realAccountId ?? this.realAccountId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier()
    : super(
        TransactionFilterState(
          // Default filters? Maybe current month?
          startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        ),
      );

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setAccount(String? accountId) {
    state = state.copyWith(realAccountId: accountId);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = TransactionFilterState(); // Reset
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>((
      ref,
    ) {
      return TransactionFilterNotifier();
    });

// FutureProvider to fetch based on filters
final filteredTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return [];

  final filters = ref.watch(transactionFilterProvider);
  final repo = ref.read(transactionRepositoryProvider);

  // Fetch from DB with filters
  List<TransactionModel> transactions = await repo.getFilteredTransactions(
    userId: user.uid,
    startDate: filters.startDate,
    endDate: filters.endDate,
    realAccountId: filters.realAccountId,
    limit: 50, // Limit for better performance
  );

  // Client-side search filtering (for Label, Note, Payee)
  if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
    final query = filters.searchQuery!.toLowerCase();
    transactions = transactions.where((tx) {
      final labelMatch = tx.label?.toLowerCase().contains(query) ?? false;
      final noteMatch = tx.note?.toLowerCase().contains(query) ?? false;
      final payeeMatch = tx.payee?.toLowerCase().contains(query) ?? false;
      return labelMatch || noteMatch || payeeMatch;
    }).toList();
  }

  return transactions;
});
