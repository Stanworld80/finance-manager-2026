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
    DateTimeRange period,
  ) async {
    try {
      final List<List<dynamic>> rows = [];

      // Account Totals Section
      if (accountStats.isNotEmpty) {
        rows.add(['TOTAUX PAR COMPTE REEL']);
        rows.add([
          'Nom du compte',
          'Compte lié',
          'Solde début',
          'Revenus',
          'Dépenses',
          'Différence',
          'Solde fin',
        ]);
        for (final AccountStat stat in accountStats) {
          final diff = stat.income + stat.expense;
          rows.add([
            stat.accountName,
            '---',
            stat.startBalance,
            stat.income,
            stat.expense,
            diff,
            stat.endBalance,
          ]);
        }
        rows.add([]); // Spacer
      }

      // System Envelopes Section
      if (systemEnvelopeStats.isNotEmpty) {
        rows.add(['ENVELOPPES SYSTEME']);
        rows.add([
          'Nom de l\'enveloppe',
          'Compte lié',
          'Solde début',
          'Revenus',
          'Dépenses',
          'Différence',
          'Solde fin',
        ]);

        for (final EnvelopeStat stat in systemEnvelopeStats) {
          final diff = stat.income + stat.expense;
          rows.add([
            stat.envelopeName,
            stat.realAccountName,
            stat.startBalance,
            stat.income,
            stat.expense,
            diff,
            stat.endBalance,
          ]);
        }
        rows.add([]); // Spacer
      }

      // Envelope Details Section
      rows.add(['DETAILS PAR ENVELOPPE']);
      rows.add([
        'Nom de l\'enveloppe',
        'Compte lié',
        'Solde début',
        'Revenus',
        'Dépenses',
        'Différence',
        'Solde fin',
      ]);

      for (final EnvelopeStat stat in envelopeStats) {
        final diff = stat.income + stat.expense;
        rows.add([
          stat.envelopeName,
          stat.realAccountName,
          stat.startBalance,
          stat.income,
          stat.expense,
          diff,
          stat.endBalance,
        ]);
      }

      final String csvData = const ListToCsvConverter().convert(rows);

      final String dir = (await getTemporaryDirectory()).path;
      final String filePath =
          '$dir/resume_finance_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final File file = File(filePath);
      await file.writeAsString(csvData);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Résumé Finance (${_formatPeriod(period)})',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
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
  }) async {
    try {
      final pdf = pw.Document();

      final accountHeaders = [
        'Nom du compte',
        'Compte lié',
        'Solde début',
        'Revenus',
        'Dépenses',
        'Différence',
        'Solde fin',
      ];

      final envelopeHeaders = [
        'Nom de l\'enveloppe',
        'Compte lié',
        'Solde début',
        'Revenus',
        'Dépenses',
        'Différence',
        'Solde fin',
      ];

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
                accountHeaders,
                accountStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  return [
                    stat.accountName,
                    '---',
                    stat.startBalance,
                    stat.income,
                    stat.expense,
                    diff,
                    stat.endBalance,
                  ];
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
                envelopeHeaders,
                systemEnvelopeStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  return [
                    stat.envelopeName,
                    stat.realAccountName,
                    stat.startBalance,
                    stat.income,
                    stat.expense,
                    diff,
                    stat.endBalance,
                  ];
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
                envelopeHeaders,
                envelopeStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  return [
                    stat.envelopeName,
                    stat.realAccountName,
                    stat.startBalance,
                    stat.income,
                    stat.expense,
                    diff,
                    stat.endBalance,
                  ];
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
                envelopeHeaders,
                externalEnvelopeStats.map((stat) {
                  final diff = stat.income + stat.expense;
                  return [
                    stat.envelopeName,
                    stat.realAccountName,
                    stat.startBalance,
                    stat.income,
                    stat.expense,
                    diff,
                    stat.endBalance,
                  ];
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
    List<String> headers,
    List<List<dynamic>> data, {
    PdfColor headerColor = PdfColors.blueGrey800,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
      },
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

              final isNumeric = index >= 2;
              final doubleValue = isNumeric && value is double ? _normalizeValue(value) : 0.0;
              final text = isNumeric && value is double
                  ? _numberFormat.format(doubleValue)
                  : value.toString();

              return pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: 12.25,
                    color: isNumeric ? _getPdfValueColor(doubleValue) : PdfColors.black,
                    fontWeight: index >= 5 ? pw.FontWeight.bold : pw.FontWeight.normal,
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
