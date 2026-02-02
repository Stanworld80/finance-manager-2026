import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/transaction_service.dart';
import '../domain/transaction_model.dart';
import '../../accounts/application/account_service.dart';

class SelectableAccount {
  final String id;
  final String name;
  final String? realAccountName;
  final VirtualAccount? virtualAccount;
  final bool isExternal;

  SelectableAccount({
    required this.id,
    required this.name,
    this.realAccountName,
    this.virtualAccount,
    this.isExternal = false,
  });

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

class AddTransactionPage extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddTransactionPage({super.key, this.transactionToEdit});

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

  SelectableAccount? _origin;
  SelectableAccount? _destination;

  bool _isSplitMode = false;
  final List<SplitRow> _splitRows = [];

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

      // Logic to pre-fill origin/destination happens in build because we need the list of accounts
      // Logic to pre-fill split rows:
      if (tx.splits.length > 2 ||
          (tx.splits.length == 2 &&
              tx.splits.any(
                (s) =>
                    !SystemAccounts.isSystem(s.virtualAccountId) &&
                    s.virtualAccountId != tx.splits.first.virtualAccountId,
              ))) {
        // This logic is complex because 'split mode' in UI means > 1 internal envelope for SAME side.
        // Or simple split.
        // Let's assume if it has > 2 splits, it's a split.
        // Or if it is a Transfer, we handle differently.
        if (tx.type != TransactionType.transfer) {
          _isSplitMode = true;
          // We will populate _splitRows in build or here if we have names? No we need SelectableAccount.
          // We'll mark as not initialized and do it in build.
        }
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
    items.add(
      SelectableAccount(
        id: SystemAccounts.external,
        name: "Monde Extérieur",
        isExternal: true,
      ),
    );
    for (var v in allVirtuals) {
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
        ),
      );
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
      appBar: AppBar(title: const Text("Nouvelle Transaction")),
      body: realAccountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        data: (realAccountList) => allVirtualsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Erreur: $err")),
          data: (allVirtuals) {
            final items = _buildItems(realAccountList, allVirtuals);
            final externalItem = items.firstWhere((i) => i.isExternal);

            if (!_isInitialized) {
              if (widget.transactionToEdit != null) {
                _initializeFromTransaction(
                  widget.transactionToEdit!,
                  items,
                  externalItem,
                );
              } else if (_origin == null &&
                  _destination == null &&
                  items.length > 1) {
                _origin = items.firstWhere((i) => !i.isExternal);
                _destination = externalItem;
                _type = TransactionType.debit;
              }
              _isInitialized = true;
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
                            if (_origin?.isExternal ?? false) {
                              _origin = items.firstWhere((i) => !i.isExternal);
                            }
                            _destination = externalItem;
                          } else if (_type == TransactionType.credit) {
                            _origin = externalItem;
                            if (_destination?.isExternal ?? false) {
                              _destination = items.firstWhere(
                                (i) => !i.isExternal,
                              );
                            }
                          } else {
                            if (_origin?.isExternal ?? true) {
                              _origin = items.firstWhere((i) => !i.isExternal);
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
                      decoration: const InputDecoration(
                        labelText: "Libellé",
                        hintText: "Ex: Courses, Salaire...",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "Requis" : null,
                      onSaved: (value) => _label = value!,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Commentaire",
                        hintText: "Ajouter une note...",
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => _note = value,
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SelectableAccount>(
                            key: const ValueKey('origin_dropdown'),
                            initialValue: _origin,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "De (Origine)",
                              border: OutlineInputBorder(),
                            ),
                            items: items.map((i) {
                              return DropdownMenuItem(
                                value: i,
                                child: Text(i.displayName),
                              );
                            }).toList(),
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
                          onPressed: () => _showQuickCreateEnvelope(
                            context,
                            ref,
                            realAccountList,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Destination Selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SelectableAccount>(
                            key: const ValueKey('destination_dropdown'),
                            initialValue: _destination,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "À (Destination)",
                              border: OutlineInputBorder(),
                            ),
                            items: items.map((i) {
                              return DropdownMenuItem(
                                value: i,
                                child: Text(i.displayName),
                              );
                            }).toList(),
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
                          onPressed: () => _showQuickCreateEnvelope(
                            context,
                            ref,
                            realAccountList,
                          ),
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
                                  child:
                                      DropdownButtonFormField<
                                        SelectableAccount
                                      >(
                                        initialValue: row.selectableAccount,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: "Enveloppe",
                                        ),
                                        items: internalItems
                                            .map(
                                              (i) => DropdownMenuItem(
                                                value: i,
                                                child: Text(
                                                  i.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
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

                    const SizedBox(height: 24),

                    ListTile(
                      title: const Text("Date"),
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
    SelectableAccount externalItem,
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
        _destination = externalItem;
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
        _origin = externalItem;
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

        if (widget.transactionToEdit != null) {
          // --- EDIT MODE ---
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

  Future<void> _showQuickCreateEnvelope(
    BuildContext context,
    WidgetRef ref,
    List<RealAccount> realAccounts,
  ) async {
    final nameController = TextEditingController();
    RealAccount? selectedAccount = realAccounts.isNotEmpty
        ? realAccounts.first
        : null;

    await showDialog(
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
                  value: selectedAccount,
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
                  await ref
                      .read(accountServiceProvider)
                      .createVirtualAccount(
                        realAccountId: selectedAccount!.id,
                        name: nameController.text,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
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
