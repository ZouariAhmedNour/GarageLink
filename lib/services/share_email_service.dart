import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareEmailService {
  static Future<void> sharePdf(Uint8List bytes, {String fileName = 'devis.pdf', String? subject, String? text}) async {
    final box = XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf');
    await Share.shareXFiles([box], subject: subject, text: text);
  }

  /// Ouvre le client email avec sujet/corps. (Les PJ ne sont pas possibles via `mailto:`)
  static Future<void> openEmailClient({required String to, required String subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': subject,
        if (body != null) 'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
