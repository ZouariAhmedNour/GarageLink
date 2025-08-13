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
      appBar: AppBar(
        title: const Text('Prévisualisation du devis'),
        actions: [
          IconButton(
            tooltip: 'Partager PDF',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final bytes = await PdfService.buildDevisPdf(devis);
              await ShareEmailService.sharePdf(bytes, subject: 'Devis GarageLink', text: 'Veuillez trouver ci-joint le devis.');
            },
          ),
          IconButton(
            tooltip: 'Envoyer par e-mail (sans PJ)',
            icon: const Icon(Icons.email_outlined),
            onPressed: () async {
              await ShareEmailService.openEmailClient(
                to: '',
                subject: 'Devis GarageLink',
                body: 'Bonjour,\n\nVeuillez trouver ci-joint le devis.\n\nCordialement.',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        build: (format) => PdfService.buildDevisPdf(devis),
      ),
    );
  }
}
