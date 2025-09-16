import 'package:flutter/material.dart';
import 'package:garagelink/models/devis.dart' show DevisService;
import 'package:garagelink/models/pieces.dart' show PieceRechange;
import 'package:garagelink/utils/format.dart';

/// PieceRow flexible : accepte un `entry` qui peut être :
/// - DevisService (recommandé, provient du provider)
/// - PieceRechange (catalogue)
/// - ou un ancien modèle avec champs nom/quantite/prixUnitaire/total
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

    // 1) Known typed models
    if (entry is DevisService) {
      final DevisService s = entry as DevisService;
      name = s.piece;
      quantity = s.quantity;
      unitPrice = s.unitPrice;
      total = s.total;
    } else if (entry is PieceRechange) {
      final PieceRechange p = entry as PieceRechange;
      name = p.name;
      quantity = 1;
      unitPrice = _toDouble(p.prix, 0.0);
      total = unitPrice * quantity;
    } else {
      // 2) Fallback: try dynamic properties (nom, name, piece, quantite, quantity, prixUnitaire, prix, unitPrice, total)
      try {
        final dyn = entry as dynamic;
        name = _asString(dyn.nom ?? dyn.name ?? dyn.piece ?? '');
        quantity = _toInt(dyn.quantite ?? dyn.quantity ?? 1, 1);
        unitPrice = _toDouble(dyn.prixUnitaire ?? dyn.prix ?? dyn.unitPrice ?? 0.0, 0.0);
        total = _toDouble(dyn.total ?? (quantity * unitPrice), quantity * unitPrice);
      } catch (_) {
        // if all fails, try toString
        name = entry?.toString() ?? '';
        quantity = 1;
        unitPrice = 0.0;
        total = 0.0;
      }
    }

    // ensure total sanity
    if (total == 0.0 && quantity > 0 && unitPrice > 0.0) {
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
        title: Text(name.isEmpty ? '(sans désignation)' : name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
