import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/services/pdf_service.dart';

class FacturePreviewPage extends ConsumerWidget {
  final Facture facture;
  const FacturePreviewPage({super.key, required this.facture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeClient = (facture.clientInfo.nom?.isNotEmpty ?? false)
        ? facture.clientInfo.nom!
        : "client";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aperçu Facture"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await PdfService.instance.buildFacturePdfBytes(
                facture,
                footerNote: "Généré par GarageLink",
              );
              await PdfService.instance.printPdfBytes(bytes);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.instance.buildFacturePdfBytes(
          facture,
          footerNote: "Généré par GarageLink",
        ),
        pdfFileName: "facture_${safeClient}.pdf",
        allowSharing: true,
        allowPrinting: true,
      ),
    );
  }
}
