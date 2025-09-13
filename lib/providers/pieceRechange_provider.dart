// lib/providers/pieceRechange_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/pieceRechange.dart';
import 'package:garagelink/services/piece_api.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://192.168.1.105:5000/api',
);

class PieceRechangeNotifier extends AsyncNotifier<List<PieceRechange>> {
  late final PieceApi _api;

  @override
  Future<List<PieceRechange>> build() async {
    _api = PieceApi(baseUrl: _apiBaseUrl);
    return await _fetchPieces();
  }

  /// 🔄 Récupération des pièces
  Future<List<PieceRechange>> _fetchPieces() async {
    final res = await _api.getAllPieces();

    // backend renvoie { success: true, data: [...] }
    if (res['success'] == true && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map((e) => e is PieceRechange
              ? e
              : PieceRechange.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // fallback si le backend renvoie directement une liste
    if (res is List) {
      return (res as List)
          .map((e) => PieceRechange.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    throw Exception("Erreur récupération pièces");
  }

  /// 🔄 Forcer le refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _fetchPieces());
  }

  /// ➕ Ajouter une pièce
  Future<PieceRechange?> createPiece(PieceRechange piece) async {
    try {
      final res = await _api.createPiece(piece);
      if (res['success'] == true) {
        final raw = res['data'];
        final newPiece = raw is PieceRechange
            ? raw
            : PieceRechange.fromJson(Map<String, dynamic>.from(raw as Map));

        final current = state.value ?? [];
        state = AsyncValue.data([...current, newPiece]);
        return newPiece;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// ✏️ Modifier une pièce
  Future<PieceRechange?> updatePieceById(
      String id, Map<String, dynamic> update) async {
    try {
      final res = await _api.updatePiece(id, update);
      if (res['success'] == true) {
        final raw = res['data'];
        final updated = raw is PieceRechange
            ? raw
            : PieceRechange.fromJson(Map<String, dynamic>.from(raw as Map));

        final current = state.value ?? [];
        state = AsyncValue.data(
          current.map((p) => p.id == updated.id ? updated : p).toList(),
        );
        return updated;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 🗑️ Supprimer une pièce
  Future<bool> deletePieceById(String id) async {
    try {
      final res = await _api.deletePiece(id);
      if (res['success'] == true) {
        final current = state.value ?? [];
        state = AsyncValue.data(current.where((p) => p.id != id).toList());
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Export du provider
final pieceRechangeProvider =
    AsyncNotifierProvider<PieceRechangeNotifier, List<PieceRechange>>(
  () => PieceRechangeNotifier(),
);
