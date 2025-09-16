// lib/mecanicien/devis/utils/devis_actions.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:garagelink/global.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/historique_devis_provider.dart';
import 'package:garagelink/services/devis_api.dart';
import 'package:garagelink/services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';


final DevisApi _devisApi = DevisApi(baseUrl: UrlApi); // ✅ instance globale
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
  Devis? devisToSend,
  String? recipientEmail,
}) async {
  final Devis base = devisToSend ?? ref.read(devisProvider).toDevis();
  final Devis toSave = base.copyWith(status: DevisStatus.envoye);

  try {
    // 1) récupérer token
    String? authToken;
    try {
      authToken = await const FlutterSecureStorage().read(key: 'token');
    } catch (e) {
      debugPrint('Impossible de lire token: $e');
    }

    // 2) préparer payload
    final payload = toSave.toJson()..addAll({'status': statusToString(DevisStatus.envoye)});

    // 3) create or update on server
    Map<String, dynamic> res;
    if (toSave.id != null && toSave.id!.isNotEmpty) {
      res = await _devisApi.updateDevis(toSave.id!, payload, token: authToken);
    } else {
      res = await _devisApi.createDevis(payload, token: authToken);
    }

    if (res['success'] != true) {
      final msg = res['message'] ?? 'Erreur création/mise à jour du devis';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // Récupérer l'objet créé — backend renvoie souvent 'data' contenant le doc
    Devis created = toSave;
    Map<String, dynamic>? rawBody;
    if (res['data'] is Devis) {
      created = res['data'] as Devis;
    } else if (res['data'] is Map<String, dynamic>) {
      created = Devis.fromJson(Map<String, dynamic>.from(res['data']));
      rawBody = Map<String, dynamic>.from(res['data']);
    } else if (res['raw'] is Map) {
      rawBody = Map<String, dynamic>.from(res['raw']);
      try {
        created = Devis.fromJson(rawBody);
      } catch (_) {}
    }

    // 4) ajout/modif historique local
    final historique = ref.read(historiqueDevisProvider);
    final idx = historique.indexWhere((d) => d.id == created.id);
    if (idx == -1) {
      ref.read(historiqueDevisProvider.notifier).ajouterDevis(created);
    } else {
      ref.read(historiqueDevisProvider.notifier).modifierDevis(idx, created);
    }

    // 5) générer PDF bytes
    final Uint8List pdfBytes = await PdfService.buildDevisPdf(created);

    // 6) encode base64
    final String pdfBase64 = base64Encode(pdfBytes);
    final String fileName = 'devis_${created.id ?? DateTime.now().millisecondsSinceEpoch}.pdf';

    // 7) Construire mailBody (texte + html) — tu peux réutiliser ton html/text
    final String mailText = '''
Bonjour ${created.client},

Veuillez trouver ci-joint le devis (N°: ${created.id ?? ''}).

Total TTC: ${created.totalTTC.toStringAsFixed(3)} Dinars
''';

    final String mailHtml = '''
<html><body>
  <p>Bonjour ${created.client},</p>
  <p>Veuillez trouver ci-joint le devis <strong>N° ${created.id ?? ''}</strong>.</p>
  <p><strong>Total TTC:</strong> ${created.totalTTC.toStringAsFixed(3)} Dinars</p>
  <p>Cordialement,<br/>Votre garage</p>
</body></html>
''';

    // 8) Appel serveur pour envoyer l'email (endpoint : POST /devis/:devisId/send-email)
    final Map<String, dynamic> mailPayload = {
      'subject': 'Devis GarageLink - ${created.id ?? ''}',
      'text': mailText,
      'html': mailHtml,
      'attachment': {
        'filename': fileName,
        'content': pdfBase64,
      },
      // optionnel: 'to': recipientEmail ?? created.clientEmail
    };

    final String idForServer = rawBody?['_id']?.toString() ?? created.id ?? '';

    final serverSendRes = await _devisApi.sendDevisByEmail(
      idForServer,
      body: mailPayload,
      token: authToken,
    );

    if (serverSendRes['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis envoyé par le serveur (email HTML).')),
      );
      return;
    }

    // 9) fallback local : ouvrir composeur ou partager
    final clientEmail = recipientEmail?.trim() ?? (created as dynamic).clientEmail;
    if (clientEmail != null && clientEmail.isNotEmpty) {
      // ouvrir mailto si tu veux ; sinon partager pdf
      final subject = Uri.encodeComponent('Devis GarageLink - ${created.id ?? ''}');
      final body = Uri.encodeComponent(mailText);
      final uri = Uri.parse('mailto:$clientEmail?subject=$subject&body=$body');

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boîte mail ouverte')));
        } else {
          // fallback partager
          await PdfService.instance.sharePdf(
            pdfBytes,
            fileName,
            subject: 'Devis GarageLink - ${created.id ?? ''}',
            text: mailText,
            to: [clientEmail],
          );
        }
      } catch (e) {
        await PdfService.instance.sharePdf(
          pdfBytes,
          fileName,
          subject: 'Devis GarageLink - ${created.id ?? ''}',
          text: mailText,
          to: clientEmail != null ? [clientEmail] : null,
        );
      }
    } else {
      // pas d'email client -> partager
      await PdfService.instance.sharePdf(
        pdfBytes,
        fileName,
        subject: 'Devis GarageLink - ${created.id ?? ''}',
        text: mailText,
        to: null,
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur génération/envoi : $e')));
  }
}