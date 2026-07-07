import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

part 'transaction_providers.g.dart';

enum TransactionSort {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

@riverpod
class TransactionSearchQuery extends _$TransactionSearchQuery {
  @override
  String build() => '';
  void set(String query) => state = query;
}

@riverpod
class TransactionDateFilter extends _$TransactionDateFilter {
  @override
  DateTimeRange? build() => null;
  void set(DateTimeRange? range) => state = range;
}

@riverpod
class TransactionSortOrder extends _$TransactionSortOrder {
  @override
  TransactionSort build() => TransactionSort.dateDesc;
  void set(TransactionSort sort) => state = sort;
}

@riverpod
Stream<List<TransactionModel>> filteredAccountTransactions(
  Ref ref,
  String realAccountId,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  final query = ref.watch(transactionSearchQueryProvider).toLowerCase();
  final dateRange = ref.watch(transactionDateFilterProvider);
  final sort = ref.watch(transactionSortOrderProvider);

  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactionsByRealAccount(user.uid, realAccountId)
      .map((txs) {
    var filtered = List<TransactionModel>.from(txs);

    // Filter by Search
    if (query.isNotEmpty) {
      filtered = filtered.where((tx) {
        final label = tx.label?.toLowerCase() ?? '';
        final note = tx.note?.toLowerCase() ?? '';
        final payee = tx.payee?.toLowerCase() ?? '';
        final category = tx.category?.toLowerCase() ?? '';
        return label.contains(query) ||
            note.contains(query) ||
            payee.contains(query) ||
            category.contains(query);
      }).toList();
    }

    // Filter by Date
    if (dateRange != null) {
      final start = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
      );
      final end = DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((tx) {
        return tx.transactionDate.isAtSameMomentAs(start) ||
            tx.transactionDate.isAtSameMomentAs(end) ||
            (tx.transactionDate.isAfter(start) &&
                tx.transactionDate.isBefore(end));
      }).toList();
    }

    // Sort
    switch (sort) {
      case TransactionSort.dateDesc:
        filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      case TransactionSort.dateAsc:
        filtered.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      case TransactionSort.amountDesc:
        filtered.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
      case TransactionSort.amountAsc:
        filtered.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
    }

    return filtered;
  });
}

@riverpod
Stream<List<TransactionModel>> recentTransactions(Ref ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(transactionRepositoryProvider).watchTransactions(user.uid, limit: 10);
}

@riverpod
Stream<TransactionModel?> transactionById(Ref ref, String id) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransaction(user.uid, id);
}

@riverpod
Stream<List<TransactionModel>> upcomingTransactions(
  Ref ref,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  // Watch all and filter client side. In a real app we'd want a DB query
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(user.uid)
      .map(
        (txs) =>
            txs
                .where(
                  (tx) =>
                      tx.step == TransactionStep.planned ||
                      tx.step == TransactionStep.scheduled,
                )
                .toList()
              ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate)),
      );
}

@riverpod
Stream<List<TransactionModel>> externalTransactions(
  Ref ref,
  String externalEntityId,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(user.uid)
      .map(
        (txs) =>
            txs.where((tx) => tx.externalEntityId == externalEntityId).toList()
              ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate)),
      );
}
