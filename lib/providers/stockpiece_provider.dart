import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_piece.dart';
import '../models/mouvement.dart';

class StockPieceNotifier extends AsyncNotifier<List<StockPiece>> {
  @override
  Future<List<StockPiece>> build() async {
    // ⚡ Ici tu peux remplacer par un fetch API/MongoDB
    return [];
  }

  /// Ajouter une nouvelle pièce
  Future<void> addPiece(StockPiece piece) async {
    final current = state.value ?? [];
    state = AsyncValue.data([...current, piece]);
  }

  /// Mettre à jour une pièce existante
  Future<void> updatePiece(StockPiece updated) async {
    final current = state.value ?? [];
    final newList = current.map((p) => p.id == updated.id ? updated : p).toList();
    state = AsyncValue.data(newList);
  }

  /// Appliquer un mouvement (entrée ou sortie)
  void applyMouvement(Mouvement mvt) {
    final current = state.value ?? [];
    final index = current.indexWhere((p) => p.id == mvt.pieceId);
    if (index != -1) {
      final piece = current[index];
      final newQty = mvt.type == TypeMouvement.entree
          ? piece.quantite + mvt.quantite
          : piece.quantite - mvt.quantite;
      final updatedPiece = piece.copyWith(
        quantite: newQty,
        updatedAt: DateTime.now(),
      );
      final newList = [...current];
      newList[index] = updatedPiece;
      state = AsyncValue.data(newList);
    }
  }

  /// Annuler un mouvement (inverse de apply)
  void revertMouvement(Mouvement mvt) {
    final current = state.value ?? [];
    final index = current.indexWhere((p) => p.id == mvt.pieceId);
    if (index != -1) {
      final piece = current[index];
      final newQty = mvt.type == TypeMouvement.entree
          ? piece.quantite - mvt.quantite
          : piece.quantite + mvt.quantite;
      final updatedPiece = piece.copyWith(
        quantite: newQty,
        updatedAt: DateTime.now(),
      );
      final newList = [...current];
      newList[index] = updatedPiece;
      state = AsyncValue.data(newList);
    }
  }
}

/// Provider Riverpod
final stockPieceProvider =
    AsyncNotifierProvider<StockPieceNotifier, List<StockPiece>>(() {
  return StockPieceNotifier();
});
