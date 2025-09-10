import 'package:flutter/material.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/models/piece.dart';
import 'package:garagelink/MecanicienScreens/devis/utils/show_modern_snackbar.dart';


void onGenerate({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required List<Piece> pieces,
}) {
  if (!formKey.currentState!.validate()) return;
  if (pieces.isEmpty) {
    showModernSnackBar(context, 'Ajoutez au moins une pièce.', Colors.orange);
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const DevisPreviewPage()),
  );
}