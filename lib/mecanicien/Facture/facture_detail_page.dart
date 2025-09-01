import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/services/share_email_service.dart';

class FactureDetailPage extends ConsumerWidget {
  final Facture facture;
  const FactureDetailPage({Key? key, required this.facture}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Facture ${facture.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${facture.clientName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Date: ${facture.date.toLocal().toString().split(" ")[0]}'),
            SizedBox(height: 8),
            Text('Montant: ${facture.montant.toStringAsFixed(2)} DT', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Télécharger PDF'),
                  onPressed: () async {
                    // TODO: connecter à un PdfService qui génère un PDF à partir des détails (ou du devis source si dispo).
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Génération PDF (à connecter au Devis/PdfService)'))); 
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.print),
                  label: Text('Imprimer'),
                  onPressed: () async {
                    // TODO: imprimer le PDF via package 'printing' après génération.
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impression (à connecter au PDF)')));
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text('Envoyer'),
                  onPressed: () async {
                    final body = 'Bonjour ${facture.clientName},\n\nVeuillez trouver votre facture ${facture.id}.\n\nCordialement.';
                    final to = facture.clientEmail ?? ''; // si vide, ShareEmailService peut ouvrir client mail sans destinataire
                    await ShareEmailService.openEmailClient(
                      to: to,
                      subject: 'Votre facture ${facture.id}',
                      body: body,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
