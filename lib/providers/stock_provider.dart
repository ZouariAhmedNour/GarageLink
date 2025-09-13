// lib/providers/stock_alerts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/stock_piece.dart';
import 'package:garagelink/providers/stockpiece_provider.dart';

/// Représente une alerte de stock à partir d'une StockPiece
class StockAlert {
  final StockPiece piece;
  StockAlert(this.piece);

  // Délégations vers la pièce (évite duplication)
  int get seuilMin => piece.seuilMin;
  int? get seuilMax => piece.seuilMax;

  bool get isLow => piece.quantite <= seuilMin;
  bool get isOver => seuilMax != null && piece.quantite > seuilMax!;
}

/// Fournit la liste des alertes (filtrage des pièces en dessous/au-dessus des seuils)
final stockProvider = Provider<List<StockAlert>>((ref) {
  final piecesAsync = ref.watch(stockPieceProvider);

  return piecesAsync.when(
    data: (pieces) {
      return pieces
          .map((p) => StockAlert(p))
          .where((a) => a.isLow || a.isOver)
          .toList();
    },
    loading: () => <StockAlert>[],
    error: (_, __) => <StockAlert>[],
  );
});
