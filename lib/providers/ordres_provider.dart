import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/ordre_api.dart';

// NOTE: Ne pas redeclarer authTokenProvider ici si tu l'as déjà ailleurs.
// final authTokenProvider = StateProvider<String?>((ref) => null);

// État des ordres de travail
class OrdresState {
  final List<OrdreTravail> ordres;
  final bool loading;
  final String? error;

  const OrdresState({
    this.ordres = const [],
    this.loading = false,
    this.error,
  });

  OrdresState copyWith({
    List<OrdreTravail>? ordres,
    bool? loading,
    String? error,
  }) =>
      OrdresState(
        ordres: ordres ?? this.ordres,
        loading: loading ?? this.loading,
        error: error,
      );
}

class OrdresNotifier extends StateNotifier<OrdresState> {
  OrdresNotifier(this.ref) : super(const OrdresState());

  final Ref ref;

  // Récupérer le token depuis le provider d'auth (défini ailleurs)
  String? get _token => ref.read(authTokenProvider);

  bool get _hasToken => _token != null && _token!.isNotEmpty;

  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);
  void setError(String error) => state = state.copyWith(error: error, loading: false);
  void setOrdres(List<OrdreTravail> list) => state = state.copyWith(ordres: [...list], error: null);
  void clear() => state = const OrdresState();

  // Helper pour comparer les ids (supporte id ou _id)
  bool _matchesId(OrdreTravail o, String id) {
    final oid = o.id ?? (o.toJson()['_id']?.toString());
    return oid == id || (o.id == null && (o.toJson()['_id']?.toString() == id));
  }

  Future<void> loadAll({
    int page = 1,
    int limit = 10,
    String? status,
    String? atelierId,
    String? priorite,
    DateTime? dateDebut,
    DateTime? dateFin,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final result = await OrdreApi.getAllOrdres(
        token: _token!,
        page: page,
        limit: limit,
        status: status,
        atelierId: atelierId,
        priorite: priorite,
        dateDebut: dateDebut,
        dateFin: dateFin,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      final ordresList = (result['ordres'] as List<dynamic>?)
              ?.map((e) => e is OrdreTravail ? e : OrdreTravail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <OrdreTravail>[];

      setOrdres(ordresList);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<OrdreTravail?> getById(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final ordre = await OrdreApi.getOrdreById(_token!, id);
      return ordre;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<OrdreTravail?> getByDevisId(String devisId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final result = await OrdreApi.getOrdreByDevisId(_token!, devisId);
      if (result['exists'] == true) {
        final ord = result['ordre'];
        if (ord is OrdreTravail) return ord;
        if (ord is Map<String, dynamic>) return OrdreTravail.fromJson(ord);
      }
      return null;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getByStatus({
    required String status,
    int page = 1,
    int limit = 10,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final result = await OrdreApi.getOrdresByStatus(
        token: _token!,
        status: status,
        page: page,
        limit: limit,
      );

      final ordresList = (result['ordres'] as List<dynamic>?)
              ?.map((e) => e is OrdreTravail ? e : OrdreTravail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <OrdreTravail>[];

      setOrdres(ordresList);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> getByAtelier({
    required String atelierId,
    int page = 1,
    int limit = 10,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final result = await OrdreApi.getOrdresByAtelier(
        token: _token!,
        atelierId: atelierId,
        page: page,
        limit: limit,
      );

      final ordresList = (result['ordres'] as List<dynamic>?)
              ?.map((e) => e is OrdreTravail ? e : OrdreTravail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <OrdreTravail>[];

      setOrdres(ordresList);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getStatistiques({String? atelierId}) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final stats = await OrdreApi.getStatistiques(token: _token!, atelierId: atelierId);
      return stats;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> createOrdre({
    required String devisId,
    required DateTime dateCommence,
    required String atelierId,
    String priorite = 'normale',
    String? description,
    required List<Tache> taches,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final ordre = await OrdreApi.createOrdre(
        token: _token!,
        devisId: devisId,
        dateCommence: dateCommence,
        atelierId: atelierId,
        priorite: priorite,
        description: description,
        taches: taches,
      );

      // Optionnel : éviter doublons (check id/_id)
      final exists = state.ordres.any((o) => _matchesId(o, ordre.id ?? ordre.toJson()['_id']?.toString() ?? ''));
      if (!exists) {
        state = state.copyWith(ordres: [...state.ordres, ordre], error: null);
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.updateStatusOrdre(token: _token!, id: id, status: status);
      state = state.copyWith(
        ordres: state.ordres.map((o) {
          return _matchesId(o, id) ? updatedOrdre : o;
        }).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> demarrerOrdre(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.demarrerOrdre(_token!, id);
      state = state.copyWith(
        ordres: state.ordres.map((o) => _matchesId(o, id) ? updatedOrdre : o).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> terminerOrdre(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.terminerOrdre(_token!, id);
      state = state.copyWith(
        ordres: state.ordres.map((o) => _matchesId(o, id) ? updatedOrdre : o).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> supprimerOrdre(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await OrdreApi.supprimerOrdre(_token!, id);
      state = state.copyWith(
        ordres: state.ordres.where((o) => !_matchesId(o, id)).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateOrdre({
    required String id,
    DateTime? dateCommence,
    String? atelierId,
    String? priorite,
    String? description,
    List<Tache>? taches,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.updateOrdre(
        token: _token!,
        id: id,
        dateCommence: dateCommence,
        atelierId: atelierId,
        priorite: priorite,
        description: description,
        taches: taches,
      );
      state = state.copyWith(
        ordres: state.ordres.map((o) => _matchesId(o, id) ? updatedOrdre : o).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}

final ordresProvider = StateNotifierProvider<OrdresNotifier, OrdresState>((ref) {
  return OrdresNotifier(ref);
});
