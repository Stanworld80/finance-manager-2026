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

  // Sorting and Filtering states
  int? _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, bool> _expandedSections = {
    'account-totals': true,
    'system-envelopes': true,
    'envelope-details': true,
    'external-accounts': true,
  };

  final Map<String, bool> _includedInExport = {
    'account-totals': true,
    'system-envelopes': true,
    'envelope-details': true,
    'external-accounts': true,
  };

  final Map<String, bool> _visibleColumns = {
    'name': true,
    'linkedAccount': true,
    'startBalance': true,
    'income': true,
    'expense': true,
    'difference': true,
    'endBalance': true,
  };

  List<String> get _activeColumns => [
        if (_visibleColumns['name'] == true) 'name',
        if (_visibleColumns['linkedAccount'] == true) 'linkedAccount',
        if (_visibleColumns['startBalance'] == true) 'startBalance',
        if (_visibleColumns['income'] == true) 'income',
        if (_visibleColumns['expense'] == true) 'expense',
        if (_visibleColumns['difference'] == true) 'difference',
        if (_visibleColumns['endBalance'] == true) 'endBalance',
      ];

  Future<void> _selectColumnsDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sélectionner les colonnes'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildColumnCheckbox(setDialogState, 'name', 'Nom (Compte/Enveloppe)', required: true),
                    _buildColumnCheckbox(setDialogState, 'linkedAccount', 'Compte lié'),
                    _buildColumnCheckbox(setDialogState, 'startBalance', 'Solde début'),
                    _buildColumnCheckbox(setDialogState, 'income', 'Revenus'),
                    _buildColumnCheckbox(setDialogState, 'expense', 'Dépenses'),
                    _buildColumnCheckbox(setDialogState, 'difference', 'Différence'),
                    _buildColumnCheckbox(setDialogState, 'endBalance', 'Solde fin'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColumnCheckbox(
    StateSetter setDialogState,
    String key,
    String label, {
    bool required = false,
  }) {
    return CheckboxListTile(
      value: _visibleColumns[key] ?? true,
      title: Text(label),
      subtitle: required ? const Text('Requis', style: TextStyle(fontSize: 12)) : null,
      activeColor: Theme.of(context).primaryColor,
      onChanged: required
          ? null
          : (value) {
              setDialogState(() {
                _visibleColumns[key] = value ?? false;
              });
              setState(() {
                _visibleColumns[key] = value ?? false;
              });
            },
    );
  }

  Color? _getValueColor(double value) {
    if (value > 0.005) return Colors.green;
    if (value < -0.005) return Colors.red;
    return null; // Neutral color (Theme default, usually black/white)
  }

  double _normalizeValue(double value) {
    return value.abs() < 0.005 ? 0.0 : value;
  }

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

  List<AccountStat> _getProcessedAccountStats(List<AccountStat> stats) {
    // 1. Filter
    var processed = stats;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      processed = processed.where((stat) {
        return stat.accountName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Sort
    final activeCols = _activeColumns;
    if (_sortColumnIndex != null && _sortColumnIndex! < activeCols.length) {
      final sortField = activeCols[_sortColumnIndex!];
      processed.sort((a, b) {
        int result;
        switch (sortField) {
          case 'name':
            result = a.accountName.compareTo(b.accountName);
            break;
          case 'linkedAccount':
            result = 0; // Linked account column for envelopes
            break;
          case 'startBalance':
            result = a.startBalance.compareTo(b.startBalance);
            break;
          case 'income':
            result = a.income.compareTo(b.income);
            break;
          case 'expense':
            result = a.expense.compareTo(b.expense);
            break;
          case 'difference':
            final diffA = a.income + a.expense;
            final diffB = b.income + b.expense;
            result = diffA.compareTo(diffB);
            break;
          case 'endBalance':
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



  List<EnvelopeStat> _getProcessedEnvelopeStats(List<EnvelopeStat> stats) {
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
    final activeCols = _activeColumns;
    if (_sortColumnIndex != null && _sortColumnIndex! < activeCols.length) {
      final sortField = activeCols[_sortColumnIndex!];
      processed.sort((a, b) {
        int result;
        switch (sortField) {
          case 'name':
            result = a.envelopeName.compareTo(b.envelopeName);
            break;
          case 'linkedAccount':
            result = a.realAccountName.compareTo(b.realAccountName);
            break;
          case 'startBalance':
            result = a.startBalance.compareTo(b.startBalance);
            break;
          case 'income':
            result = a.income.compareTo(b.income);
            break;
          case 'expense':
            result = a.expense.compareTo(b.expense);
            break;
          case 'difference':
            final diffA = a.income + a.expense;
            final diffB = b.income + b.expense;
            result = diffA.compareTo(diffB);
            break;
          case 'endBalance':
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
    final exportService = ref.watch(resumeExportServiceProvider);

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
            data: (data) {
              if (data.envelopeStats.isEmpty &&
                  data.systemEnvelopeStats.isEmpty &&
                  data.externalEnvelopeStats.isEmpty &&
                  data.accountStats.isEmpty) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.view_column, color: Colors.white),
                    tooltip: 'Sélectionner les colonnes',
                    onPressed: _selectColumnsDialog,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onSelected: (value) async {
                      final processedAccountStats = _getProcessedAccountStats(
                        data.accountStats,
                      );
                      final processedSystemEnvelopeStats =
                          _getProcessedEnvelopeStats(data.systemEnvelopeStats);
                      final processedEnvelopeStats = _getProcessedEnvelopeStats(
                        data.envelopeStats,
                      );
                      final processedExternalStats = _getProcessedEnvelopeStats(
                        data.externalEnvelopeStats,
                      );

                      if (value == 'csv') {
                        await exportService.exportToCsv(
                          context,
                          processedAccountStats,
                          processedSystemEnvelopeStats,
                          processedEnvelopeStats,
                          _selectedDateRange,
                          visibleColumns: _visibleColumns,
                        );
                      } else if (value == 'pdf') {
                        await exportService.exportToPdf(
                          context,
                          processedAccountStats,
                          processedSystemEnvelopeStats,
                          processedEnvelopeStats,
                          processedExternalStats,
                          _selectedDateRange,
                          includedSections: _includedInExport,
                          visibleColumns: _visibleColumns,
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
              data: (data) {
                final processedEnvelopeStats = _getProcessedEnvelopeStats(
                  data.envelopeStats,
                );
                final processedSystemEnvelopeStats =
                    _getProcessedEnvelopeStats(data.systemEnvelopeStats);
                final processedAccountStats = _getProcessedAccountStats(
                  data.accountStats,
                );
                final processedExternalStats = _getProcessedEnvelopeStats(
                  data.externalEnvelopeStats,
                );

                if (data.envelopeStats.isEmpty &&
                    data.systemEnvelopeStats.isEmpty &&
                    data.externalEnvelopeStats.isEmpty &&
                    data.accountStats.isEmpty) {
                  return const Center(
                    child: Text('Aucune donnée disponible pour cette période.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      // Section: Account Totals
                      KeyedSubtree(
                        key: const Key('account-totals-section'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'Totaux par Compte Réel',
                              Icons.account_balance,
                              color: Colors.blue.shade400,
                              sectionKey: 'account-totals',
                            ),
                            if (_expandedSections['account-totals'] == true) ...[
                              if (processedAccountStats.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Aucun compte trouvé.'),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildAccountTable(
                                    context,
                                    processedAccountStats,
                                    numberFormat,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Section: System Envelopes
                      KeyedSubtree(
                        key: const Key('system-envelopes-section'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'Enveloppes Système',
                              Icons.settings,
                              color: Colors.amber,
                              sectionKey: 'system-envelopes',
                            ),
                            if (_expandedSections['system-envelopes'] == true) ...[
                              if (processedSystemEnvelopeStats.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Aucune enveloppe système trouvée.',
                                  ),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildEnvelopeTable(
                                    context,
                                    processedSystemEnvelopeStats,
                                    numberFormat,
                                    headerColor: Colors.amber.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Section: Envelope Details
                      KeyedSubtree(
                        key: const Key('envelope-details-section'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'Détails par Enveloppe',
                              Icons.account_tree,
                              color: Colors.orange.shade400,
                              sectionKey: 'envelope-details',
                            ),
                            if (_expandedSections['envelope-details'] == true) ...[
                              if (processedEnvelopeStats.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Aucune enveloppe trouvée.'),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildEnvelopeTable(
                                    context,
                                    processedEnvelopeStats,
                                    numberFormat,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Section: External Accounts
                      KeyedSubtree(
                        key: const Key('external-accounts-section'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'Comptes Extérieurs',
                              Icons.public,
                              color: Colors.teal.shade300,
                              sectionKey: 'external-accounts',
                            ),
                            if (_expandedSections['external-accounts'] == true) ...[
                              if (processedExternalStats.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Aucun compte extérieur trouvé.'),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildEnvelopeTable(
                                    context,
                                    processedExternalStats,
                                    numberFormat,
                                    headerColor: Colors.teal.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Color? color,
    required String sectionKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // If no color provided, use a high-contrast theme color
    Color effectiveColor = color ?? (isDark 
        ? Theme.of(context).colorScheme.primaryContainer 
        : Theme.of(context).primaryColor);
        
    // In dark mode, ensure the provided color isn't too dark
    if (isDark && color != null) {
      // We could use HSL to lighten it, but for simplicity we rely on the caller
      // or common sense. shade400/shade300 are usually good.
    }

    final isExpanded = _expandedSections[sectionKey] ?? true;
    final isIncluded = _includedInExport[sectionKey] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedSections[sectionKey] = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isExpanded ? effectiveColor : effectiveColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isExpanded ? effectiveColor : effectiveColor.withValues(alpha: 0.7),
                      ),
                ),
              ),
              // PDF Export Toggle
              Tooltip(
                message: 'Inclure dans l\'export PDF',
                child: Checkbox(
                  value: isIncluded,
                  activeColor: effectiveColor,
                  checkColor: Colors.white,
                  onChanged: (value) {
                    setState(() {
                      _includedInExport[sectionKey] = value ?? false;
                    });
                  },
                ),
              ),
              // Expansion Toggle Icon
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: isExpanded ? effectiveColor : effectiveColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTable(
    BuildContext context,
    List<AccountStat> stats,
    NumberFormat numberFormat,
  ) {
    final int? activeSortColumnIndex = (_sortColumnIndex != null && _sortColumnIndex! < _activeColumns.length)
        ? _sortColumnIndex
        : null;

    return DataTable(
      sortColumnIndex: activeSortColumnIndex,
      sortAscending: _sortAscending,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
      columns: _buildColumns(isAccount: true),
      rows: stats.map((stat) {
        final diff = stat.income + stat.expense;
        final List<DataCell> cells = [];

        if (_visibleColumns['name'] == true) {
          cells.add(DataCell(
            Text(
              stat.accountName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ));
        }
        if (_visibleColumns['linkedAccount'] == true) {
          cells.add(const DataCell(Text('---')));
        }
        if (_visibleColumns['startBalance'] == true) {
          cells.add(DataCell(Text(numberFormat.format(_normalizeValue(stat.startBalance)))));
        }
        if (_visibleColumns['income'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(stat.income)),
              style: TextStyle(color: _getValueColor(stat.income)),
            ),
          ));
        }
        if (_visibleColumns['expense'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(stat.expense)),
              style: TextStyle(color: _getValueColor(stat.expense)),
            ),
          ));
        }
        if (_visibleColumns['difference'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(diff)),
              style: TextStyle(
                color: _getValueColor(diff),
                fontWeight: FontWeight.bold,
              ),
            ),
          ));
        }
        if (_visibleColumns['endBalance'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(stat.endBalance)),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getValueColor(stat.endBalance),
              ),
            ),
          ));
        }

        return DataRow(cells: cells);
      }).toList(),
    );
  }

  Widget _buildEnvelopeTable(
    BuildContext context,
    List<EnvelopeStat> stats,
    NumberFormat numberFormat, {
    Color? headerColor,
  }) {
    final int? activeSortColumnIndex = (_sortColumnIndex != null && _sortColumnIndex! < _activeColumns.length)
        ? _sortColumnIndex
        : null;

    return DataTable(
      sortColumnIndex: activeSortColumnIndex,
      sortAscending: _sortAscending,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) =>
            headerColor ??
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
      columns: _buildColumns(isAccount: false),
      rows: stats.map((stat) {
        final diff = stat.income + stat.expense;
        final List<DataCell> cells = [];

        if (_visibleColumns['name'] == true) {
          cells.add(DataCell(Text(stat.envelopeName)));
        }
        if (_visibleColumns['linkedAccount'] == true) {
          cells.add(DataCell(Text(stat.realAccountName)));
        }
        if (_visibleColumns['startBalance'] == true) {
          cells.add(DataCell(Text(numberFormat.format(_normalizeValue(stat.startBalance)))));
        }
        if (_visibleColumns['income'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(stat.income)),
              style: TextStyle(color: _getValueColor(stat.income)),
            ),
          ));
        }
        if (_visibleColumns['expense'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(stat.expense)),
              style: TextStyle(color: _getValueColor(stat.expense)),
            ),
          ));
        }
        if (_visibleColumns['difference'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(diff)),
              style: TextStyle(
                color: _getValueColor(diff),
                fontWeight: FontWeight.bold,
              ),
            ),
          ));
        }
        if (_visibleColumns['endBalance'] == true) {
          cells.add(DataCell(
            Text(
              numberFormat.format(_normalizeValue(stat.endBalance)),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getValueColor(stat.endBalance),
              ),
            ),
          ));
        }

        return DataRow(cells: cells);
      }).toList(),
    );
  }

  List<DataColumn> _buildColumns({required bool isAccount}) {
    final List<DataColumn> cols = [];

    if (_visibleColumns['name'] == true) {
      cols.add(DataColumn(
        label: Text(
          isAccount ? 'Nom du compte' : 'Nom de l\'enveloppe',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onSort: _onSort,
      ));
    }
    if (_visibleColumns['linkedAccount'] == true) {
      cols.add(DataColumn(
        label: const Text(
          'Compte lié',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onSort: _onSort,
      ));
    }
    if (_visibleColumns['startBalance'] == true) {
      cols.add(DataColumn(
        label: const Text(
          'Solde début',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        numeric: true,
        onSort: _onSort,
      ));
    }
    if (_visibleColumns['income'] == true) {
      cols.add(DataColumn(
        label: const Text(
          'Revenus',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        numeric: true,
        onSort: _onSort,
      ));
    }
    if (_visibleColumns['expense'] == true) {
      cols.add(DataColumn(
        label: const Text(
          'Dépenses',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        numeric: true,
        onSort: _onSort,
      ));
    }
    if (_visibleColumns['difference'] == true) {
      cols.add(DataColumn(
        label: const Text(
          'Différence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        numeric: true,
        onSort: _onSort,
      ));
    }
    if (_visibleColumns['endBalance'] == true) {
      cols.add(DataColumn(
        label: const Text(
          'Solde fin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        numeric: true,
        onSort: _onSort,
      ));
    }

    return cols;
  }
}
