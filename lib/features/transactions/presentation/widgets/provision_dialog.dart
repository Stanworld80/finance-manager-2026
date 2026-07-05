import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/data/account_providers.dart';
import '../../../accounts/domain/account_models.dart';
import '../../application/transaction_service.dart';
import '../../../../../core/presentation/utils/decimal_text_input_formatter.dart';
import '../../../../../core/presentation/utils/dialog_utils.dart';
import '../../../../../core/presentation/widgets/custom_date_picker.dart';
import '../models/transaction_ui_models.dart';
import '../../domain/transaction_model.dart';
import 'searchable_account_selector.dart';


/// Dialog Provision : virement simplifié depuis une enveloppe vers "Libre" (ou "Solde Engagé")
/// du compte par défaut.
class ProvisionDialog extends ConsumerStatefulWidget {
  const ProvisionDialog({super.key});

  @override
  ConsumerState<ProvisionDialog> createState() => _ProvisionDialogState();
}

class _ProvisionDialogState extends ConsumerState<ProvisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();

  SelectableAccount? _envelope; // "De" = enveloppe choisie
  TransactionStep _step = TransactionStep.completed;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  /// Met à jour le libellé automatiquement quand l'enveloppe change
  void _onEnvelopeChanged(SelectableAccount? val) {
    setState(() {
      _envelope = val;
      if (val != null) {
        _labelController.text = 'Provision ${val.name}';
      } else {
        _labelController.text = '';
      }
    });
  }

  /// Résout la destination en fonction du statut et du compte de l'enveloppe
  SelectableAccount? _resolveDestination(
    List<SelectableAccount> items,
  ) {
    if (_envelope == null) return null;

    final targetType = _step == TransactionStep.completed
        ? VirtualAccountType.systemFree
        : VirtualAccountType.systemCommitted;

    try {
      // Priorité absolue au compte principal
      return items.firstWhere(
        (i) => i.isPrincipal && i.virtualAccount?.type == targetType,
      );
    } catch (_) {
      // Si pas de compte principal (cas rare), on cherche le premier compte system qui correspond
      try {
        return items.firstWhere(
          (i) => i.virtualAccount?.type == targetType,
        );
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _submit(List<SelectableAccount> items) async {
    if (!_formKey.currentState!.validate()) return;
    if (_envelope == null) return;

    if (!await showDateConfirmationDialog(
      context: context,
      selectedDate: _date,
    )) {
      return;
    }

    final destination = _resolveDestination(items);
    if (destination == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de trouver le compte destination (Libre / Solde Engagé)',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(transactionServiceProvider);
      final amount = double.parse(_amountController.text);
      final label = _labelController.text.trim();

      await service.addTransfer(
        amount: amount,
        label: label.isNotEmpty ? label : 'Provision ${_envelope!.name}',
        note: null,
        date: _date,
        sourceVirtualAccount: _envelope!.virtualAccount!,
        targetVirtualAccount: destination.virtualAccount!,
        step: _step,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provision enregistrée ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final realAccountsAsync = ref.watch(realAccountsProvider);
    final allVirtualsAsync = ref.watch(allVirtualAccountsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: realAccountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur : $e'),
            data: (realAccounts) => allVirtualsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur : $e'),
              data: (allVirtuals) {
                // Construire la liste des comptes sélectionnables
                final items = _buildItems(realAccounts, allVirtuals);

                // Enveloppes utilisateur (hors externes et comptes système)
                final envelopes = items
                    .where(
                      (i) =>
                          !i.isExternal &&
                          i.virtualAccount?.type == VirtualAccountType.userBudget,
                    )
                    .toList();

                final destination = _resolveDestination(items);

                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        Row(
                          children: [
                            const Icon(Icons.savings_outlined, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              'Provision',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Enveloppe (Origine)
                        SearchableAccountSelector(
                          label: 'Enveloppe (Origine)',
                          selectedAccount: _envelope,
                          items: envelopes,
                          onChanged: _onEnvelopeChanged,
                          validator: (val) =>
                              val == null ? 'Choisir une enveloppe' : null,
                        ),
                        const SizedBox(height: 16),

                        // Destination (lecture seule, automatique)
                        if (destination != null)
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Destination (automatique)',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                            ),
                            child: Text(
                              destination.displayName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        if (destination == null && _envelope != null)
                          const Text(
                            '⚠ Compte destination introuvable',
                            style: TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 16),

                        // Montant
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Montant',
                            prefixText: '€ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            DecimalTextInputFormatter(decimalRange: 2),
                          ],
                          autofocus: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requis';
                            if (double.tryParse(val) == null) return 'Invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Libellé (pré-rempli, éditable)
                        TextFormField(
                          controller: _labelController,
                          decoration: const InputDecoration(
                            labelText: 'Libellé',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              (val == null || val.isEmpty) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),

                        // Statut : Réalisé / En attente
                        SegmentedButton<TransactionStep>(
                          segments: const [
                            ButtonSegment(
                              value: TransactionStep.completed,
                              label: Text('Réalisé'),
                              icon: Icon(Icons.check_circle_outline),
                            ),
                            ButtonSegment(
                              value: TransactionStep.pending,
                              label: Text('En attente'),
                              icon: Icon(Icons.hourglass_empty),
                            ),
                          ],
                          selected: {_step},
                          onSelectionChanged: (sel) {
                            setState(() => _step = sel.first);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Date'),
                          subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
                          onTap: () async {
                            final picked = await showCustomDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _date = picked;
                                DateWarningSessionState.registerDateSelection(picked);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bouton valider
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _submit(items),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.savings_outlined),
                            label: const Text('Enregistrer la Provision'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),

                        // Info contextuelle
                        const SizedBox(height: 8),
                        Text(
                          _step == TransactionStep.completed
                              ? '→ Destination : zone Libre du compte'
                              : '→ Destination : Solde Engagé du compte',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.teal,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<SelectableAccount> _buildItems(
    List<RealAccount> realAccounts,
    List<VirtualAccount> allVirtuals,
  ) {
    final List<SelectableAccount> items = [];

    final physicalAccounts = realAccounts
        .where(
          (r) =>
              r.type != RealAccountType.external &&
              r.type != RealAccountType.externalGeneric,
        )
        .toList();

    for (var r in physicalAccounts) {
      final virtualsForAccount =
          allVirtuals.where((v) => v.realAccountId == r.id).toList();
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
    return items;
  }
}
