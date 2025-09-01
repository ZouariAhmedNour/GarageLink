// lib/services/pdf_service.dart
import 'dart:typed_data';

import 'package:garagelink/models/devis.dart';
import 'package:garagelink/utils/format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  /// Génère un document. [title] est "Devis" par défaut; passe "Facture" pour générer la facture.
  static Future<Uint8List> buildDevisPdf(Devis devis, {String title = 'Devis'}) async {
    final doc = pw.Document();

    final tableHeaders = ['Article', 'Qté', 'PU', 'Total'];

    // Calculs utiles
    final double sousTotalBrut = devis.sousTotal; // avant remise
    final double remiseAmount = (sousTotalBrut - devis.totalHt).clamp(0.0, double.infinity);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('GarageLink', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text(title, style: pw.TextStyle(fontSize: 16)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Date: ${Fmt.date(devis.date)}'),
                pw.Text('Client: ${devis.client}'),
                pw.Text('N° Série: ${devis.numeroSerie}'),
                pw.Text('${title} ID: ${devis.id}'),
              ]),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: tableHeaders,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            data: [
              ...devis.pieces.map((p) => [
                    p.nom,
                    p.quantite.toString(),
                    Fmt.money(p.prixUnitaire),
                    Fmt.money(p.total),
                  ]),
              ['Main d oeuvre', '-', '-', Fmt.money(devis.mainOeuvre)],
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 250,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
                  // Afficher le Sous-total brut avant remise
                  _line('Sous-total (HT brut)', Fmt.money(sousTotalBrut)),
                   pw.SizedBox(height: 6),

                  // Affiche la remise (en % et montant) seulement si > 0
                  if (devis.remise > 0)
                    pw.Column(children: [
                      _line('Remise (${(devis.remise * 100).toStringAsFixed(0)}%)', '- ${Fmt.money(remiseAmount)}'),
                      pw.SizedBox(height: 6),
                    ]),

                  // Total HT après remise
                  _line('Total HT', Fmt.money(devis.totalHt)),
                   pw.SizedBox(height: 6),

                  // Montant TVA (appliquée sur le Total HT)
                  _line('Montant TVA (${(devis.tva * 100).toStringAsFixed(0)}%)', Fmt.money(devis.montantTva)),
                  pw.Divider(),
                  // Total TTC final
                  _line('Total TTC', Fmt.money(devis.totalTtc), bold: true),
                ]),
              )
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Durée estimée de travail: ${Fmt.duration(devis.dureeEstimee)}'),
          pw.SizedBox(height: 8),

          if (title.toLowerCase() == 'facture')
            pw.Column(children: [
              pw.Text('Facture émise. Paiement : selon conditions convenues.'),
              pw.SizedBox(height: 6),
              pw.Text('Merci pour votre confiance.'),
            ])
          else
            pw.Column(children: [
              pw.Text('Conditions: Devis valable 15 jours. Paiement à la livraison du véhicule.'),
            ]),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _line(String label, String value, {bool bold = false}) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      );
}
