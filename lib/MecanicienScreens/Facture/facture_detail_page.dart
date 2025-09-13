// lib/mecanicien/devis/facture_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/services/share_email_service.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';

class FactureDetailPage extends ConsumerWidget {
  final Facture facture;
  const FactureDetailPage({Key? key, required this.facture}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientName = facture.clientInfo.nom ?? 'Client';
    final clientEmail = facture.clientInfo.email ?? '';
    final date = facture.invoiceDate ?? facture.createdAt ?? DateTime.now();
    final montant = facture.totalTTC;

    final displayId = facture.numeroFacture.isNotEmpty ? facture.numeroFacture : (facture.id ?? '');

    // Utiliser bodySmall à la place de caption (caption est déprécié)
    final TextStyle? captionStyle = Theme.of(context).textTheme.bodySmall;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Facture ${displayId}',
        backgroundColor: primaryBlue,
        showDelete: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Client', style: captionStyle),
            const SizedBox(height: 6),
            Text(clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(date.toLocal().toString().split(' ')[0]),
            ]),
            const SizedBox(height: 8),

            Row(children: [
              Icon(Icons.attach_money, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text('${montant.toStringAsFixed(2)} DT',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),

            if (clientEmail.isNotEmpty) ...[
              Text('Email', style: captionStyle),
              const SizedBox(height: 6),
              Text(clientEmail),
              const SizedBox(height: 12),
            ],

            if (facture.clientInfo.telephone != null && facture.clientInfo.telephone!.isNotEmpty) ...[
              Text('Téléphone', style: captionStyle),
              const SizedBox(height: 6),
              Text(facture.clientInfo.telephone!),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Télécharger PDF'),
                onPressed: () {
                  // TODO: connecter à PdfService.buildFacturePdfBytes(...) si tu ajoutes cette méthode
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Génération PDF (à connecter au PdfService pour Facture)'),
                  ));
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Imprimer'),
                onPressed: () {
                  // TODO: imprimer le PDF via 'printing' une fois la génération implémentée
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Impression (à connecter au PdfService pour Facture)'),
                  ));
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Envoyer'),
                onPressed: () async {
                  final body = 'Bonjour $clientName,\n\nVeuillez trouver votre facture ${facture.numeroFacture.isNotEmpty ? facture.numeroFacture : facture.id ?? ''}.\n\nCordialement.';
                  await ShareEmailService.openEmailClient(
                    to: clientEmail,
                    subject: 'Votre facture ${facture.numeroFacture.isNotEmpty ? facture.numeroFacture : facture.id ?? ''}',
                    body: body,
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            if (facture.services.isNotEmpty) ...[
              const Text('Détails', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...facture.services.map((s) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.piece),
                  subtitle: Text('Qté: ${s.quantity}  •  PU: ${s.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text(s.total.toStringAsFixed(2)),
                );
              }).toList(),
            ] else ...[
              const SizedBox(height: 8),
              const Text('Aucune ligne de service disponible', style: TextStyle(color: Colors.grey)),
            ],

            const SizedBox(height: 24),

            // éventuels notes
            if (facture.notes != null && facture.notes!.isNotEmpty) ...[
              const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(facture.notes!),
            ],
          ]),
        ),
      ),
    );
  }
}
