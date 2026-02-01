import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/transaction_service.dart';
import '../domain/transaction_model.dart';

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
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.debit;
  double? _amount;
  String _label = "";
  DateTime _date = DateTime.now();

  SelectableAccount? _origin;
  SelectableAccount? _destination;

  bool _isSplitMode = false;
  final List<SplitRow> _splitRows = [];

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

            if (_origin == null && _destination == null && items.length > 1) {
              _origin = items.firstWhere((i) => !i.isExternal);
              _destination = externalItem;
              _type = TransactionType.debit;
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

                    // Origin Selection
                    DropdownButtonFormField<SelectableAccount>(
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
                    const SizedBox(height: 16),

                    // Destination Selection
                    DropdownButtonFormField<SelectableAccount>(
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
                        child: const Text("Valider"),
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final service = ref.read(transactionServiceProvider);

        if (_type == TransactionType.transfer) {
          await service.addTransfer(
            amount: _amount!,
            label: _label,
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

          // External account is the other side
          final realAccount = _type == TransactionType.debit
              ? _origin!
                    .virtualAccount! // Actually we need a RealAccount object here?
              : _destination!.virtualAccount!;

          // Wait, TransactionService needs a RealAccount object.
          // I should fetch it from the virtual account.
          // Since I have the realAccountList in build, I should probably pass it or fetch it.

          await service.addSplitTransaction(
            totalAmount: _amount!,
            type: _type,
            label: _label,
            date: _date,
            realAccount: await _getRealAccount(realAccount.realAccountId),
            splits: splits,
          );
        } else {
          // SIMPLE DEBIT/CREDIT
          final vAccount = _type == TransactionType.debit
              ? _origin!.virtualAccount!
              : _destination!.virtualAccount!;
          await service.addTransaction(
            amount: _amount!,
            type: _type,
            label: _label,
            date: _date,
            realAccount: await _getRealAccount(vAccount.realAccountId),
            targetVirtualAccount: vAccount,
          );
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
}

class SplitRow {
  SelectableAccount? selectableAccount;
  final amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}
