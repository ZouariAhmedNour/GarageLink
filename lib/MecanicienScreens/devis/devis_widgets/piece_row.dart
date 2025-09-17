// lib/mecanicien/devis/devis_widgets/piece_row.dart
import 'package:flutter/material.dart';
import 'package:garagelink/models/devis.dart' show Service;
import 'package:garagelink/models/pieces.dart';

import 'package:garagelink/utils/format.dart';

class PieceRow extends StatelessWidget {
  final dynamic entry;
  final VoidCallback? onDelete;

  const PieceRow({
    super.key,
    required this.entry,
    this.onDelete,
  });

  String _asString(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  int _toInt(dynamic v, [int fallback = 1]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    String name = '';
    int quantity = 1;
    double unitPrice = 0.0;
    double total = 0.0;

    // 1) Si c'est ton modèle Service (devis)
    if (entry is Service) {
      final Service s = entry as Service;
      name = s.piece;
      quantity = s.quantity;
      unitPrice = s.unitPrice;
      total = s.total;
    }
    // 2) Si c'est ton modèle Piece
    else if (entry is Piece) {
      final Piece p = entry as Piece;
      name = p.name;
      quantity = 1;
      unitPrice = p.prix;
      total = unitPrice * quantity;
    } else {
      // 3) Fallback dynamique (Map ou autre)
      try {
        final dyn = entry as dynamic;
        name = _asString(dyn.nom ?? dyn.name ?? dyn.piece ?? '');
        quantity = _toInt(dyn.quantite ?? dyn.quantity ?? 1, 1);
        unitPrice = _toDouble(dyn.prixUnitaire ?? dyn.prix ?? dyn.unitPrice ?? 0.0, 0.0);
        total = _toDouble(dyn.total ?? (quantity * unitPrice), quantity * unitPrice);
      } catch (_) {
        // Tout échoue -> toString
        name = entry?.toString() ?? '';
        quantity = 1;
        unitPrice = 0.0;
        total = 0.0;
      }
    }

    // S'assurer de la cohérence
    if ((total == 0.0 || total.isNaN) && quantity > 0 && unitPrice > 0.0) {
      total = quantity * unitPrice;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4A90E2), width: 1),
      ),
      elevation: 1,
      child: ListTile(
        title: Text(
          name.isEmpty ? '(sans désignation)' : name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Qté: $quantity  •  PU: ${Fmt.money(unitPrice)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Fmt.money(total), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (onDelete != null)
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
