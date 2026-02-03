import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/recurring_transaction_service.dart';
import '../domain/recurring_transaction.dart';
import '../domain/transaction_model.dart';
import '../../../../core/presentation/utils/decimal_text_input_formatter.dart';

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
}

class AddRecurringTransactionPage extends ConsumerStatefulWidget {
  const AddRecurringTransactionPage({super.key});

  @override
  ConsumerState<AddRecurringTransactionPage> createState() =>
      _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState
    extends ConsumerState<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  double? _amount;
  String _label = "";
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int _interval = 1;
  DateTime _startDate = DateTime.now();
  SelectableAccount? _targetAccount;
  final TransactionType _type = TransactionType.debit;

  @override
  Widget build(BuildContext context) {
    final realAccountsAsync = ref.watch(realAccountsProvider);
    final allVirtualsAsync = ref.watch(allVirtualAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Nouvel Échéancier")),
      body: realAccountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        data: (realAccountList) => allVirtualsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Erreur: $err")),
          data: (allVirtuals) {
            final items = _buildItems(realAccountList, allVirtuals);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Montant",
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
                      onSaved: (value) => _amount = double.parse(value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Libellé",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "Requis" : null,
                      onSaved: (value) => _label = value!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<SelectableAccount>(
                      initialValue: _targetAccount,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Compte/Enveloppe Cible",
                        border: OutlineInputBorder(),
                      ),
                      items: items.map((i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text(i.displayName),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _targetAccount = val),
                      validator: (val) => val == null ? "Requis" : null,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      "Périodicité",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<RecurringFrequency>(
                            initialValue: _frequency,
                            decoration: const InputDecoration(
                              labelText: "Fréquence",
                              border: OutlineInputBorder(),
                            ),
                            items: RecurringFrequency.values.map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(f.name),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _frequency = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: _interval.toString(),
                            decoration: const InputDecoration(
                              labelText: "Intervalle",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "!";
                              if (int.tryParse(value) == null) return "!";
                              return null;
                            },
                            onSaved: (value) => _interval = int.parse(value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Date de début"),
                      subtitle: Text("${_startDate.toLocal()}".split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text("Créer l'échéancier"),
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

  List<SelectableAccount> _buildItems(
    List<RealAccount> realAccounts,
    List<VirtualAccount> allVirtuals,
  ) {
    return allVirtuals.map((v) {
      final r = realAccounts.firstWhere((acc) => acc.id == v.realAccountId);
      return SelectableAccount(
        id: v.id,
        name: v.name,
        realAccountName: r.name,
        virtualAccount: v,
      );
    }).toList();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final service = ref.read(recurringTransactionServiceProvider);
        await service.createRecurringTransaction(
          amount: _amount!,
          label: _label,
          frequency: _frequency,
          interval: _interval,
          startDate: _startDate,
          realAccountId: _targetAccount!.virtualAccount!.realAccountId,
          targetVirtualAccountId: _targetAccount!.id,
          type: _type,
        );
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
}
