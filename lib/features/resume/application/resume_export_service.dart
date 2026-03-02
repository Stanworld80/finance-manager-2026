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
    DateTimeRange period,
  ) async {
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

      final accountData = accountStats.map((AccountStat stat) {
        final diff = stat.income + stat.expense;
        return [
          stat.accountName,
          '---',
          _numberFormat.format(stat.startBalance),
          _numberFormat.format(stat.income),
          _numberFormat.format(stat.expense),
          _numberFormat.format(diff),
          _numberFormat.format(stat.endBalance),
        ];
      }).toList();

      final systemEnvelopeData = systemEnvelopeStats.map((EnvelopeStat stat) {
        final diff = stat.income + stat.expense;
        return [
          stat.envelopeName,
          stat.realAccountName,
          _numberFormat.format(stat.startBalance),
          _numberFormat.format(stat.income),
          _numberFormat.format(stat.expense),
          _numberFormat.format(diff),
          _numberFormat.format(stat.endBalance),
        ];
      }).toList();

      final envelopeData = envelopeStats.map((EnvelopeStat stat) {
        final diff = stat.income + stat.expense;
        return [
          stat.envelopeName,
          stat.realAccountName,
          _numberFormat.format(stat.startBalance),
          _numberFormat.format(stat.income),
          _numberFormat.format(stat.expense),
          _numberFormat.format(diff),
          _numberFormat.format(stat.endBalance),
        ];
      }).toList();

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
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatPeriod(period),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            if (accountStats.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Totaux par Compte Réel',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
              _buildPdfTable(accountHeaders, accountData),
              pw.SizedBox(height: 20),
            ],
            if (systemEnvelopeStats.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Enveloppes Système',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color:
                        PdfColors.orange800, // Matching UI color Amber/Orange
                  ),
                ),
              ),
              _buildPdfTable(
                envelopeHeaders,
                systemEnvelopeData,
                headerColor: PdfColors.orange800,
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Text(
                'Détails par Enveloppe',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ),
            _buildPdfTable(envelopeHeaders, envelopeData),
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

  pw.Widget _buildPdfTable(
    List<String> headers,
    List<List<String>> data, {
    PdfColor headerColor = PdfColors.blueGrey800,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
      cellStyle: const pw.TextStyle(color: PdfColors.black, fontSize: 8),
      headerHeight: 20,
      cellHeight: 18,
    );
  }
}
