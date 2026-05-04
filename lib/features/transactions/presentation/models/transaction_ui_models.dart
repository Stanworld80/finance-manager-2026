import '../../accounts/domain/account_models.dart';
import '../domain/transaction_model.dart';
import 'package:flutter/material.dart';

class SelectableAccount {
  final String id;
  final String name;
  final String? realAccountName;
  final VirtualAccount? virtualAccount;
  final bool isExternal;
  final bool isExternalGeneric;
  final String? externalEntityId;

  final bool isPrincipal;
  final VirtualAccountType? virtualAccountType;

  SelectableAccount({
    required this.id,
    required this.name,
    this.realAccountName,
    this.virtualAccount,
    this.isExternal = false,
    this.isExternalGeneric = false,
    this.externalEntityId,
    this.isPrincipal = false,
    this.virtualAccountType,
  });

  VirtualAccountType? get type => virtualAccount?.type;

  String get displayName =>
      realAccountName != null ? "$name ($realAccountName)" : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectableAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum AccountSortType { byAccount, alphabetical }

class SplitRow {
  SelectableAccount? selectableAccount;
  final amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}
