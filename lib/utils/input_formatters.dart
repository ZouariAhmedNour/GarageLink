import 'package:flutter/services.dart';

class TunisiePhoneFormatter extends TextInputFormatter {
  final String prefix = '+216';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Si on essaie de supprimer ou modifier le préfixe, on empêche le changement
    if (!newValue.text.startsWith(prefix)) {
      return oldValue;
    }
    return newValue;
  }
}
