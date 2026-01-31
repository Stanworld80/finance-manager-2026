import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/transaction_service.dart';
import '../domain/transaction_model.dart';

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

  RealAccount? _selectedRealAccount;
  VirtualAccount?
  _selectedVirtualAccount; // Used for Debit/Credit (Source/Target)
  VirtualAccount? _transferSourceAccount; // Used for Transfer (From)
  VirtualAccount? _transferTargetAccount; // Used for Transfer (To)

  @override
  Widget build(BuildContext context) {
    final realAccountsAsync = ref.watch(realAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle Transaction")),
      body: realAccountsAsync.when(
        data: (realAccounts) {
          if (realAccounts.isEmpty) {
            return const Center(
              child: Text("Veuillez d'abord créer un compte."),
            );
          }

          if (_selectedRealAccount == null && realAccounts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedRealAccount = realAccounts.first;
              });
            });
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
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: TransactionType.credit,
                        label: Text("Revenu"),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: TransactionType.transfer,
                        label: Text("Transfert"),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setState(() {
                        _type = newSelection.first;
                        _selectedVirtualAccount = null;
                        _transferSourceAccount = null;
                        _transferTargetAccount = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Montant",
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
                    onSaved: (value) => _amount = double.parse(value!),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Libellé",
                      hintText: "Ex: Courses, Salaire, Epargne...",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? "Requis" : null,
                    onSaved: (value) => _label = value!,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<RealAccount>(
                    initialValue: _selectedRealAccount,
                    decoration: const InputDecoration(
                      labelText: "Compte Bancaire",
                    ),
                    items: realAccounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc,
                        child: Text(acc.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRealAccount = val;
                        _selectedVirtualAccount = null;
                        _transferSourceAccount = null;
                        _transferTargetAccount = null;
                      });
                    },
                    validator: (val) => val == null ? "Requis" : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedRealAccount != null)
                    Consumer(
                      builder: (context, ref, child) {
                        final provider = virtualAccountsProvider(
                          _selectedRealAccount!.id,
                        );
                        final virtualsAsync = ref.watch(provider);
                        return virtualsAsync.when(
                          data: (virtuals) {
                            if (_type == TransactionType.transfer) {
                              return Column(
                                children: [
                                  DropdownButtonFormField<VirtualAccount>(
                                    decoration: const InputDecoration(
                                      labelText: "Depuis (Source)",
                                    ),
                                    items: virtuals
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(v.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(
                                      () => _transferSourceAccount = val,
                                    ),
                                    validator: (val) =>
                                        _type == TransactionType.transfer &&
                                            val == null
                                        ? "Requis"
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<VirtualAccount>(
                                    decoration: const InputDecoration(
                                      labelText: "Vers (Destination)",
                                    ),
                                    items: virtuals
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(v.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(
                                      () => _transferTargetAccount = val,
                                    ),
                                    validator: (val) =>
                                        _type == TransactionType.transfer &&
                                            val == null
                                        ? "Requis"
                                        : null,
                                  ),
                                ],
                              );
                            }

                            // Standard Debit/Credit Logic
                            List<VirtualAccount> options = [];
                            if (_type == TransactionType.credit) {
                              options = virtuals
                                  .where(
                                    (v) =>
                                        v.type ==
                                        VirtualAccountType.flowToDistribute,
                                  )
                                  .toList();
                              if (options.isEmpty) options = virtuals;
                            } else {
                              options = virtuals
                                  .where(
                                    (v) =>
                                        v.type ==
                                            VirtualAccountType.userBudget ||
                                        v.type == VirtualAccountType.systemFree,
                                  )
                                  .toList();
                            }

                            return DropdownButtonFormField<VirtualAccount>(
                              key: ValueKey(
                                "$_type-${_selectedRealAccount!.id}",
                              ),
                              decoration: InputDecoration(
                                labelText: _type == TransactionType.credit
                                    ? "Vers (Enveloppe)"
                                    : "Depuis (Enveloppe)",
                              ),
                              items: options
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedVirtualAccount = val),
                              validator: (val) =>
                                  _type != TransactionType.transfer &&
                                      val == null
                                  ? "Requis"
                                  : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => Text("Erreur: $e"),
                        );
                      },
                    ),

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Erreur: $e")),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        if (_type == TransactionType.transfer) {
          await ref
              .read(transactionServiceProvider)
              .addTransfer(
                amount: _amount!,
                label: _label,
                date: _date,
                realAccount: _selectedRealAccount!,
                sourceVirtualAccount: _transferSourceAccount!,
                targetVirtualAccount: _transferTargetAccount!,
              );
        } else {
          await ref
              .read(transactionServiceProvider)
              .addTransaction(
                amount: _amount!,
                type: _type,
                label: _label,
                date: _date,
                realAccount: _selectedRealAccount!,
                targetVirtualAccount: _selectedVirtualAccount!,
              );
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Opération effectuée")));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
        }
      }
    }
  }
}
