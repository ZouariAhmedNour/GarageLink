// lib/providers/atelier_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/atelier.dart';
import 'package:garagelink/services/atelier_api.dart';

/// ATTENTION:
/// Ce provider lit un provider `authTokenProvider` pour récupérer le token.
/// Si tu as défini authTokenProvider dans un autre fichier (ex: ordres_provider.dart),
/// garde le même nom ici. Sinon déclare-le globalement ailleurs.
final authTokenProvider = StateProvider<String?>((ref) => null);

/// État pour la gestion des ateliers
class AteliersState {
  final List<Atelier> ateliers;
  final bool loading;
  final String? error;

  const AteliersState({
    this.ateliers = const [],
    this.loading = false,
    this.error,
  });

  AteliersState copyWith({
    List<Atelier>? ateliers,
    bool? loading,
    String? error,
  }) {
    return AteliersState(
      ateliers: ateliers ?? this.ateliers,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Notifier qui gère les appels réseau et l'état
class AteliersNotifier extends StateNotifier<AteliersState> {
  AteliersNotifier(this.ref) : super(const AteliersState());

  final Ref ref;

  String? get _token => ref.read(authTokenProvider);

  bool get _hasToken => _token != null && _token!.isNotEmpty;

  void _setLoading(bool v) => state = state.copyWith(loading: v, error: null);
  void _setError(String message) => state = state.copyWith(error: message, loading: false);
  void _setAteliers(List<Atelier> list) => state = state.copyWith(ateliers: [...list], error: null);

  void clear() => state = const AteliersState();

  /// Charger tous les ateliers
  Future<void> loadAll({bool requireAuth = false}) async {
    if (requireAuth && !_hasToken) {
      _setError('Token d\'authentification requis');
      return;
    }

    _setLoading(true);
    try {
      final ateliers = await AtelierApi.getAllAteliers(token: _token);
      _setAteliers(ateliers);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Récupérer un atelier par id
  Future<Atelier?> getById(String id, {bool requireAuth = false}) async {
    if (requireAuth && !_hasToken) {
      _setError('Token d\'authentification requis');
      return null;
    }

    _setLoading(true);
    try {
      final atelier = await AtelierApi.getAtelierById(id, token: _token);
      return atelier;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Créer un atelier
  Future<Atelier?> create({
    required String name,
    required String localisation,
    bool requireAuth = false,
  }) async {
    if (requireAuth && !_hasToken) {
      _setError('Token d\'authentification requis');
      return null;
    }

    _setLoading(true);
    try {
      final atelier = await AtelierApi.createAtelier(
        name: name,
        localisation: localisation,
        token: _token,
      );
      state = state.copyWith(ateliers: [...state.ateliers, atelier], error: null);
      return atelier;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Mettre à jour un atelier
  Future<Atelier?> update({
    required String id,
    String? name,
    String? localisation,
    bool requireAuth = false,
  }) async {
    if (requireAuth && !_hasToken) {
      _setError('Token d\'authentification requis');
      return null;
    }

    _setLoading(true);
    try {
      final atelier = await AtelierApi.updateAtelier(
        id: id,
        name: name,
        localisation: localisation,
        token: _token,
      );

      state = state.copyWith(
        ateliers: state.ateliers.map((a) => a.id == atelier.id ? atelier : a).toList(),
        error: null,
      );
      return atelier;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprimer un atelier
  Future<bool> delete(String id, {bool requireAuth = false}) async {
    if (requireAuth && !_hasToken) {
      _setError('Token d\'authentification requis');
      return false;
    }

    _setLoading(true);
    try {
      await AtelierApi.deleteAtelier(id, token: _token);
      state = state.copyWith(ateliers: state.ateliers.where((a) => a.id != id).toList(), error: null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

/// Export du provider
final ateliersProvider = StateNotifierProvider<AteliersNotifier, AteliersState>((ref) {
  return AteliersNotifier(ref);
});
