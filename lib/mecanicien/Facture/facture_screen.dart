import 'package:flutter/material.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:garagelink/services/share_email_service.dart';

class FactureScreen extends StatelessWidget {
  final Devis devis;
  const FactureScreen({super.key, required this.devis});

  // helper to create route from a Devis
  static Route fromDevis(Devis d) {
    return MaterialPageRoute(builder: (_) => FactureScreen(devis: d));
  }

  @override
  Widget build(BuildContext context) {
    // Simple: transforme le devis en facture (ici on réutilise le PDF generation)
    return Scaffold(
      appBar: AppBar(title: const Text('Générer facture')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Générer et envoyer la facture'),
          onPressed: () async {
            // Ici, tu devrais mapper Devis -> Facture model si tu veux conserver la facture
            final bytes = await PdfService.buildDevisPdf(devis); // réutilise le PDF pour la facture ou crée un PdfService.buildFacture
            await ShareEmailService.sharePdf(bytes, fileName: 'facture_${devis.id}.pdf', subject: 'Facture GarageLink');
          },
        ),
      ),
    );
  }
}
