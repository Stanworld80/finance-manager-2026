import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../presentation/resume_providers.dart';

class ResumeExportService {
  final NumberFormat _numberFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '',
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String _formatPeriod(DateTimeRange period) {
    return '${_dateFormat.format(period.start)} - ${_dateFormat.format(period.end)}';
  }

  /// Exports the given stats to a CSV file and shares it
  Future<void> exportToCsv(
    BuildContext context,
    List<AccountStat> accountStats,
    List<EnvelopeStat> systemEnvelopeStats,
    List<EnvelopeStat> envelopeStats,
    DateTimeRange period, {
    required Map<String, bool> visibleColumns,
  }) async {
    try {
      final List<List<dynamic>> rows = [];

      // Account Totals Section
      if (accountStats.isNotEmpty) {
        rows.add(['TOTAUX PAR COMPTE REEL']);
        final List<String> accountHeaders = [];
        if (visibleColumns['name'] == true) accountHeaders.add('Nom du compte');
        if (visibleColumns['linkedAccount'] == true) accountHeaders.add('Compte lié');
        if (visibleColumns['startBalance'] == true) accountHeaders.add('Solde début');
        if (visibleColumns['income'] == true) accountHeaders.add('Revenus');
        if (visibleColumns['expense'] == true) accountHeaders.add('Dépenses');
        if (visibleColumns['difference'] == true) accountHeaders.add('Différence');
        if (visibleColumns['endBalance'] == true) accountHeaders.add('Solde fin');
        rows.add(accountHeaders);

        for (final AccountStat stat in accountStats) {
          final diff = stat.income + stat.expense;
          final List<dynamic> row = [];
          if (visibleColumns['name'] == true) row.add(stat.accountName);
          if (visibleColumns['linkedAccount'] == true) row.add('---');
          if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
          if (visibleColumns['income'] == true) row.add(stat.income);
          if (visibleColumns['expense'] == true) row.add(stat.expense);
          if (visibleColumns['difference'] == true) row.add(diff);
          if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
          rows.add(row);
        }
        rows.add([]); // Spacer
      }

      // System Envelopes Section
      if (systemEnvelopeStats.isNotEmpty) {
        rows.add(['ENVELOPPES SYSTEME']);
        final List<String> systemHeaders = [];
        if (visibleColumns['name'] == true) systemHeaders.add('Nom de l\'enveloppe');
        if (visibleColumns['linkedAccount'] == true) systemHeaders.add('Compte lié');
        if (visibleColumns['startBalance'] == true) systemHeaders.add('Solde début');
        if (visibleColumns['income'] == true) systemHeaders.add('Revenus');
        if (visibleColumns['expense'] == true) systemHeaders.add('Dépenses');
        if (visibleColumns['difference'] == true) systemHeaders.add('Différence');
        if (visibleColumns['endBalance'] == true) systemHeaders.add('Solde fin');
        rows.add(systemHeaders);

        for (final EnvelopeStat stat in systemEnvelopeStats) {
          final diff = stat.income + stat.expense;
          final List<dynamic> row = [];
          if (visibleColumns['name'] == true) row.add(stat.envelopeName);
          if (visibleColumns['linkedAccount'] == true) row.add(stat.realAccountName);
          if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
          if (visibleColumns['income'] == true) row.add(stat.income);
          if (visibleColumns['expense'] == true) row.add(stat.expense);
          if (visibleColumns['difference'] == true) row.add(diff);
          if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
          rows.add(row);
        }
        rows.add([]); // Spacer
      }

      // Envelope Details Section
      rows.add(['DETAILS PAR ENVELOPPE']);
      final List<String> envelopeHeaders = [];
      if (visibleColumns['name'] == true) envelopeHeaders.add('Nom de l\'enveloppe');
      if (visibleColumns['linkedAccount'] == true) envelopeHeaders.add('Compte lié');
      if (visibleColumns['startBalance'] == true) envelopeHeaders.add('Solde début');
      if (visibleColumns['income'] == true) envelopeHeaders.add('Revenus');
      if (visibleColumns['expense'] == true) envelopeHeaders.add('Dépenses');
      if (visibleColumns['difference'] == true) envelopeHeaders.add('Différence');
      if (visibleColumns['endBalance'] == true) envelopeHeaders.add('Solde fin');
      rows.add(envelopeHeaders);

      for (final EnvelopeStat stat in envelopeStats) {
        final diff = stat.income + stat.expense;
        final List<dynamic> row = [];
        if (visibleColumns['name'] == true) row.add(stat.envelopeName);
        if (visibleColumns['linkedAccount'] == true) row.add(stat.realAccountName);
        if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
        if (visibleColumns['income'] == true) row.add(stat.income);
        if (visibleColumns['expense'] == true) row.add(stat.expense);
        if (visibleColumns['difference'] == true) row.add(diff);
        if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
        rows.add(row);
      }

      final String csvData = const ListToCsvConverter().convert(rows);

      final String dir = (await getTemporaryDirectory()).path;
      final String filePath =
          '$dir/resume_finance_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final File file = File(filePath);
      await file.writeAsString(csvData);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            subject: 'Résumé Finance (${_formatPeriod(period)})',
            files: [XFile(filePath)],
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'exportation CSV: $e')),
        );
      }
    }
  }

  /// Generates a PDF from the given stats and opens the print/share preview
  Future<void> exportToPdf(
    BuildContext context,
    List<AccountStat> accountStats,
    List<EnvelopeStat> systemEnvelopeStats,
    List<EnvelopeStat> envelopeStats,
    List<EnvelopeStat> externalEnvelopeStats,
    DateTimeRange period, {
    required Map<String, bool> includedSections,
    required Map<String, bool> visibleColumns,
  }) async {
    try {
      final pdf = pw.Document();

      final List<String> activeKeys = [];
      if (visibleColumns['name'] == true) activeKeys.add('name');
      if (visibleColumns['linkedAccount'] == true) activeKeys.add('linkedAccount');
      if (visibleColumns['startBalance'] == true) activeKeys.add('startBalance');
      if (visibleColumns['income'] == true) activeKeys.add('income');
      if (visibleColumns['expense'] == true) activeKeys.add('expense');
      if (visibleColumns['difference'] == true) activeKeys.add('difference');
      if (visibleColumns['endBalance'] == true) activeKeys.add('endBalance');

      final List<String> accountHeaders = [];
      if (visibleColumns['name'] == true) accountHeaders.add('Nom du compte');
      if (visibleColumns['linkedAccount'] == true) accountHeaders.add('Compte lié');
      if (visibleColumns['startBalance'] == true) accountHeaders.add('Solde début');
      if (visibleColumns['income'] == true) accountHeaders.add('Revenus');
      if (visibleColumns['expense'] == true) accountHeaders.add('Dépenses');
      if (visibleColumns['difference'] == true) accountHeaders.add('Différence');
      if (visibleColumns['endBalance'] == true) accountHeaders.add('Solde fin');

      final List<String> envelopeHeaders = [];
      if (visibleColumns['name'] == true) envelopeHeaders.add('Nom de l\'enveloppe');
      if (visibleColumns['linkedAccount'] == true) envelopeHeaders.add('Compte lié');
      if (visibleColumns['startBalance'] == true) envelopeHeaders.add('Solde début');
      if (visibleColumns['income'] == true) envelopeHeaders.add('Revenus');
      if (visibleColumns['expense'] == true) envelopeHeaders.add('Dépenses');
      if (visibleColumns['difference'] == true) envelopeHeaders.add('Différence');
      if (visibleColumns['endBalance'] == true) envelopeHeaders.add('Solde fin');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Résumé Finance',
                    style: pw.TextStyle(
                      fontSize: 31.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatPeriod(period),
                    style: const pw.TextStyle(fontSize: 17.5),
                  ),
                ],
              ),
            ),
            if (includedSections['account-totals'] == true &&
                accountStats.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Totaux par Compte Réel',
                  style: pw.TextStyle(
                    fontSize: 24.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
              _buildPdfTable(
                activeKeys,
                accountHeaders,
                accountStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  final List<dynamic> row = [];
                  if (visibleColumns['name'] == true) row.add(stat.accountName);
                  if (visibleColumns['linkedAccount'] == true) row.add('---');
                  if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
                  if (visibleColumns['income'] == true) row.add(stat.income);
                  if (visibleColumns['expense'] == true) row.add(stat.expense);
                  if (visibleColumns['difference'] == true) row.add(diff);
                  if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
                  return row;
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            if (includedSections['system-envelopes'] == true &&
                systemEnvelopeStats.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Enveloppes Système',
                  style: pw.TextStyle(
                    fontSize: 24.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ),
              ),
              _buildPdfTable(
                activeKeys,
                envelopeHeaders,
                systemEnvelopeStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  final List<dynamic> row = [];
                  if (visibleColumns['name'] == true) row.add(stat.envelopeName);
                  if (visibleColumns['linkedAccount'] == true) row.add(stat.realAccountName);
                  if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
                  if (visibleColumns['income'] == true) row.add(stat.income);
                  if (visibleColumns['expense'] == true) row.add(stat.expense);
                  if (visibleColumns['difference'] == true) row.add(diff);
                  if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
                  return row;
                }).toList(),
                headerColor: PdfColors.orange800,
              ),
              pw.SizedBox(height: 20),
            ],
            if (includedSections['envelope-details'] == true &&
                envelopeStats.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Détails par Enveloppe',
                  style: pw.TextStyle(
                    fontSize: 24.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
              _buildPdfTable(
                activeKeys,
                envelopeHeaders,
                envelopeStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  final List<dynamic> row = [];
                  if (visibleColumns['name'] == true) row.add(stat.envelopeName);
                  if (visibleColumns['linkedAccount'] == true) row.add(stat.realAccountName);
                  if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
                  if (visibleColumns['income'] == true) row.add(stat.income);
                  if (visibleColumns['expense'] == true) row.add(stat.expense);
                  if (visibleColumns['difference'] == true) row.add(diff);
                  if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
                  return row;
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            if (includedSections['external-accounts'] == true &&
                externalEnvelopeStats.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Comptes Externes',
                  style: pw.TextStyle(
                    fontSize: 24.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
              _buildPdfTable(
                activeKeys,
                envelopeHeaders,
                externalEnvelopeStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  final List<dynamic> row = [];
                  if (visibleColumns['name'] == true) row.add(stat.envelopeName);
                  if (visibleColumns['linkedAccount'] == true) row.add(stat.realAccountName);
                  if (visibleColumns['startBalance'] == true) row.add(stat.startBalance);
                  if (visibleColumns['income'] == true) row.add(stat.income);
                  if (visibleColumns['expense'] == true) row.add(stat.expense);
                  if (visibleColumns['difference'] == true) row.add(diff);
                  if (visibleColumns['endBalance'] == true) row.add(stat.endBalance);
                  return row;
                }).toList(),
              ),
            ],
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'resume_finance_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'exportation PDF: $e')),
        );
      }
    }
  }

  PdfColor _getPdfValueColor(double value) {
    if (value > 0.005) return PdfColors.green;
    if (value < -0.005) return PdfColors.red;
    return PdfColors.black;
  }

  double _normalizeValue(double value) {
    return value.abs() < 0.005 ? 0.0 : value;
  }

  pw.Widget _buildPdfTable(
    List<String> activeKeys,
    List<String> headers,
    List<List<dynamic>> data, {
    PdfColor headerColor = PdfColors.blueGrey800,
  }) {
    final Map<int, pw.TableColumnWidth> columnWidths = {};
    final Map<String, double> colWidthMap = {
      'name': 3.0,
      'linkedAccount': 2.0,
      'startBalance': 1.5,
      'income': 1.5,
      'expense': 1.5,
      'difference': 1.5,
      'endBalance': 1.5,
    };
    for (int i = 0; i < activeKeys.length; i++) {
      final key = activeKeys[i];
      final width = colWidthMap[key] ?? 1.5;
      columnWidths[i] = pw.FlexColumnWidth(width);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: columnWidths,
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 12.25,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data Rows
        ...data.map((row) {
          return pw.TableRow(
            children: row.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;

              final key = activeKeys[index];
              final isNumeric = key != 'name' && key != 'linkedAccount';
              final doubleValue = isNumeric && value is double ? _normalizeValue(value) : 0.0;
              final text = isNumeric && value is double
                  ? _numberFormat.format(doubleValue)
                  : value.toString();

              final isBold = key == 'difference' || key == 'endBalance';

              return pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: 12.25,
                    color: isNumeric ? _getPdfValueColor(doubleValue) : PdfColors.black,
                    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                  textAlign: isNumeric ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
