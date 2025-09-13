import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/utils/show_modern_snackbar.dart';
import 'package:garagelink/models/devis.dart';

void onGenerate({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required List<DevisService> services,
}) {
  if (!formKey.currentState!.validate()) return;
  if (services.isEmpty) {
    showModernSnackBar(context, 'Ajoutez au moins une pièce.', Colors.orange);
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const DevisPreviewPage()),
  );
}
