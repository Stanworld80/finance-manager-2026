import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'resume_providers.dart';
import '../application/resume_export_service.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});

  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> {
  late DateTimeRange _selectedDateRange;

  // Sorting and Filtering states
  int? _sortColumnIndex;
  bool _sortAscending = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<EnvelopeStat> _getProcessedStats(List<EnvelopeStat> stats) {
    // 1. Filter
    var processed = stats;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      processed = processed.where((stat) {
        return stat.envelopeName.toLowerCase().contains(query) ||
            stat.realAccountName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Sort
    if (_sortColumnIndex != null) {
      processed.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0:
            result = a.envelopeName.compareTo(b.envelopeName);
            break;
          case 1:
            result = a.realAccountName.compareTo(b.realAccountName);
            break;
          case 2:
            result = a.startBalance.compareTo(b.startBalance);
            break;
          case 3:
            result = a.income.compareTo(b.income);
            break;
          case 4:
            result = a.expense.compareTo(b.expense);
            break;
          case 5:
            final diffA = a.income + a.expense;
            final diffB = b.income + b.expense;
            result = diffA.compareTo(diffB);
            break;
          case 6:
            result = a.endBalance.compareTo(b.endBalance);
            break;
          default:
            result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    return processed;
  }

  @override
  Widget build(BuildContext context) {
    // Provide the selected date range to the provider to fetch data
    final resumeDataAsync = ref.watch(resumeDataProvider(_selectedDateRange));

    final numberFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final exportService = ResumeExportService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé'),
        actions: [
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            label: Text(
              '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          resumeDataAsync.maybeWhen(
            data: (stats) {
              if (stats.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.download, color: Colors.white),
                onSelected: (value) async {
                  final processedStats = _getProcessedStats(stats);
                  if (value == 'csv') {
                    await exportService.exportToCsv(
                      context,
                      processedStats,
                      _selectedDateRange,
                    );
                  } else if (value == 'pdf') {
                    await exportService.exportToPdf(
                      context,
                      processedStats,
                      _selectedDateRange,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('Exporter en PDF'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'csv',
                    child: ListTile(
                      leading: Icon(Icons.table_chart),
                      title: Text('Exporter en CSV'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher une enveloppe ou un compte...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: resumeDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Erreur: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (stats) {
                final processedStats = _getProcessedStats(stats);

                if (stats.isEmpty) {
                  return const Center(
                    child: Text('Aucune donnée disponible pour cette période.'),
                  );
                }

                if (processedStats.isEmpty) {
                  return const Center(
                    child: Text('Aucun résultat pour cette recherche.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                      ),
                      columns: [
                        DataColumn(
                          label: const Text(
                            'Nom de l\'enveloppe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Compte lié',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Solde début',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Revenus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Dépenses',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Différence',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text(
                            'Solde fin',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                          onSort: _onSort,
                        ),
                      ],
                      rows: processedStats.map((stat) {
                        final diff =
                            stat.income + stat.expense; // Expense is negative
                        final diffColor = diff >= 0 ? Colors.green : Colors.red;

                        return DataRow(
                          cells: [
                            DataCell(Text(stat.envelopeName)),
                            DataCell(Text(stat.realAccountName)),
                            DataCell(
                              Text(numberFormat.format(stat.startBalance)),
                            ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),
        ],
      ),
    );
  }
}
