import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/pieces.dart';
import 'package:garagelink/services/pieces_api.dart';

// Provider pour le token d'authentification (partagé avec autres providers)
final authTokenProvider = StateProvider<String?>((ref) => null);

// État des pièces
class PiecesState {
  final List<Piece> pieces;
  final bool loading;
  final String? error;

  const PiecesState({
    this.pieces = const [],
    this.loading = false,
    this.error,
  });

  PiecesState copyWith({
    List<Piece>? pieces,
    bool? loading,
    String? error,
  }) =>
      PiecesState(
        pieces: pieces ?? this.pieces,
        loading: loading ?? this.loading,
        error: error,
      );
}

class PiecesNotifier extends StateNotifier<PiecesState> {
  PiecesNotifier(this.ref) : super(const PiecesState());

  final Ref ref;

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setPieces(List<Piece> list) => state = state.copyWith(pieces: [...list], error: null);

  void clear() => state = const PiecesState();

  // Réseau : charger toutes les pièces
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final pieces = await PieceApi.getAllPieces(_token!);
      setPieces(pieces);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : créer une pièce
  Future<void> createPiece({
    required String name,
    required double prix,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final piece = await PieceApi.createPiece(
        token: _token!,
        name: name,
        prix: prix,
      );
      state = state.copyWith(pieces: [...state.pieces, piece], error: null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour une pièce
  Future<void> updatePiece({
    required String id,
    String? name,
    double? prix,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedPiece = await PieceApi.updatePiece(
        token: _token!,
        id: id,
        name: name,
        prix: prix,
      );
      state = state.copyWith(
        pieces: state.pieces.map((p) => p.id == id ? updatedPiece : p).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer une pièce
  Future<void> deletePiece(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await PieceApi.deletePiece(_token!, id);
      state = state.copyWith(
        pieces: state.pieces.where((p) => p.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Récupérer une pièce par ID (cache local)
  Piece? getById(String id) {
    try {
      return state.pieces.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

final piecesProvider = StateNotifierProvider<PiecesNotifier, PiecesState>((ref) {
  return PiecesNotifier(ref);
});