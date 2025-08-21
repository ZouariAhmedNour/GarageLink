// share_email_service.dart
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareEmailService {
  static Future<void> sharePdf(
    Uint8List bytes, {
    String fileName = 'devis.pdf',
    String? subject,
    String? text,
    Uint8List? previewPng,
  }) async {
    final List<XFile> attachments = [
      XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf'),
    ];
    if (previewPng != null) {
      attachments.add(XFile.fromData(previewPng, name: 'preview.png', mimeType: 'image/png'));
    }
    await Share.shareXFiles(attachments, subject: subject, text: text);
  }

  static Future<void> openEmailClient({required String to, required String subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {'subject': subject, if (body != null) 'body': body},
    );
    await launchUrl(uri);
  }
}
