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
  VirtualAccount? _selectedVirtualAccount;

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

          // Auto-select first if null
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
                  // Type Segmented Control
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
                    ],
                    selected: {_type},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setState(() {
                        _type = newSelection.first;
                        _selectedVirtualAccount =
                            null; // Reset sub-dropdown to avoid value mismatch
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
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

                  // Label
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

                  // Real Account Dropdown
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
                        _selectedVirtualAccount = null; // Reset sub-dropdown
                      });
                    },
                    validator: (val) => val == null ? "Requis" : null,
                  ),
                  const SizedBox(height: 16),

                  // Virtual Account Dropdown (Dependent)
                  if (_selectedRealAccount != null)
                    Consumer(
                      builder: (context, ref, child) {
                        final provider = virtualAccountsProvider(
                          _selectedRealAccount!.id,
                        );
                        final virtualsAsync = ref.watch(provider);
                        return virtualsAsync.when(
                          data: (virtuals) {
                            // Determine available accounts based on Type
                            // If Expense (Debit): Show User Budgets + Free (Source of funds)
                            // If Income (Credit): Show Flow (Destination) or Free?
                            // SPECS says Income -> "À Distribuer" (Flow).

                            List<VirtualAccount> options = [];
                            if (_type == TransactionType.credit) {
                              // Prefer 'Flow' type
                              options = virtuals
                                  .where(
                                    (v) =>
                                        v.type ==
                                        VirtualAccountType.flowToDistribute,
                                  )
                                  .toList();
                              if (options.isEmpty) {
                                options = virtuals; // Fallback
                              }
                            } else {
                              // Expense: Budgets + Free
                              options = virtuals
                                  .where(
                                    (v) =>
                                        v.type ==
                                            VirtualAccountType.userBudget ||
                                        v.type == VirtualAccountType.systemFree,
                                  )
                                  .toList();
                            }

                            // Ensure selected value is valid for the current list
                            // We use where checking for ID/Equality.
                            // Since we don't have == override, we rely on identity.
                            // If the list refreshed, we might lose selection if not careful.
                            // Ideally, we shouldn't rely on 'contains' if checks identity unless objects are cached.
                            // But for clearing invalid types:

                            VirtualAccount? currentValue =
                                _selectedVirtualAccount;
                            if (currentValue != null &&
                                !options.contains(currentValue)) {
                              currentValue = null;
                            }

                            return DropdownButtonFormField<VirtualAccount>(
                              key: ValueKey(
                                "$_type-${_selectedRealAccount?.id}",
                              ), // Force rebuild on type change
                              initialValue: currentValue,
                              decoration: InputDecoration(
                                labelText: _type == TransactionType.credit
                                    ? "Vers (Enveloppe)"
                                    : "Depuis (Enveloppe)",
                              ),
                              items: options.map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(v.name),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedVirtualAccount = val),
                              validator: (val) => val == null ? "Requis" : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => Text("Erreur: $e"),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Date Picker (Basic)
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

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Transaction ajoutée")));
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
