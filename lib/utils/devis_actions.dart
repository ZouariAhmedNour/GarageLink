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

/// Génère PDF et lance le partage (email).
/// Si [devisToSend] est fourni, on l'utilise, sinon on prend le devis courant du provider.
Future<void> generateAndSendDevis(
  WidgetRef ref,
  BuildContext context, {
  Uint8List? previewPng,
  String adminEmail = 'admin@tondomaine.com',
  Devis? devisToSend,
}) async {
  // Prendre soit le devis passé, soit le devis courant du provider
  final Devis base = devisToSend ?? ref.read(devisProvider).toDevis();

  // Marquer comme envoye
  final Devis d = base.copyWith(status: DevisStatus.envoye);

  // 1) Enregistrer/mettre à jour dans l'historique comme envoye
  ref.read(historiqueDevisProvider.notifier).ajouterDevis(d);

  // 2) Générer PDF
  final Uint8List pdfBytes = await PdfService.buildDevisPdf(d);

  // 3) Préparer email body (avec liens cliquables)
  final id = d.id;
  final baseUrl = 'https://tondomaine.com'; // change pour ton domaine
  final acceptUrl = '$baseUrl/devis/$id/accept';
  final refuseUrl = '$baseUrl/devis/$id/refuse';

  final emailBody = '''
Bonjour,

Veuillez trouver ci-joint le devis (ID: $id).

Actions :
- Accepter : $acceptUrl
- Refuser  : $refuseUrl

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

  // 5) SnackBar
  if (ScaffoldMessenger.maybeOf(context) != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Devis $id enregistré et partage ouvert.')),
    );
  }
}
