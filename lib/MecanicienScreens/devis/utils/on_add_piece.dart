// on_add_piece.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart' show Service;
import 'package:garagelink/models/pieces.dart' show Piece;

import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/MecanicienScreens/devis/utils/show_modern_snackbar.dart';

/// Ajoute une pièce (soit depuis le catalogue Piece, soit saisie libre)
void onAddPiece({
  required BuildContext context,
  required WidgetRef ref,
  required Piece? selectedItem,
  required TextEditingController pieceNomCtrl,
  required TextEditingController qteCtrl,
  required TextEditingController puCtrl,
  required VoidCallback onSuccess,
}) {
  double? _parseDouble(String s) {
    if (s.trim().isEmpty) return null;
    final normalized = s.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  int? _parseInt(String s) {
    if (s.trim().isEmpty) return null;
    return int.tryParse(s.trim());
  }

  // Valeurs fournies par l'UI
  final nameFromCtrl = pieceNomCtrl.text.trim();
  final qteFromCtrl = _parseInt(qteCtrl.text.trim());
  final puFromCtrl = _parseDouble(puCtrl.text.trim());

  // Si selectedItem est fourni, on l'utilise comme source par défaut
  if (selectedItem != null) {
    final name = nameFromCtrl.isEmpty ? selectedItem.name : nameFromCtrl;
    final prixUnit = puFromCtrl ?? selectedItem.prix;
    final quantite = (qteFromCtrl != null && qteFromCtrl > 0) ? qteFromCtrl : 1;

    if (name.isEmpty) {
      showModernSnackBar(context, 'Le nom de la pièce est requis.', Colors.orange);
      return;
    }
    if (prixUnit < 0) {
      showModernSnackBar(context, 'Le prix est invalide.', Colors.orange);
      return;
    }

    // Construire la ligne Service
    final line = Service(
      pieceId: selectedItem.id?.toString() ?? '',
      piece: name,
      quantity: quantite,
      unitPrice: prixUnit,
      total: (quantite * prixUnit),
    );

    ref.read(devisProvider.notifier).addService(line);
    showModernSnackBar(context, 'Pièce ajoutée depuis le catalogue.', const Color(0xFF50C878));
    onSuccess();
    return;
  }

  // Pas d'item sélectionné : validation stricte des champs
  final name = nameFromCtrl;
  if (name.isEmpty) {
    showModernSnackBar(context, 'Veuillez saisir le nom de la pièce.', Colors.orange);
    return;
  }

  final qte = qteFromCtrl ?? 0;
  final pu = puFromCtrl;

  if (qte <= 0) {
    showModernSnackBar(context, 'La quantité doit être un entier positif.', Colors.orange);
    return;
  }
  if (pu == null || pu < 0) {
    showModernSnackBar(context, 'Le prix unitaire est invalide.', Colors.orange);
    return;
  }

  final line = Service(
    pieceId: '',
    piece: name,
    quantity: qte,
    unitPrice: pu,
    total: qte * pu,
  );

  ref.read(devisProvider.notifier).addService(line);
  showModernSnackBar(context, 'Pièce ajoutée avec succès !', const Color(0xFF50C878));
  onSuccess();
}
