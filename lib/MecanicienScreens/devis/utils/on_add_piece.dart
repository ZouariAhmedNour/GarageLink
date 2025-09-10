import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/models/catalogItem.dart';
import 'package:garagelink/MecanicienScreens/devis/models/piece.dart';

import 'package:garagelink/MecanicienScreens/devis/utils/show_modern_snackbar.dart';
import 'package:garagelink/providers/devis_provider.dart';

void onAddPiece({
  required BuildContext context,
  required WidgetRef ref,
  required CatalogItem? selectedItem,
  required TextEditingController pieceNomCtrl,
  required TextEditingController qteCtrl,
  required TextEditingController puCtrl,
  required VoidCallback onSuccess,
}) {
  if (selectedItem != null) {
    final p = Piece(
      nom: pieceNomCtrl.text.trim(),
      prixUnitaire: double.tryParse(puCtrl.text.trim()) ?? 0,
      quantite: int.tryParse(qteCtrl.text.trim()) ?? 1, id: '', sku: '',
    );
    ref.read(devisProvider.notifier).addPiece(p);
    onSuccess();
    return;
  }

  if (pieceNomCtrl.text.isEmpty) {
    showModernSnackBar(context, 'Veuillez saisir le nom de la pièce.', Colors.orange);
    return;
  }

  final qte = int.tryParse(qteCtrl.text.trim());
  final pu = double.tryParse(puCtrl.text.trim());
  if (qte == null || qte <= 0 || pu == null || pu < 0) {
    showModernSnackBar(context, 'Vérifiez quantité et prix unitaire.', Colors.orange);
    return;
  }

  final p = Piece(
    nom: pieceNomCtrl.text.trim(),
    prixUnitaire: pu,
    quantite: qte, id: '', sku: '', updatedAt: null,
  );
  ref.read(devisProvider.notifier).addPiece(p);
  onSuccess();

  showModernSnackBar(context, 'Pièce ajoutée avec succès !', const Color(0xFF50C878));
}