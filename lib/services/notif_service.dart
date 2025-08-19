import 'package:url_launcher/url_launcher.dart';

class ShareNotifService {
  static Future<void> openEmailClient({
    required String to,
    required String subject,
    required String body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

if (await canLaunchUrl(emailUri)) {
  await launchUrl(
    emailUri,
    mode: LaunchMode.externalApplication, // <-- important
  );
} else {
  throw Exception("Impossible d’ouvrir le client email.");
}
  }

  static Future<void> openSmsClient({
    required String phone,
    required String message,
  }) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
  await launchUrl(
    smsUri,
    mode: LaunchMode.externalApplication,
  );
} else {
  throw Exception("Impossible d’ouvrir l’application SMS.");
}

  }
}
