import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/models/user.dart';
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
  Future<Uint8List> buildDevisPdfBytes(Devis devis, User user, {String? footerNote}) async {
    final pdf = pw.Document();
    final ttf = await _loadFont();

    final baseTextStyle = pw.TextStyle(font: ttf, fontSize: 10);
    final headerTextStyle = pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final sectionTitleStyle = pw.TextStyle(font: ttf, fontSize: 11, fontWeight: pw.FontWeight.bold);
    final tableHeaderStyle = pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold);

    // Préparer les données du tableau
    final List<List<String>> tableData = devis.services.map((s) {
      return [
        s.piece,
        '${s.quantity}',
        _currency(s.unitPrice),
        _currency(s.total),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // marges réduites pour mieux utiliser la feuille
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        build: (context) {
          return <pw.Widget>[
            // --- EN-TETE : garage | client/infos devis ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Colonne garage
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if ((user.garagenom ?? '').isNotEmpty)
                        pw.Text(user.garagenom!, style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      if ((user.streetAddress ?? '').isNotEmpty || (user.cityName ?? '').isNotEmpty)
                        pw.Text('${user.streetAddress ?? ''}${(user.streetAddress != null && user.cityName != null) ? ', ' : ''}${user.cityName ?? ''}', style: baseTextStyle),
                      if ((user.governorateName ?? '').isNotEmpty) pw.Text(user.governorateName!, style: baseTextStyle),
                      if ((user.matriculefiscal ?? '').isNotEmpty) pw.Text('Matricule fiscale : ${user.matriculefiscal!}', style: baseTextStyle),
                      if ((user.phone ?? '').isNotEmpty) pw.Text('Tel: ${user.phone!}', style: baseTextStyle),
                      if ((user.email ?? '').isNotEmpty) pw.Text('Email: ${user.email!}', style: baseTextStyle),
                    ],
                  ),
                ),

                // Colonne client / devis
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Client', style: sectionTitleStyle),
                      pw.SizedBox(height: 6),
                      pw.Text(devis.clientName.isNotEmpty ? devis.clientName : '-', style: pw.TextStyle(font: ttf, fontSize: 12)),
                      pw.SizedBox(height: 8),
                      pw.Text('Véhicule :', style: sectionTitleStyle),
                      pw.Text(devis.vehicleInfo ?? '-', style: baseTextStyle),
                      pw.SizedBox(height: 8),
                      pw.Text('Devis # ${devis.id ?? '-'}', style: baseTextStyle),
                      pw.Text('Statut : ${_niceStatus(devis.status)}', style: baseTextStyle),
                      pw.Text('Date : ${_dateFmt.format(devis.createdAt ?? DateTime.now())}', style: baseTextStyle),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // --- TABLEAU SERVICES (utilise plus d'espace horizontal) ---
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey))),
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 6, child: pw.Text('Désignation', style: tableHeaderStyle)),
                  pw.Expanded(flex: 1, child: pw.Text('Qté', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('PU', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Lignes — si beaucoup, la page passera naturellement à la suivante
            ...tableData.map((row) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 6, child: pw.Text(row[0], style: baseTextStyle)),
                    pw.Expanded(flex: 1, child: pw.Text(row[1], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(row[2], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(row[3], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                  ],
                ),
              );
            }).toList(),

            pw.Divider(),

            // --- BLOC TOTAUX (aligné à droite, compact et visible) ---
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Sous-total pièces : ', style: baseTextStyle),
                        pw.SizedBox(width: 8),
                        pw.Text(_currency(devis.totalServicesHT), style: baseTextStyle),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Main d\'oeuvre : ', style: baseTextStyle),
                        pw.SizedBox(width: 8),
                        pw.Text(_currency(devis.maindoeuvre), style: baseTextStyle),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Total HT : ', style: tableHeaderStyle),
                        pw.SizedBox(width: 8),
                        pw.Text(_currency(devis.totalHT), style: tableHeaderStyle),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('TVA (${devis.tvaRate.toStringAsFixed(2)}%) : ', style: baseTextStyle),
                        pw.SizedBox(width: 8),
                        pw.Text(_currency(devis.montantTVA), style: baseTextStyle),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Total TTC : ', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 8),
                          pw.Text(_currency(devis.totalTTC), style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 14),

            // footerNote optionnel (placé avant footer de page)
            if (footerNote != null && footerNote.isNotEmpty)
              pw.Text(footerNote, style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey700)),

            // petit pied de page : date de création seulement (sans "Généré par ...")
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Créé: ${_dateFmt.format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey)),
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
  Future<void> sharePdf(Uint8List bytes, String filename, {String? subject, String? text, List<String>? to}) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }

    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    final xfile = XFile(file.path);

    String combinedText = text ?? '';
    if (to != null && to.isNotEmpty) {
      combinedText = 'Destinataire(s): ${to.join(', ')}\n\n$combinedText';
    }

    await Share.shareXFiles([xfile], text: combinedText, subject: subject);
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
    }
  }

  Future<pw.Font?> _loadFont() async {
    try {
      final ByteData fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> buildDevisPdf(Devis devis, User user, {String? title, String? footerNote}) {
    final String? note = footerNote ?? title;
    return PdfService.instance.buildDevisPdfBytes(devis, user, footerNote: note);
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
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

extension PdfServiceFacture on PdfService {
  Future<Uint8List> buildFacturePdfBytes(Facture facture, {String? footerNote}) async {
    final pdf = pw.Document();
    final ttf = await _loadFont();

    final baseTextStyle = pw.TextStyle(font: ttf, fontSize: 10);
    final headerTextStyle = pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final sectionTitleStyle = pw.TextStyle(font: ttf, fontSize: 11, fontWeight: pw.FontWeight.bold);
    final tableHeaderStyle = pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold);

    final double partsTotalFromRows = facture.services.fold<double>(0.0, (sum, s) => sum + (s.total));
    final double maindoeuvre = facture.maindoeuvre;
    final double partsHT = (partsTotalFromRows > 0) ? partsTotalFromRows : 0.0;
    final double totalHT = (facture.totalHT > 0) ? facture.totalHT : (partsHT + maindoeuvre);
    final double tvaRate = (facture.tvaRate > 0) ? facture.tvaRate : 0.0;
    final double totalTVA = (facture.totalTVA > 0) ? facture.totalTVA : (totalHT * tvaRate / 100.0);
    final double totalTTC = (facture.totalTTC > 0) ? facture.totalTTC : (totalHT + totalTVA);

    // table data
    final List<List<String>> tableData = facture.services.map((s) {
      final refStr = (s.pieceId != null && s.pieceId!.isNotEmpty) ? s.pieceId! : '-';
      return [s.piece ?? '', refStr, '${s.quantity}', _currency(s.unitPrice), _currency(s.total)];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        build: (context) {
          return <pw.Widget>[
            // header: client / véhicule | infos facture
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(facture.clientInfo.nom ?? 'Client', style: sectionTitleStyle),
                      pw.SizedBox(height: 6),
                      if (facture.clientInfo.telephone != null && facture.clientInfo.telephone!.isNotEmpty)
                        pw.Text('Tel: ${facture.clientInfo.telephone}', style: baseTextStyle),
                      if (facture.clientInfo.email != null && facture.clientInfo.email!.isNotEmpty)
                        pw.Text(facture.clientInfo.email!, style: baseTextStyle),
                      if (facture.clientInfo.adresse != null && facture.clientInfo.adresse!.isNotEmpty)
                        pw.Text(facture.clientInfo.adresse!, style: baseTextStyle),
                      pw.SizedBox(height: 8),
                      if (facture.vehicleInfo.isNotEmpty)
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text('Véhicule :', style: pw.TextStyle(font: ttf, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(facture.vehicleInfo, style: baseTextStyle),
                        ]),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Facture #: ${facture.numeroFacture}', style: baseTextStyle),
                      pw.SizedBox(height: 6),
                      pw.Text('Date: ${_dateFmt.format(facture.invoiceDate)}', style: baseTextStyle),
                      pw.SizedBox(height: 6),
                      pw.Text('Échéance: ${_dateFmt.format(facture.dueDate)}', style: baseTextStyle),
                      pw.SizedBox(height: 6),
                      if (facture.createdBy != null && facture.createdBy!.isNotEmpty)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                          child: pw.Text('Mécanicien: ${facture.createdBy}', style: baseTextStyle),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // table header
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey))),
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 6, child: pw.Text('Désignation', style: tableHeaderStyle)),
                  pw.Expanded(flex: 2, child: pw.Text('Réf', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Qté', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('PU', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: tableHeaderStyle, textAlign: pw.TextAlign.right)),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // rows
            ...tableData.map((row) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 6, child: pw.Text(row[0], style: baseTextStyle)),
                    pw.Expanded(flex: 2, child: pw.Text(row[1], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(row[2], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(row[3], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(row[4], style: baseTextStyle, textAlign: pw.TextAlign.right)),
                  ],
                ),
              );
            }).toList(),

            pw.Divider(),

            // totals block
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                      pw.Text('Sous-total pièces: ', style: baseTextStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(partsHT), style: baseTextStyle),
                    ]),
                    pw.SizedBox(height: 6),
                    pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                      pw.Text('Main d\'oeuvre: ', style: baseTextStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(maindoeuvre), style: baseTextStyle),
                    ]),
                    pw.SizedBox(height: 6),
                    pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                      pw.Text('Total HT: ', style: tableHeaderStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(totalHT), style: tableHeaderStyle),
                    ]),
                    pw.SizedBox(height: 6),
                    pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                      pw.Text('TVA (${tvaRate.toStringAsFixed(2)}%): ', style: baseTextStyle),
                      pw.SizedBox(width: 8),
                      pw.Text(_currency(totalTVA), style: baseTextStyle),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                        pw.Text('Total TTC: ', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 8),
                        pw.Text(_currency(totalTTC), style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 14),

            if (facture.notes != null && facture.notes!.isNotEmpty) ...[
              pw.Text('Notes:', style: sectionTitleStyle),
              pw.SizedBox(height: 6),
              pw.Text(facture.notes!, style: baseTextStyle),
            ],

            if (footerNote != null && footerNote.isNotEmpty)
              pw.Padding(padding: const pw.EdgeInsets.only(top: 12), child: pw.Text(footerNote, style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey700))),

            pw.SizedBox(height: 8),
            pw.Divider(),
            // juste la date, sans "Généré par..."
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Créé: ${_dateFmt.format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey))),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
