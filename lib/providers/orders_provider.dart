import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/services/ordre_api.dart';

// Provider pour le token d'authentification (partagé avec autres providers)
final authTokenProvider = StateProvider<String?>((ref) => null);

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

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setOrdres(List<OrdreTravail> list) => state = state.copyWith(ordres: [...list], error: null);

  void clear() => state = const OrdresState();

  // Réseau : charger tous les ordres
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
      setOrdres(result['ordres'] as List<OrdreTravail>);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer un ordre par ID
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

  // Réseau : récupérer un ordre par devisId
  Future<OrdreTravail?> getByDevisId(String devisId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final result = await OrdreApi.getOrdreByDevisId(_token!, devisId);
      if (result['exists'] == true) {
        return result['ordre'] as OrdreTravail;
      }
      return null;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer les ordres par statut
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
      setOrdres(result['ordres'] as List<OrdreTravail>);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer les ordres par atelier
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
      setOrdres(result['ordres'] as List<OrdreTravail>);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer les statistiques
  Future<Map<String, dynamic>?> getStatistiques({String? atelierId}) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final stats = await OrdreApi.getStatistiques(
        token: _token!,
        atelierId: atelierId,
      );
      return stats;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : créer un ordre
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
      state = state.copyWith(ordres: [...state.ordres, ordre], error: null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour le statut d'un ordre
  Future<void> updateStatus(String id, String status) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.updateStatusOrdre(
        token: _token!,
        id: id,
        status: status,
      );
      state = state.copyWith(
        ordres: state.ordres.map((o) => o.id == id ? updatedOrdre : o).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : démarrer un ordre
  Future<void> demarrerOrdre(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.demarrerOrdre(_token!, id);
      state = state.copyWith(
        ordres: state.ordres.map((o) => o.id == id ? updatedOrdre : o).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : terminer un ordre
  Future<void> terminerOrdre(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedOrdre = await OrdreApi.terminerOrdre(_token!, id);
      state = state.copyWith(
        ordres: state.ordres.map((o) => o.id == id ? updatedOrdre : o).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer un ordre
  Future<void> supprimerOrdre(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await OrdreApi.supprimerOrdre(_token!, id);
      state = state.copyWith(
        ordres: state.ordres.where((o) => o.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour un ordre
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
        ordres: state.ordres.map((o) => o.id == id ? updatedOrdre : o).toList(),
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