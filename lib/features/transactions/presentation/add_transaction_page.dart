import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/transaction_service.dart';
import '../domain/transaction_model.dart';
import '../application/recurring_transaction_service.dart';
import '../domain/recurring_transaction_model.dart';
import '../../accounts/application/account_service.dart';
import '../../../../core/presentation/utils/decimal_text_input_formatter.dart';
import 'widgets/searchable_account_selector.dart';

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

class AddTransactionPage extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;
  final String? initialType;
  final String? initialRealAccountId;

  const AddTransactionPage({
    super.key,
    this.transactionToEdit,
    this.initialType,
    this.initialRealAccountId,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.debit;
  double? _amount;
  String _label = "";
  String? _note;
  DateTime _date = DateTime.now();
  TransactionStep _step = TransactionStep.completed;

  SelectableAccount? _origin;
  SelectableAccount? _destination;

  bool _isSplitMode = false;
  final List<SplitRow> _splitRows = [];

  AccountSortType _sortType = AccountSortType.byAccount;

  // Recurrence
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  int _interval = 1;
  DateTime? _endDate;

  // Used for pre-filling origin/destination in build when list is available
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _amount = tx.amount.abs();
      _label = tx.label ?? "";
      _note = tx.note;
      _date = tx.transactionDate;
      _type = tx.type;
      _step = tx.step;

      if (tx.splits.length > 2 ||
          (tx.splits.length == 2 &&
              tx.splits.any(
                (s) =>
                    !SystemAccounts.isSystem(s.virtualAccountId) &&
                    s.virtualAccountId != tx.splits.first.virtualAccountId,
              ))) {
        if (tx.type != TransactionType.transfer) {
          _isSplitMode = true;
        }
      }
    } else {
      // Handle query parameters if creating a new transaction
      if (widget.initialType != null) {
        if (widget.initialType == 'credit') _type = TransactionType.credit;
        if (widget.initialType == 'debit') _type = TransactionType.debit;
        if (widget.initialType == 'transfer') _type = TransactionType.transfer;
      }
    }
  }

  @override
  void dispose() {
    for (var row in _splitRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addSplitRow() {
    setState(() {
      _splitRows.add(SplitRow());
    });
  }

  void _removeSplitRow(int index) {
    setState(() {
      final row = _splitRows.removeAt(index);
      row.dispose();
    });
  }

  double get _currentSplitTotal {
    return _splitRows.fold(0.0, (sum, row) {
      final val = double.tryParse(row.amountController.text) ?? 0.0;
      return sum + val;
    });
  }

  List<SelectableAccount> _buildItems(
    List<RealAccount> realAccounts,
    List<VirtualAccount> allVirtuals,
  ) {
    final List<SelectableAccount> items = [];

    // Always add Generic External first
    items.add(
      SelectableAccount(
        id: SystemAccounts.external,
        name: "Monde Extérieur (Indéfini)",
        isExternal: true,
        isExternalGeneric: true,
      ),
    );

    // Add specific External Entities
    final externalEntities = realAccounts
        .where(
          (r) =>
              r.type == RealAccountType.external ||
              r.type == RealAccountType.externalGeneric,
        )
        .toList();

    for (var entity in externalEntities) {
      if (entity.type == RealAccountType.externalGeneric)
        continue; // Already added
      items.add(
        SelectableAccount(
          id: "ext:${entity.id}",
          name: entity.name,
          isExternal: true,
          externalEntityId: entity.id,
        ),
      );
    }

    final physicalAccounts = realAccounts
        .where(
          (r) =>
              r.type != RealAccountType.external &&
              r.type != RealAccountType.externalGeneric,
        )
        .toList();

    if (_sortType == AccountSortType.alphabetical) {
      // Sort all virtuals alphabetically by name
      final sortedVirtuals = List<VirtualAccount>.from(allVirtuals)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      for (var v in sortedVirtuals) {
        final r = realAccounts.cast<RealAccount?>().firstWhere(
          (acc) => acc?.id == v.realAccountId,
          orElse: () => null,
        );
        items.add(
          SelectableAccount(
            id: v.id,
            name: v.name,
            realAccountName: r?.name,
            virtualAccount: v,
            isPrincipal: r?.isPrincipal ?? false,
            virtualAccountType: v.type,
          ),
        );
      }
    } else {
      // Default: Group by Real Account
      for (var r in physicalAccounts) {
        final virtualsForAccount =
            allVirtuals.where((v) => v.realAccountId == r.id).toList()
              ..sort((a, b) {
                // Put 'Libre' first, then others alphabetical
                if (a.type == VirtualAccountType.systemFree) return -1;
                if (b.type == VirtualAccountType.systemFree) return 1;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });

        for (var v in virtualsForAccount) {
          items.add(
            SelectableAccount(
              id: v.id,
              name: v.name,
              realAccountName: r.name,
              virtualAccount: v,
              isPrincipal: r.isPrincipal,
              virtualAccountType: v.type,
            ),
          );
        }
      }
    }
    return items;
  }

  void _syncType() {
    if (_origin == null || _destination == null) return;
    if (_origin!.isExternal) {
      _type = TransactionType.credit;
    } else if (_destination!.isExternal) {
      _type = TransactionType.debit;
    } else {
      _type = TransactionType.transfer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final realAccountsAsync = ref.watch(realAccountsProvider);
    final allVirtualsAsync = ref.watch(allVirtualAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit != null
              ? "Modifier la Transaction"
              : "Nouvelle Transaction",
        ),
        actions: [
          PopupMenuButton<AccountSortType>(
            icon: const Icon(Icons.sort),
            tooltip: "Trier les comptes",
            onSelected: (val) {
              setState(() => _sortType = val);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AccountSortType.byAccount,
                child: Text("Par Compte Bancaire"),
              ),
              const PopupMenuItem(
                value: AccountSortType.alphabetical,
                child: Text("Ordre Alphabétique"),
              ),
            ],
          ),
        ],
      ),
      body: realAccountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        data: (realAccountList) => allVirtualsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Erreur: $err")),
          data: (allVirtuals) {
            final items = _buildItems(realAccountList, allVirtuals);
            final externalGenericItem = items.firstWhere(
              (i) => i.isExternalGeneric,
            );

            if (!_isInitialized) {
              if (widget.transactionToEdit != null) {
                _initializeFromTransaction(
                  widget.transactionToEdit!,
                  items,
                  externalGenericItem,
                );
              } else if (_origin == null &&
                  _destination == null &&
                  items.isNotEmpty) {
                SelectableAccount? defaultRealAccount;
                if (widget.initialRealAccountId != null) {
                  try {
                    defaultRealAccount = items.firstWhere(
                      (i) =>
                          i.virtualAccount?.realAccountId ==
                              widget.initialRealAccountId &&
                          i.type == VirtualAccountType.systemFree,
                    );
                  } catch (_) {
                    try {
                      defaultRealAccount = items.firstWhere(
                        (i) =>
                            i.virtualAccount?.realAccountId ==
                            widget.initialRealAccountId,
                      );
                    } catch (_) {}
                  }
                }

                // If no specific account context, try to find the PRINCIPAL account
                if (defaultRealAccount == null) {
                  try {
                    final principalAccount = realAccountList.firstWhere(
                      (a) => a.isPrincipal,
                    );
                    defaultRealAccount = items.firstWhere(
                      (i) =>
                          i.virtualAccount?.realAccountId ==
                              principalAccount.id &&
                          i.type == VirtualAccountType.systemFree,
                    );
                  } catch (_) {
                    // Fallback to existing logic if no principal or its Libre not found
                  }
                }

                if (defaultRealAccount == null && items.length > 1) {
                  defaultRealAccount = items.firstWhere(
                    (i) => !i.isExternal,
                    orElse: () => externalGenericItem,
                  );
                }

                if (_type == TransactionType.debit) {
                  _origin = defaultRealAccount ?? externalGenericItem;
                  _destination = externalGenericItem;
                } else if (_type == TransactionType.credit) {
                  _origin = externalGenericItem;
                  _destination = defaultRealAccount ?? externalGenericItem;
                } else if (_type == TransactionType.transfer) {
                  _origin = defaultRealAccount ?? externalGenericItem;
                  _destination = items.firstWhere(
                    (i) => !i.isExternal && i.id != _origin?.id,
                    orElse: () => externalGenericItem,
                  );
                }
              }
              _isInitialized = true;
            } else {
              // Re-validate selection in case sort changed reference (should use ID match)
              if (_origin != null && !_origin!.isExternal) {
                _origin = items.firstWhere(
                  (i) => i.id == _origin!.id,
                  orElse: () => _origin!,
                );
              }
              if (_destination != null && !_destination!.isExternal) {
                _destination = items.firstWhere(
                  (i) => i.id == _destination!.id,
                  orElse: () => _destination!,
                );
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.debit,
                          label: Text("Dépense"),
                          icon: Icon(Icons.outbound),
                        ),
                        ButtonSegment(
                          value: TransactionType.credit,
                          label: Text("Revenu"),
                          icon: Icon(Icons.move_to_inbox),
                        ),
                        ButtonSegment(
                          value: TransactionType.transfer,
                          label: Text("Transfert"),
                          icon: Icon(Icons.swap_horiz),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _type = newSelection.first;
                          _isSplitMode = false;
                          if (_type == TransactionType.debit) {
                            // When switching to Expense:
                            // 1. Destination becomes External Generic
                            // 2. Origin should be the Principal account's Libre if the current origin is external
                            if (_origin?.isExternal ?? false) {
                              _origin = items.firstWhere(
                                (i) =>
                                    i.isPrincipal &&
                                    i.type == VirtualAccountType.systemFree,
                                orElse: () => items.firstWhere(
                                  (i) => !i.isExternal,
                                  orElse: () => items.last,
                                ),
                              );
                            }
                            _destination = externalGenericItem;
                          } else if (_type == TransactionType.credit) {
                            // When switching to Income:
                            // 1. Origin becomes External Generic
                            // 2. Destination should be the Principal account's Libre if the current destination is external
                            _origin = externalGenericItem;
                            if (_destination?.isExternal ?? false) {
                              _destination = items.firstWhere(
                                (i) =>
                                    i.isPrincipal &&
                                    i.type == VirtualAccountType.systemFree,
                                orElse: () => items.firstWhere(
                                  (i) => !i.isExternal,
                                  orElse: () => items.last,
                                ),
                              );
                            }
                          } else {
                            if (_origin?.isExternal ?? true) {
                              _origin = items.firstWhere(
                                (i) => !i.isExternal,
                                orElse: () => items.last,
                              );
                            }
                            if (_destination?.isExternal ?? true) {
                              _destination = items
                                  .where((i) => !i.isExternal)
                                  .last;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: _amount?.toString(),
                      decoration: const InputDecoration(
                        labelText: "Montant Total",
                        prefixText: "€ ",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Requis";
                        if (double.tryParse(value) == null) return "Invalide";
                        return null;
                      },
                      onChanged: (val) =>
                          setState(() => _amount = double.tryParse(val)),
                      onSaved: (value) => _amount = double.parse(value!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: _label,
                      decoration: const InputDecoration(
                        labelText: "Libellé",
                        hintText: "Ex: Courses, Salaire...",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "Requis" : null,
                      onChanged: (val) => setState(() => _label = val),
                      onSaved: (value) => _label = value!,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: _note,
                      decoration: const InputDecoration(
                        labelText: "Commentaire",
                        hintText: "Ajouter une note...",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _note = val),
                      onSaved: (value) => _note = value,
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: SearchableAccountSelector(
                            label: "De (Origine)",
                            selectedAccount: _origin,
                            items: items,
                            onChanged: (val) {
                              setState(() {
                                _origin = val;
                                _syncType();
                              });
                            },
                            validator: (val) => val == null ? "Requis" : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: "Créer une nouvelle enveloppe",
                          onPressed: () async {
                            final newAccount = await _showQuickCreateEnvelope(
                              context,
                              ref,
                              realAccountList,
                            );
                            if (newAccount != null) {
                              setState(() {
                                // Find the wrapped item corresponding to the new account
                                final newItem = items.firstWhere(
                                  (i) => i.id == newAccount.id,
                                  orElse: () => items.first,
                                );
                                _origin = newItem;
                                _syncType();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Destination Selection
                    Row(
                      children: [
                        Expanded(
                          child: SearchableAccountSelector(
                            label: "À (Destination)",
                            selectedAccount: _destination,
                            items: items,
                            onChanged: (val) {
                              setState(() {
                                _destination = val;
                                _syncType();
                              });
                            },
                            validator: (val) => val == null ? "Requis" : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: "Créer une nouvelle enveloppe",
                          onPressed: () async {
                            final newAccount = await _showQuickCreateEnvelope(
                              context,
                              ref,
                              realAccountList,
                            );
                            if (newAccount != null) {
                              setState(() {
                                // Find the wrapped item corresponding to the new account
                                final newItem = items.firstWhere(
                                  (i) => i.id == newAccount.id,
                                  orElse: () => items.first,
                                );
                                _destination = newItem;
                                _syncType();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // VENTILATION SECTION
                    if (_type != TransactionType.transfer) ...[
                      SwitchListTile(
                        title: const Text("Ventilation (Split)"),
                        subtitle: const Text(
                          "Répartir sur plusieurs enveloppes",
                        ),
                        value: _isSplitMode,
                        onChanged: (val) {
                          setState(() {
                            _isSplitMode = val;
                            if (_isSplitMode && _splitRows.isEmpty) {
                              _addSplitRow();
                            }
                          });
                        },
                      ),
                      if (_isSplitMode) ...[
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _splitRows.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final row = _splitRows[index];
                            final internalItems = items
                                .where((i) => !i.isExternal)
                                .toList();
                            return Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SearchableAccountSelector(
                                    label: "Enveloppe",
                                    selectedAccount: row.selectableAccount,
                                    items: internalItems,
                                    onChanged: (val) => setState(
                                      () => row.selectableAccount = val,
                                    ),
                                    validator: (val) =>
                                        val == null ? "!" : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: row.amountController,
                                    decoration: const InputDecoration(
                                      labelText: "€",
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      DecimalTextInputFormatter(
                                        decimalRange: 2,
                                      ),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) =>
                                        (val == null || val.isEmpty)
                                        ? "!"
                                        : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeSplitRow(index),
                                ),
                              ],
                            );
                          },
                        ),
                        TextButton.icon(
                          onPressed: _addSplitRow,
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter une ligne"),
                        ),
                        if (_amount != null) ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Ventilé: ${_currentSplitTotal.toStringAsFixed(2)} €",
                              ),
                              Text(
                                "Reste: ${(_amount! - _currentSplitTotal).toStringAsFixed(2)} €",
                                style: TextStyle(
                                  color:
                                      (_amount! - _currentSplitTotal).abs() <
                                          0.01
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],

                    if (_type != TransactionType.transfer) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TransactionStep>(
                        decoration: const InputDecoration(
                          labelText: 'Statut de la transaction',
                          border: OutlineInputBorder(),
                        ),
                        value: _step,
                        items: const [
                          DropdownMenuItem(
                            value: TransactionStep.completed,
                            child: Text('Réalisée (Débitée/Créditée)'),
                          ),
                          DropdownMenuItem(
                            value: TransactionStep.pending,
                            child: Text('En attente (Mouvement en cours)'),
                          ),
                          DropdownMenuItem(
                            value: TransactionStep.planned,
                            child: Text('Planifiée (Prévisionnel)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _step = val);
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    ListTile(
                      title: const Text(
                        "Date (Prochaine occurrence / Date unique)",
                      ),
                      subtitle: Text("${_date.toLocal()}".split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),

                    if (widget.transactionToEdit == null) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Transaction Récurrente"),
                        subtitle: const Text(
                          "Répéter automatiquement à intervalles réguliers",
                        ),
                        value: _isRecurring,
                        onChanged: (val) {
                          setState(() {
                            _isRecurring = val;
                          });
                        },
                      ),
                      if (_isRecurring) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: _interval.toString(),
                                decoration: const InputDecoration(
                                  labelText: "Répéter tous les",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    _interval = int.tryParse(val) ?? 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child:
                                  DropdownButtonFormField<RecurrenceFrequency>(
                                    decoration: const InputDecoration(
                                      labelText: 'Fréquence',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _frequency,
                                    items: const [
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.daily,
                                        child: Text('Jour(s)'),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.weekly,
                                        child: Text('Semaine(s)'),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.monthly,
                                        child: Text('Mois'),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.yearly,
                                        child: Text('An(s)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _frequency = val);
                                      }
                                    },
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text("Date de fin (Optionnelle)"),
                          subtitle: Text(
                            _endDate != null
                                ? "${_endDate!.toLocal()}".split(' ')[0]
                                : "Aucune",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _endDate = null),
                                ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _endDate ??
                                  _date.add(const Duration(days: 365)),
                              firstDate: _date,
                              lastDate: DateTime(2050),
                            );
                            if (picked != null) {
                              setState(() => _endDate = picked);
                            }
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(
                          widget.transactionToEdit != null
                              ? "Enregistrer les modifications"
                              : "Valider",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _initializeFromTransaction(
    TransactionModel tx,
    List<SelectableAccount> items,
    SelectableAccount externalGenericItem,
  ) {
    if (tx.type == TransactionType.transfer) {
      if (tx.splits.length >= 2) {
        // Identify source and target
        // Source is negative, Target is positive
        final sourceSplit = tx.splits.firstWhere(
          (s) => s.amount < 0,
          orElse: () => tx.splits.first,
        );
        final targetSplit = tx.splits.firstWhere(
          (s) => s.amount > 0,
          orElse: () => tx.splits.last,
        );

        _origin = items.firstWhere(
          (i) => i.id == sourceSplit.virtualAccountId,
          orElse: () => items.last,
        );
        _destination = items.firstWhere(
          (i) => i.id == targetSplit.virtualAccountId,
          orElse: () => items.last,
        );
      }
    } else {
      // Debit or Credit
      if (tx.type == TransactionType.debit) {
        _destination = externalGenericItem;
        final splitIter = tx.splits.where(
          (s) => !SystemAccounts.isSystem(s.virtualAccountId),
        );
        if (splitIter.isNotEmpty) {
          final firstSplit = splitIter.first;
          _origin = items.firstWhere(
            (i) => i.id == firstSplit.virtualAccountId,
            orElse: () => items.last,
          );

          if (_isSplitMode) {
            _splitRows.clear();
            for (final split in splitIter) {
              final item = items.firstWhere(
                (i) => i.id == split.virtualAccountId,
                orElse: () => _origin!,
              );
              _splitRows.add(
                SplitRow()
                  ..selectableAccount = item
                  ..amountController.text = split.amount.abs().toString(),
              );
            }
          }
        }
      } else {
        // Credit
        _origin = externalGenericItem;
        final splitIter = tx.splits.where(
          (s) => !SystemAccounts.isSystem(s.virtualAccountId),
        );
        if (splitIter.isNotEmpty) {
          final firstSplit = splitIter.first;
          _destination = items.firstWhere(
            (i) => i.id == firstSplit.virtualAccountId,
            orElse: () => items.last,
          );

          if (_isSplitMode) {
            _splitRows.clear();
            for (final split in splitIter) {
              final item = items.firstWhere(
                (i) => i.id == split.virtualAccountId,
                orElse: () => _destination!,
              );
              _splitRows.add(
                SplitRow()
                  ..selectableAccount = item
                  ..amountController.text = split.amount.abs().toString(),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final service = ref.read(transactionServiceProvider);

        if (_isRecurring && widget.transactionToEdit == null) {
          final recService = ref.read(recurringTransactionServiceProvider);

          final realAccountId = (_type == TransactionType.credit)
              ? _destination!.virtualAccount!.realAccountId
              : _origin!.virtualAccount!.realAccountId;

          // Simple logic for recurring
          await recService.addRecurringTransaction(
            frequency: _frequency,
            interval: _interval,
            startDate: _date,
            endDate: _endDate,
            realAccountId: realAccountId,
            amount: _amount!,
            label: _label,
            note: _note,
            type: _type,
            externalEntityId: (_type == TransactionType.debit)
                ? _destination?.externalEntityId
                : _origin?.externalEntityId,
            splits: _isSplitMode
                ? [
                    ..._splitRows
                        .where(
                          (r) =>
                              r.selectableAccount != null &&
                              r.amountController.text.isNotEmpty,
                        )
                        .map(
                          (r) => TransactionSplit(
                            virtualAccountId: r.selectableAccount!.id,
                            amount: (_type == TransactionType.debit)
                                ? -double.parse(r.amountController.text).abs()
                                : double.parse(r.amountController.text).abs(),
                          ),
                        ),
                    TransactionSplit(
                      virtualAccountId: (_type == TransactionType.debit)
                          ? _destination!.id
                          : _origin!.id,
                      amount: (_type == TransactionType.debit)
                          ? _splitRows
                                .where(
                                  (r) =>
                                      r.selectableAccount != null &&
                                      r.amountController.text.isNotEmpty,
                                )
                                .fold<double>(
                                  0.0,
                                  (sum, r) =>
                                      sum +
                                      double.parse(
                                        r.amountController.text,
                                      ).abs(),
                                )
                          : -_splitRows
                                .where(
                                  (r) =>
                                      r.selectableAccount != null &&
                                      r.amountController.text.isNotEmpty,
                                )
                                .fold<double>(
                                  0.0,
                                  (sum, r) =>
                                      sum +
                                      double.parse(
                                        r.amountController.text,
                                      ).abs(),
                                ),
                    ),
                  ]
                : [
                    TransactionSplit(
                      virtualAccountId: _origin!.id,
                      amount: -_amount!.abs(),
                    ),
                    TransactionSplit(
                      virtualAccountId: _destination!.id,
                      amount: _amount!.abs(),
                    ),
                  ],
          );

          if (context.mounted) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Transaction récurrente créée avec succès"),
              ),
            );
          }
          return;
        }

        if (widget.transactionToEdit != null) {
          // --- EDIT MODE ---
          final shouldUpdate = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Confirmer la modification"),
              content: const Text(
                "Voulez-vous vraiment enregistrer les modifications ?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Confirmer"),
                ),
              ],
            ),
          );

          if (shouldUpdate != true) return;

          if (_isSplitMode) {
            final splits = _splitRows
                .map(
                  (r) => (
                    account: r.selectableAccount!.virtualAccount!,
                    amount: double.parse(r.amountController.text).abs(),
                  ),
                )
                .toList();

            // Determine RealAccount from one of the splits or origin/dest
            final refAccount = _type == TransactionType.debit
                ? _origin
                : _destination;
            // If origin is external (credit), use destination. If destination is external (debit), use origin?
            // In Debit: Origin is internal.
            // In Credit: Destination is internal.

            String vAccountId;
            if (splits.isNotEmpty) {
              vAccountId = splits.first.account.id;
            } else {
              if (_type == TransactionType.debit &&
                  _origin != null &&
                  !_origin!.isExternal) {
                vAccountId = _origin!.id;
              } else if (_type == TransactionType.credit &&
                  _destination != null &&
                  !_destination!.isExternal) {
                vAccountId = _destination!.id;
              } else {
                // Fallback
                throw Exception("Impossible de déterminer le compte réel");
              }
            }

            // We need fetching logic
            if (refAccount != null && refAccount.virtualAccount != null) {
              vAccountId = refAccount.virtualAccount!.id;
            }

            // Actually, simply using the one selected in dropdown if it's not split mode,
            // or first row if split mode.
            // But in split mode, dropdown might be ignored or used as default.
            // Let's rely on `_getRealAccount` from the ID.
            final realAccount = await _getRealAccountByVirtualId(vAccountId);

            await service.updateSplitTransaction(
              originalTransaction: widget.transactionToEdit!,
              totalAmount: _amount!,
              type: _type,
              label: _label,
              note: _note,
              date: _date,
              realAccount: realAccount,
              splits: splits,
              step: _step,
              externalEntityId: (_type == TransactionType.debit)
                  ? _destination?.externalEntityId
                  : _origin?.externalEntityId,
            );
          } else {
            // Simple Update
            SelectableAccount target;
            if (_type == TransactionType.debit) {
              target = _origin!;
            } else {
              target = _destination!;
            }

            if (target.isExternal) {
              // Should not happen for the internal side
              throw Exception("Le compte cible ne peut pas être externe");
            }

            await service.updateTransaction(
              originalTransaction: widget.transactionToEdit!,
              amount: _amount!,
              type: _type,
              label: _label,
              note: _note,
              date: _date,
              realAccount: await _getRealAccount(
                target.virtualAccount!.realAccountId,
              ),
              targetVirtualAccount: target.virtualAccount!,
              step: _step,
              externalEntityId: (_type == TransactionType.debit)
                  ? _destination?.externalEntityId
                  : _origin?.externalEntityId,
            );
          }
        } else {
          // --- CREATE MODE ---
          if (_type == TransactionType.transfer) {
            await service.addTransfer(
              amount: _amount!,
              label: _label,
              note: _note,
              date: _date,
              sourceVirtualAccount: _origin!.virtualAccount!,
              targetVirtualAccount: _destination!.virtualAccount!,
            );
          } else if (_isSplitMode) {
            final splits = _splitRows
                .map(
                  (r) => (
                    account: r.selectableAccount!.virtualAccount!,
                    amount: double.parse(r.amountController.text).abs(),
                  ),
                )
                .toList();

            // Determine real account
            final refItem = _type == TransactionType.debit
                ? _origin
                : _destination;
            if (refItem == null || refItem.isExternal) {
              // In split mode, maybe they picked external in main dropdown?
              // But usually split implies internal breakdown.
              // We take the real account from the first split.
              final firstSplit = splits.first.account;
              final realAccount = await _getRealAccount(
                firstSplit.realAccountId,
              );

              await service.addSplitTransaction(
                totalAmount: _amount!,
                type: _type,
                label: _label,
                note: _note,
                date: _date,
                realAccount: realAccount,
                splits: splits,
                step: _step,
                externalEntityId: (_type == TransactionType.debit)
                    ? _destination?.externalEntityId
                    : _origin?.externalEntityId,
              );
            } else {
              await service.addSplitTransaction(
                totalAmount: _amount!,
                type: _type,
                label: _label,
                note: _note,
                date: _date,
                realAccount: await _getRealAccount(
                  refItem.virtualAccount!.realAccountId,
                ),
                splits: splits,
                step: _step,
                externalEntityId: (_type == TransactionType.debit)
                    ? _destination?.externalEntityId
                    : _origin?.externalEntityId,
              );
            }
          } else {
            // SIMPLE DEBIT/CREDIT
            final vAccount = _type == TransactionType.debit
                ? _origin!.virtualAccount!
                : _destination!.virtualAccount!;
            await service.addTransaction(
              amount: _amount!,
              type: _type,
              label: _label,
              note: _note,
              date: _date,
              realAccount: await _getRealAccount(vAccount.realAccountId),
              targetVirtualAccount: vAccount,
              step: _step,
              externalEntityId: (_type == TransactionType.debit)
                  ? _destination?.externalEntityId
                  : _origin?.externalEntityId,
            );
          }
        }

        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
        }
      }
    }
  }

  Future<RealAccount> _getRealAccount(String id) async {
    final accounts = await ref.read(realAccountsProvider.future);
    return accounts.firstWhere((a) => a.id == id);
  }

  Future<RealAccount> _getRealAccountByVirtualId(String virtualId) async {
    final allVirtuals = await ref.read(allVirtualAccountsProvider.future);
    final v = allVirtuals.firstWhere((v) => v.id == virtualId);
    return _getRealAccount(v.realAccountId);
  }

  Future<VirtualAccount?> _showQuickCreateEnvelope(
    BuildContext context,
    WidgetRef ref,
    List<RealAccount> realAccounts,
  ) async {
    final nameController = TextEditingController();
    RealAccount? selectedAccount = realAccounts.isNotEmpty
        ? realAccounts.first
        : null;

    return showDialog<VirtualAccount?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nouvelle Enveloppe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom"),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              if (realAccounts.length > 1)
                DropdownButtonFormField<RealAccount>(
                  initialValue: selectedAccount,
                  decoration: const InputDecoration(labelText: "Compte lié"),
                  items: realAccounts
                      .map(
                        (a) => DropdownMenuItem(value: a, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedAccount = val),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && selectedAccount != null) {
                  final newAccount = await ref
                      .read(accountServiceProvider)
                      .createVirtualAccount(
                        realAccountId: selectedAccount!.id,
                        name: nameController.text,
                      );
                  if (ctx.mounted) Navigator.pop(ctx, newAccount);
                }
              },
              child: const Text("Créer"),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitRow {
  SelectableAccount? selectableAccount;
  final amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}
