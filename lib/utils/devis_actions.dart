// lib/mecanicien/devis/utils/devis_actions.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/historique_devis_provider.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:garagelink/services/share_email_service.dart';

/// Sauvegarde le devis courant comme brouillon (ajoute/replace dans l'historique)
Future<void> saveDraft(WidgetRef ref) async {
  final providerState = ref.read(devisProvider);
  final Devis d = providerState.toDevis().copyWith(status: DevisStatus.brouillon);
  ref.read(historiqueDevisProvider.notifier).ajouterDevis(d);
}

/// Génère PDF et lance le partage (email). Après partage on marque le devis comme 'envoye'
/// previewPng optionnel si tu veux joindre une image d'aperçu.
Future<void> generateAndSendDevis(WidgetRef ref, BuildContext context, {Uint8List? previewPng, String adminEmail = 'admin@tondomaine.com'}) async {
  final providerState = ref.read(devisProvider);
  Devis d = providerState.toDevis().copyWith(status: DevisStatus.envoye);

  // 1) Enregister/mettre à jour dans l'historique comme envoye
  ref.read(historiqueDevisProvider.notifier).ajouterDevis(d);

  // 2) Générer PDF
  final Uint8List pdfBytes = await PdfService.buildDevisPdf(d);

  // 3) Préparer email body (ici mailto links pour action manuelle)
  final id = d.id;
  final acceptMailto = Uri(
    scheme: 'mailto',
    path: adminEmail,
    queryParameters: {
      'subject': 'ACCEPTER DEVIS $id',
      'body': 'Je confirme l\\''acceptation du devis $id\n\nClient: ${d.client}\nMontant: ${d.totalTtc.toStringAsFixed(2)}'
    },
  ).toString();


  final refuseMailto = Uri(
    scheme: 'mailto',
    path: adminEmail,
    queryParameters: {
      'subject': 'REFUSER DEVIS $id',
      'body': 'Je refuse le devis $id\n\nClient: ${d.client}\nMontant: ${d.totalTtc.toStringAsFixed(2)}'
    },
  ).toString();

  final emailBody = '''
Bonjour,

Veuillez trouver ci-joint le devis (ID: $id).

Actions :
- Accepter (envoyer un mail) : $acceptMailto
- Refuser  (envoyer un mail) : $refuseMailto

Cordialement,
GarageLink
''';

  // 4) Partage (joint le PDF et la preview si fournie)
  await ShareEmailService.sharePdf(
    pdfBytes,
    fileName: 'devis_$id.pdf',
    subject: 'Devis GarageLink - $id',
    text: emailBody,
    previewPng: previewPng,
  );

  // 5) Optionnel: montrer un SnackBar
  if (ScaffoldMessenger.maybeOf(context) != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Devis $id enregistré et partage ouvert.')));
  }
}
