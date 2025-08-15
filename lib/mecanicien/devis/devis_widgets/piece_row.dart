import 'package:flutter/material.dart';
import 'package:garagelink/mecanicien/devis/models/piece.dart';
import 'package:garagelink/utils/format.dart';


class PieceRow extends StatelessWidget {
  final Piece piece;
  final VoidCallback onDelete;
  const PieceRow({super.key, required this.piece, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
  color: Colors.white, // même fond que ModernCard
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: Color(0xFF4A90E2), width: 1), // bordure bleue
  ),
  elevation: 1,
  child: ListTile(
    title: Text(
      piece.nom,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Qté: ${piece.quantite}  •  PU: ${Fmt.money(piece.prixUnitaire)}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Fmt.money(piece.total),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ],
    ),
  ),
);
  }
}
