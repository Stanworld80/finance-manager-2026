import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'resume_providers.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});

  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> {
  late DateTimeRange _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  Future<void> _selectDateRange() async {
    final newRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide the selected date range to the provider to fetch data
    final resumeDataAsync = ref.watch(resumeDataProvider(_selectedDateRange));

    final numberFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé (Statistiques des Enveloppes)'),
        actions: [
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            label: Text(
              '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: resumeDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erreur: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return const Center(
              child: Text('Aucune donnée disponible pour cette période.'),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.resolveWith(
                  (states) => Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Nom de l\'enveloppe',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Compte lié',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Solde début',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Revenus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Dépenses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Différence',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Solde fin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                ],
                rows: stats.map((stat) {
                  final diff =
                      stat.income + stat.expense; // Expense is negative
                  final diffColor = diff >= 0 ? Colors.green : Colors.red;

                  return DataRow(
                    cells: [
                      DataCell(Text(stat.envelopeName)),
                      DataCell(Text(stat.realAccountName)),
                      DataCell(Text(numberFormat.format(stat.startBalance))),
                      DataCell(
                        Text(
                          numberFormat.format(stat.income),
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      DataCell(
                        Text(
                          numberFormat.format(stat.expense),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      DataCell(
                        Text(
                          numberFormat.format(diff),
                          style: TextStyle(
                            color: diffColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          numberFormat.format(stat.endBalance),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
