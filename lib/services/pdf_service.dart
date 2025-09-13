// lib/services/pdf_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/devis.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  final _currencyFmt = NumberFormat.simpleCurrency(locale: 'fr', name: 'TND', decimalDigits: 2);
  final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  /// Build PDF bytes for a Devis object.
  Future<Uint8List> buildDevisPdfBytes(Devis devis, {String? footerNote}) async {
    final pdf = pw.Document();

    // load optional fonts (fall back to built-in)
    final ttf = await _loadFont();

    final baseTextStyle = pw.TextStyle(font: ttf, fontSize: 10);
    final headerTextStyle = pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final tableHeaderStyle = pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (context) {
          return <pw.Widget>[
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(devis.client.isNotEmpty ? devis.client : 'Client', style: headerTextStyle),
                    pw.SizedBox(height: 6),
                    if (devis.vehicleInfo != null) pw.Text(devis.vehicleInfo!, style: baseTextStyle),
                    pw.SizedBox(height: 4),
                    pw.Text('Devis #: ${devis.id ?? "-"}', style: baseTextStyle),
                    pw.Text('Statut: ${_niceStatus(devis.status)}', style: baseTextStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: ${_dateFmt.format(devis.createdAt ?? DateTime.now())}', style: baseTextStyle),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Text('Total TTC: ${_currency(devis.totalTTC)}', style: headerTextStyle),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Services table header
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey))),
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 6, child: pw.Text('Désignation', style: tableHeaderStyle)),
                  pw.Expanded(flex: 2, child: pw.Text('Qté', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 3, child: pw.Text('PU', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 3, child: pw.Text('Total', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Services rows
            ...devis.services.map((s) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 6, child: pw.Text(s.piece, style: baseTextStyle)),
                    pw.Expanded(flex: 2, child: pw.Text('${s.quantity}', style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 3, child: pw.Text(_currency(s.unitPrice), style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 3, child: pw.Text(_currency(s.total), style: baseTextStyle, textAlign: pw.TextAlign.right)),
                  ],
                ),
              );
            }).toList(),

            pw.Divider(),

            // Totals block
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('Sous-total pièces: ', style: baseTextStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(devis.totalServicesHT), style: baseTextStyle),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('Main d\'œuvre: ', style: baseTextStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(devis.maindoeuvre), style: baseTextStyle),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('Total HT: ', style: tableHeaderStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(devis.totalHT), style: tableHeaderStyle),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('TVA (${devis.tvaRate.toStringAsFixed(2)}%): ', style: baseTextStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(devis.montantTva), style: baseTextStyle),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Total TTC: ', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 8),
                        pw.Text(_currency(devis.totalTTC), style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            if (footerNote != null && footerNote.isNotEmpty)
              pw.Text(footerNote, style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey700)),

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by GarageLink', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey)),
                pw.Text('Créé: ${_dateFmt.format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Print PDF bytes (uses printing package)
  Future<void> printPdfBytes(Uint8List bytes) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      rethrow;
    }
  }

  /// Save bytes to device storage and return the file path (non-web only).
  /// On web this throws an UnsupportedError.
  Future<String> savePdfToFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      throw UnsupportedError('Saving to local file system is not supported on web.');
    }

    try {
      final Directory dir = await _getDownloadsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Share a PDF file: on web it will use the printing package's share mechanism,
  /// on mobile it will create a temporary file and use share_plus.
  Future<void> sharePdf(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      // Printing.sharePdf works on web
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }

    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'Devis - $filename');
  }

  // ---------------- Helpers ----------------

  String _currency(double v) => _currencyFmt.format(v);

  String _niceStatus(DevisStatus s) {
    switch (s) {
      case DevisStatus.brouillon:
        return 'Brouillon';
      case DevisStatus.envoye:
        return 'Envoyé';
      case DevisStatus.accepte:
        return 'Accepté';
      case DevisStatus.refuse:
        return 'Refusé';
      case DevisStatus.enAttente:
        return 'En attente';
      default:
        return 'Inconnu';
    }
  }

Future<pw.Font?> _loadFont() async {
  try {
    // Charge la font depuis les assets (renvoie ByteData)
    final ByteData fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    // pw.Font.ttf attend ByteData dans la plupart des versions du package `pdf`
    return pw.Font.ttf(fontData);
  } catch (_) {
    // Si l'asset n'existe pas ou en cas d'erreur, retourne null pour utiliser la police par défaut
    return null;
  }
}

   static Future<Uint8List> buildDevisPdf(Devis devis, {String? title, String? footerNote}) {
    // title était utilisé dans l'ancien code ; on le mappe sur footerNote si fourni
    final String? note = footerNote ?? title;
    return PdfService.instance.buildDevisPdfBytes(devis, footerNote: note);
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Sur mobile, use Documents directory (Downloads nécessite permissions additionnelles)
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir;
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }
}
