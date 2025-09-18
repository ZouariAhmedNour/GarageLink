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
import 'package:garagelink/global.dart'; // UrlApi

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

/// Helper utilitaire pour nettoyer sauts de ligne multiples avant encodage mailto
String _removeExtraNewlines(String s) {
  return s.replaceAll(RegExp(r'\n{2,}'), '\n\n').trim();
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

  // Construire Devis avec statut 'envoye' localement (pour l'historique)
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
    // récupérer token si possible
    String? token;
    try {
      token = await const FlutterSecureStorage().read(key: 'token');
    } catch (_) {
      token = null;
    }

    // 1) create or update via DevisApi (best-effort)
    Devis created = toSave;
    if (token != null && token.isNotEmpty) {
      if (toSave.id != null && toSave.id!.isNotEmpty) {
        // update (on suppose que l'API accepte l'_id Mongo ou le custom id selon usage)
        try {
          final updated = await DevisApi.updateDevis(
            token: token,
            id: toSave.id!, // adapte si ton API attend DEVxxx ici
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

    // -------------------------------------------------------------------------
    // Envoi via serveur : IMPORTANT -> l'endpoint send-email côté backend
    // recherche le devis avec le champ "id" (le custom DEVxxx). Donc on
    // DOIT transmettre le DEVxxx (created.devisId) si disponible.
    // -------------------------------------------------------------------------
    final String idForServerSend = (created.devisId.isNotEmpty) ? created.devisId : (created.id ?? '');
    // Pour construire les liens d'accept/refuse (qui utilisent findByIdAndUpdate)
    // il faut l'_id Mongo du document : created.id (si présent)
    final String mongoIdForLinks = (created.id != null && created.id!.isNotEmpty) ? created.id! : '';

    // Si on a un token ET qu'aucun recipientEmail n'a été fourni,
    // on privilégie l'envoi via le backend (il prendra l'email client et enverra le mail + liens).
    if (token != null && token.isNotEmpty && (recipientEmail == null || recipientEmail.trim().isEmpty) && idForServerSend.isNotEmpty) {
      try {
        await DevisApi.sendDevisByEmail(token: token, devisId: idForServerSend);
        // Best-effort : mettre à jour l'historique local si besoin (backend mettra status envoye)
        try {
          ref.read(historiqueDevisProvider.notifier).updateStatusById(idForServerSend, DevisStatus.envoye);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devis envoyé par le serveur (email envoyé)'), backgroundColor: Colors.green),
        );
        return; // terminé : l'envoi est fait par le backend
      } catch (e) {
        // échec de l'envoi via backend -> on bascule en fallback local
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Envoi via serveur échoué : ${e.toString()} — utilisation du partage local'), backgroundColor: Colors.orange),
        );
        // on continue vers la génération PDF + partage
      }
    }

    // 3) Générer PDF bytes (fallback / mailto / partage local)
    Uint8List pdfBytes;
    try {
      pdfBytes = await PdfService.instance.buildDevisPdfBytes(created, footerNote: 'Généré par GarageLink');
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur buildDevisPdfBytes: $e');
      throw Exception('Impossible de générer le PDF : $e');
    }

    final filename = 'devis_${created.id ?? created.devisId}.pdf';

    // Construire les URLs d'accept/refuse basées sur mongoIdForLinks (si disponible)
    // UrlApi peut être 'http://host:port' ou 'http://host:port/api' ; on veut la base sans /api
    String baseUrl = UrlApi;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }
    final String acceptUrl = mongoIdForLinks.isNotEmpty ? '$baseUrl/api/devis/$mongoIdForLinks/accept' : '';
    final String refuseUrl = mongoIdForLinks.isNotEmpty ? '$baseUrl/api/devis/$mongoIdForLinks/refuse' : '';

    // 4) Si recipientEmail fourni -> on essaie mailto: vers cette adresse (compose)
    // On inclut dans le corps les liens d'accept/refuse (si on possède l'_id Mongo)
    if (recipientEmail != null && recipientEmail.trim().isNotEmpty) {
      final subject = Uri.encodeComponent('Devis GarageLink - ${created.devisId.isNotEmpty ? created.devisId : (created.id ?? '')}');

      final buffer = StringBuffer();
      buffer.writeln('Bonjour ${created.clientName},');
      buffer.writeln();
      buffer.writeln('Veuillez trouver ci-joint le devis.');
      buffer.writeln('Total TTC: ${created.totalTTC.toStringAsFixed(2)} DT');
      buffer.writeln();
      if (acceptUrl.isNotEmpty && refuseUrl.isNotEmpty) {
        buffer.writeln('Vous pouvez accepter ou refuser ce devis en cliquant sur les liens suivants :');
        buffer.writeln('Accepter : $acceptUrl');
        buffer.writeln('Refuser  : $refuseUrl');
        buffer.writeln();
      }
      buffer.writeln('Cordialement,');
      buffer.writeln('Votre garage');

      final body = Uri.encodeComponent(_removeExtraNewlines(buffer.toString()));
      final uri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boîte mail ouverte')));
        return;
      } else {
        // mailto impossible -> partager le PDF
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le mail, PDF partagé')));
        return;
      }
    }

    // 5) Pas d'email fourni et on n'a pas (ou pas pu) envoyer via serveur -> partager le PDF
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF partagé / prêt à être envoyé')));
  } catch (e, st) {
    debugPrint('generateAndSendDevis erreur: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur génération/envoi : $e')));
  }
}
