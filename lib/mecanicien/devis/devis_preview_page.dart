import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:garagelink/services/share_email_service.dart';
import 'package:printing/printing.dart';

class DevisPreviewPage extends ConsumerWidget {
  const DevisPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devis = ref.watch(devisProvider).toDevis();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Prévisualisation du devis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF4A90E2),
            actions: [
              IconButton(
                tooltip: 'Partager PDF',
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () async {
                  final bytes = await PdfService.buildDevisPdf(devis);
                  await ShareEmailService.sharePdf(
                    bytes,
                    subject: 'Devis GarageLink',
                    text: 'Veuillez trouver ci-joint le devis.',
                  );
                },
              ),
              IconButton(
                tooltip: 'Télécharger PDF',
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                onPressed: () async {
                  final bytes = await PdfService.buildDevisPdf(devis);
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: 'devis_${devis.client}.pdf',
                  );
                },
              ),
              IconButton(
                tooltip: 'Imprimer',
                icon: const Icon(Icons.print_outlined, color: Colors.white),
                onPressed: () async {
                  final bytes = await PdfService.buildDevisPdf(devis);
                  await Printing.layoutPdf(onLayout: (_) => bytes);
                },
              ),
              IconButton(
                tooltip: 'Envoyer par e-mail',
                icon: const Icon(Icons.email_outlined, color: Colors.white),
                onPressed: () async {
                  await ShareEmailService.openEmailClient(
                    to: '',
                    subject: 'Devis GarageLink',
                    body:
                        'Bonjour,\n\nVeuillez trouver ci-joint le devis.\n\nCordialement.',
                  );
                },
              ),
            ],
          ),

          // Contenu PDF
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: PdfPreview(
                canChangeOrientation: false,
                canChangePageFormat: false,
                build: (format) => PdfService.buildDevisPdf(devis),
                pdfFileName: 'devis_${devis.client}.pdf',
                allowSharing: false, // car on a déjà nos boutons persos
              ),
            ),
          ),
        ],
      ),
    );
  }
}
