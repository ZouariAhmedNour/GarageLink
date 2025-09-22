// lib/providers/atelier_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/atelier.dart';
import 'package:garagelink/services/atelier_api.dart';

/// NOTE:
/// Si tu as déjà défini `authTokenProvider` ailleurs (ex: dans un fichier central),
/// supprime la déclaration ci-dessous pour éviter les doublons.
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
  AteliersNotifier(this.ref) : super(const AteliersState()) {
    // Écoute le token : si on se déconnecte (token -> null), on clear le state
    ref.listen<String?>(authTokenProvider, (previous, next) {
      if (next == null) {
        clear();
      }
    });
  }

  final Ref ref;

  String? get _token => ref.read(authTokenProvider);
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  void _setLoading(bool v) => state = state.copyWith(loading: v, error: null);
  void _setError(String message) => state = state.copyWith(error: message, loading: false);
  void _setAteliers(List<Atelier> list) => state = state.copyWith(ateliers: [...list], error: null);

  void clear() => state = const AteliersState();

  String _formatError(Object e) {
    final s = e.toString();
    return s.replaceFirst('Exception: ', '');
  }

  /// Charger tous les ateliers (requireAuth=false par défaut)
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
      _setError(_formatError(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Récupérer un atelier par id (retourne l'objet et ne modifie la liste que si on en a besoin)
  Future<Atelier?> getById(String id, {bool requireAuth = false}) async {
    if (requireAuth && !_hasToken) {
      _setError('Token d\'authentification requis');
      return null;
    }

    _setLoading(true);
    try {
      final atelier = await AtelierApi.getAtelierById(id, token: _token);

      // merge dans le cache local (remplace si existait)
      final updated = [
        ...state.ateliers.where((a) => a.id != atelier.id),
        atelier,
      ];
      state = state.copyWith(ateliers: updated, error: null);

      return atelier;
    } catch (e) {
      _setError(_formatError(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Créer un atelier (ajoute dans la liste locale si succès)
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
      _setError(_formatError(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Mettre à jour un atelier (met à jour la liste locale si présent)
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
      _setError(_formatError(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprimer un atelier (retire de la liste locale si succès)
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
      _setError(_formatError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

/// Provider principal
final ateliersProvider = StateNotifierProvider<AteliersNotifier, AteliersState>((ref) {
  return AteliersNotifier(ref);
});

/// Provider utilitaire pour obtenir un atelier depuis le cache par id (ou null)
final atelierByIdProvider = Provider.family<Atelier?, String>((ref, id) {
  final ateliers = ref.watch(ateliersProvider).ateliers;
  final idx = ateliers.indexWhere((a) => a.id == id);
  return idx == -1 ? null : ateliers[idx];
});
