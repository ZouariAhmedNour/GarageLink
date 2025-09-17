import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/historique_devis_provider.dart';
import 'package:garagelink/services/devis_api.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

String _statusToString(DevisStatus s) {
  switch (s) {
    case DevisStatus.envoye:
      return 'envoye';
    case DevisStatus.accepte:
      return 'accepte';
    case DevisStatus.refuse:
      return 'refuse';
    case DevisStatus.brouillon:
    return 'brouillon';
  }
}

/// Sauvegarde le devis courant comme brouillon dans l'historique local
Future<void> saveDraft(WidgetRef ref) async {
  final providerState = ref.read(devisProvider);
  final Devis d = providerState.toDevis();
  // assure statut brouillon
  final Devis brouillon = Devis(
    id: d.id,
    devisId: d.devisId,
    clientId: d.clientId,
    clientName: d.clientName,
    vehicleInfo: d.vehicleInfo,
    vehiculeId: d.vehiculeId,
    factureId: d.factureId,
    inspectionDate: d.inspectionDate,
    services: d.services,
    totalHT: d.totalHT,
    totalServicesHT: d.totalServicesHT,
    totalTTC: d.totalTTC,
    tvaRate: d.tvaRate,
    maindoeuvre: d.maindoeuvre,
    estimatedTime: d.estimatedTime,
    status: DevisStatus.brouillon,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  );

  ref.read(historiqueDevisProvider.notifier).ajouterDevis(brouillon);
}

/// Génère un PDF pour le devis (création ou mise à jour côté serveur) puis
/// propose un envoi/partage local (mailto ou partage de PDF).
///
/// - ref : WidgetRef pour accéder aux providers
/// - context : BuildContext pour afficher SnackBars/dialogs
/// - previewPng : optionnel, image preview (pas utilisé pour l'API ici)
/// - devisToSend : si fourni, on l'utilise plutôt que le devis courant du provider
/// - recipientEmail : email du destinataire (optionnel). Si fourni on essaie d'ouvrir mailto.
Future<void> generateAndSendDevis(
  WidgetRef ref,
  BuildContext context, {
  Uint8List? previewPng,
  Devis? devisToSend,
  String? recipientEmail,
}) async {
  final Devis base = devisToSend ?? ref.read(devisProvider).toDevis();

  // Construire Devis avec statut 'envoye'
  final Devis toSave = Devis(
    id: base.id,
    devisId: base.devisId,
    clientId: base.clientId,
    clientName: base.clientName,
    vehicleInfo: base.vehicleInfo,
    vehiculeId: base.vehiculeId,
    factureId: base.factureId,
    inspectionDate: base.inspectionDate,
    services: base.services,
    totalHT: base.totalHT,
    totalServicesHT: base.totalServicesHT,
    totalTTC: base.totalTTC,
    tvaRate: base.tvaRate,
    maindoeuvre: base.maindoeuvre,
    estimatedTime: base.estimatedTime,
    status: DevisStatus.envoye,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
  );

  try {
    // récupérer token si possible (certaines méthodes de DevisApi requièrent token)
    String? token;
    try {
      token = await const FlutterSecureStorage().read(key: 'token');
    } catch (_) {
      token = null;
    }

    // 1) create or update via DevisApi
    Devis created = toSave;
    if (token != null && token.isNotEmpty) {
      if (toSave.id != null && toSave.id!.isNotEmpty) {
        // update (en utilisant id comme identifiant)
        try {
          final updated = await DevisApi.updateDevis(
            token: token,
            id: toSave.id!, // si ton API attend un autre id, adapte ici
            clientId: toSave.clientId,
            clientName: toSave.clientName,
            vehicleInfo: toSave.vehicleInfo,
            inspectionDate: toSave.inspectionDate,
            services: toSave.services,
            tvaRate: toSave.tvaRate,
            maindoeuvre: toSave.maindoeuvre,
            estimatedTime: toSave.estimatedTime,
          );
          created = updated;
        } catch (e) {
          // ignore et essaye la création ensuite
          debugPrint('updateDevis échoué: $e');
        }
      } else {
        // create
        try {
          final createdFromApi = await DevisApi.createDevis(
            token: token,
            clientId: toSave.clientId,
            clientName: toSave.clientName,
            vehicleInfo: toSave.vehicleInfo,
            vehiculeId: toSave.vehiculeId,
            inspectionDate: toSave.inspectionDate,
            services: toSave.services,
            tvaRate: toSave.tvaRate,
            maindoeuvre: toSave.maindoeuvre,
            estimatedTime: toSave.estimatedTime,
          );
          created = createdFromApi;
        } catch (e) {
          debugPrint('createDevis échoué: $e');
        }
      }
    } else {
      debugPrint('Token absent : on ne crée/maj pas côté serveur.');
    }

    // 2) Mettre à jour l'historique local (ajout ou remplacement)
    final historique = ref.read(historiqueDevisProvider);
    final idx = historique.indexWhere((d) =>
        (d.id != null && created.id != null && d.id == created.id) ||
        (d.devisId.isNotEmpty && created.devisId.isNotEmpty && d.devisId == created.devisId));
    if (idx == -1) {
      ref.read(historiqueDevisProvider.notifier).ajouterDevis(created);
    } else {
      ref.read(historiqueDevisProvider.notifier).modifierDevis(idx, created);
    }

    // 3) Générer PDF bytes (utilise ton PdfService)
    Uint8List pdfBytes;
    try {
      pdfBytes = await PdfService.instance.buildDevisPdfBytes(created, footerNote: 'Généré par GarageLink');
    } catch (e) {
      // fallback si ton service a une autre méthode statique
      if (kDebugMode) debugPrint('Erreur buildDevisPdfBytes: $e');
      throw Exception('Impossible de générer le PDF : $e');
    }

    final filename = 'devis_${created.id ?? created.devisId}.pdf';

    // 4) Si on a un recipientEmail fourni, on tente d'ouvrir mailto: (compose)
    if (recipientEmail != null && recipientEmail.trim().isNotEmpty) {
      final subject = Uri.encodeComponent('Devis GarageLink - ${created.id ?? created.devisId}');
      final body = Uri.encodeComponent(
        'Bonjour ${created.clientName},\n\nVeuillez trouver ci-joint le devis.\n\nTotal TTC: ${created.totalTTC.toStringAsFixed(2)}\n\nCordialement,\nVotre garage',
      );
      final uri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boîte mail ouverte')));
        return;
      } else {
        // si mailto impossible, on partage le PDF
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le mail, PDF partagé')));
        return;
      }
    }

    // 5) Pas d'email : on partage le PDF (utilise Printing pour compatibilité mobile/web/desktop)
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF partagé / prêt à être envoyé')));
  } catch (e, st) {
    debugPrint('generateAndSendDevis erreur: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur génération/envoi : $e')));
  }
}
