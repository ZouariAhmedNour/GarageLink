import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/services/carnetEntretien_api.dart';
import 'package:garagelink/providers/auth_provider.dart';

class CarnetStats {
  final int totalEntretiens;
  final double totalDepense;
  final double moyenneParEntretien;
  final DateTime? dernierEntretien;
  final DateTime? prochainEntretien;
  final Map<String, dynamic> repartitionParType;
  final List<Map<String, dynamic>> evolutionDepenses;

  CarnetStats({
    required this.totalEntretiens,
    required this.totalDepense,
    required this.moyenneParEntretien,
    this.dernierEntretien,
    this.prochainEntretien,
    this.repartitionParType = const {},
    this.evolutionDepenses = const [],
  });

  factory CarnetStats.fromJson(Map<String, dynamic> json) {
    return CarnetStats(
      totalEntretiens: json['totalEntretiens'] ?? 0,
      totalDepense: (json['totalDepense'] as num?)?.toDouble() ?? 0.0,
      moyenneParEntretien: (json['moyenneParEntretien'] as num?)?.toDouble() ?? 0.0,
      dernierEntretien: json['dernierEntretien'] != null
          ? DateTime.parse(json['dernierEntretien'])
          : null,
      prochainEntretien: json['prochainEntretien'] != null
          ? DateTime.parse(json['prochainEntretien'])
          : null,
      repartitionParType: json['repartitionParType'] ?? {},
      evolutionDepenses: (json['evolutionDepenses'] as List<dynamic>?)
              ?.map((e) => {
                    'date': DateTime.parse(e['date']),
                    'montant': (e['montant'] as num?)?.toDouble() ?? 0.0,
                  })
              .toList() ??
          [],
    );
  }
}

class CarnetEntretienState {
  final Map<String, Vehicule> vehicules;
  final Map<String, List<CarnetEntretien>> historique;
  final Map<String, CarnetStats> stats;
  final bool loading;
  final String? error;

  CarnetEntretienState({
    this.vehicules = const {},
    this.historique = const {},
    this.stats = const {},
    this.loading = false,
    this.error,
  });

  CarnetEntretienState copyWith({
    Map<String, Vehicule>? vehicules,
    Map<String, List<CarnetEntretien>>? historique,
    Map<String, CarnetStats>? stats,
    bool? loading,
    String? error,
  }) {
    return CarnetEntretienState(
      vehicules: vehicules ?? this.vehicules,
      historique: historique ?? this.historique,
      stats: stats ?? this.stats,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class CarnetEntretienNotifier extends StateNotifier<CarnetEntretienState> {
  final Ref ref;

  CarnetEntretienNotifier(this.ref) : super(CarnetEntretienState());

  String? get _token => ref.read(authTokenProvider);
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);
  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void _ensureToken() {
    if (!_hasToken) {
      final msg = 'Token d\'authentification requis';
      state = state.copyWith(error: msg, loading: false);
      throw Exception(msg);
    }
  }

  Future<void> loadForVehicule(String vehiculeId) async {
    _ensureToken();

    setLoading(true);
    try {
      final data = await CarnetEntretienApi.getCarnetByVehiculeId(_token!, vehiculeId);
      final vehicule = data['vehicule'] as Vehicule;
      final historique = data['historique'] as List<CarnetEntretien>;

      final newVehicules = Map<String, Vehicule>.from(state.vehicules);
      newVehicules[vehiculeId] = vehicule;

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      newHistorique[vehiculeId] = historique;

      state = state.copyWith(
        vehicules: newVehicules,
        historique: newHistorique,
        error: null,
      );
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadStats(String vehiculeId) async {
    _ensureToken();

    setLoading(true);
    try {
      final statsJson = await CarnetEntretienApi.getStatistiques(_token!, vehiculeId);
      final newStats = Map<String, CarnetStats>.from(state.stats);
      newStats[vehiculeId] = CarnetStats.fromJson(statsJson);

      state = state.copyWith(
        stats: newStats,
        error: null,
      );
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<CarnetEntretien> ajouterEntree({
    required String vehiculeId,
    required DateTime date,
    required List<ServiceEntretien> taches,
    required double cout,
    String? notes,
  }) async {
    _ensureToken();

    setLoading(true);
    try {
      final carnet = await CarnetEntretienApi.creerCarnetManuel(
        token: _token!,
        vehiculeId: vehiculeId,
        date: date,
        taches: taches,
        cout: cout,
        notes: notes,
      );

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      newHistorique[vehiculeId] = [carnet, ...currentHistorique];

      state = state.copyWith(
        historique: newHistorique,
        error: null,
      );
      return carnet;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> creerDepuisDevis(String vehiculeId, String devisId) async {
    _ensureToken();

    setLoading(true);
    try {
      final carnet = await CarnetEntretienApi.creerDepuisDevis(_token!, devisId);
      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      newHistorique[vehiculeId] = [carnet, ...currentHistorique];

      state = state.copyWith(
        historique: newHistorique,
        error: null,
      );
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // HELPERS -----------------------------------------------------------------

  List<ServiceEntretien> _buildServicesFromDynamic(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map<ServiceEntretien>((t) {
        if (t is ServiceEntretien) return t;
        if (t is Map<String, dynamic>) {
          return ServiceEntretien(
            nom: (t['nom'] ?? t['description'] ?? '').toString(),
            description: t['description']?.toString(),
            quantite: (t['quantite'] as int?) ?? (t['quantity'] as int?) ?? 1,
            prix: (t['prix'] as num?)?.toDouble() ?? (t['price'] as num?)?.toDouble(),
          );
        }
        return ServiceEntretien(nom: t.toString(), description: null);
      }).toList();
    }
    return [];
  }

  CarnetEntretien _mergeCarnetWithUpdates(CarnetEntretien old, Map<String, dynamic> updates) {
    // prendre les valeurs existantes et écraser avec updates quand présentes
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final newServices = updates.containsKey('taches')
        ? _buildServicesFromDynamic(updates['taches'])
        : old.services;

    return CarnetEntretien(
      id: old.id,
      vehiculeId: old.vehiculeId,
      devisId: old.devisId,
      dateCommencement: parseDate(updates['dateCommencement']) ?? old.dateCommencement,
      dateFinCompletion: parseDate(updates['dateFinCompletion']) ?? old.dateFinCompletion,
      statut: updates['statut'] ?? old.statut,
      totalTTC: (updates['totalTTC'] as num?)?.toDouble() ?? old.totalTTC,
      kilometrageEntretien: updates['kilometrageEntretien'] ?? old.kilometrageEntretien,
      notes: updates['notes'] ?? old.notes,
      services: newServices,
      pieces: old.pieces,
      technicien: updates['technicien'] ?? old.technicien,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // FIN HELPERS -------------------------------------------------------------

  Future<void> marquerTermine({
    required String vehiculeId,
    required String carnetId,
    DateTime? dateFinCompletion,
    int? kilometrageEntretien,
    String? notes,
  }) async {
    _ensureToken();

    setLoading(true);
    try {
      final updatedCarnet = await CarnetEntretienApi.marquerTermine(
        token: _token!,
        carnetId: carnetId,
        dateFinCompletion: dateFinCompletion,
        kilometrageEntretien: kilometrageEntretien,
        notes: notes,
      );

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      newHistorique[vehiculeId] = currentHistorique
          .map((e) => e.id == carnetId ? updatedCarnet : e)
          .toList();

      state = state.copyWith(
        historique: newHistorique,
        error: null,
      );
      return;
    } catch (e) {
      // fallback local (API absent or erreur réseau)
      print('⚠️ marquerTermine API failed, applying local fallback: $e');

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      final idx = currentHistorique.indexWhere((c) => c.id == carnetId);
      if (idx != -1) {
        final old = currentHistorique[idx];
        final updates = <String, dynamic>{
          'dateFinCompletion': dateFinCompletion?.toIso8601String(),
          'kilometrageEntretien': kilometrageEntretien,
          'notes': notes,
          'statut': 'termine',
        }..removeWhere((k, v) => v == null);
        final merged = _mergeCarnetWithUpdates(old, updates);
        final newList = [...currentHistorique];
        newList[idx] = merged;
        newHistorique[vehiculeId] = newList;
        state = state.copyWith(historique: newHistorique, error: null);
        print('✅ marquerTermine fallback applied locally');
        return;
      }

      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> supprimerEntree(String vehiculeId, String carnetId) async {
    _ensureToken();

    setLoading(true);
    try {
      await CarnetEntretienApi.deleteCarnet(_token!, carnetId);

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      newHistorique[vehiculeId] = currentHistorique.where((e) => e.id != carnetId).toList();

      state = state.copyWith(
        historique: newHistorique,
        error: null,
      );
      return;
    } catch (e) {
      // fallback local deletion
      print('⚠️ deleteCarnet API failed, deleting locally: $e');
      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      final newList = currentHistorique.where((e) => e.id != carnetId).toList();
      newHistorique[vehiculeId] = newList;
      state = state.copyWith(historique: newHistorique, error: null);
      print('✅ suppression fallback appliquée localement');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateEntry({
    required String vehiculeId,
    required String carnetId,
    required Map<String, dynamic> updates,
  }) async {
    _ensureToken();

    setLoading(true);
    try {
      final updated = await CarnetEntretienApi.updateCarnet(
        token: _token!,
        carnetId: carnetId,
        updates: updates,
      );

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      newHistorique[vehiculeId] = currentHistorique.map((e) => e.id == carnetId ? updated : e).toList();

      state = state.copyWith(
        historique: newHistorique,
        error: null,
      );
      return;
    } catch (e) {
      // fallback local update (server route absent / 404)
      print('⚠️ updateCarnet API failed, applying local fallback: $e');

      final newHistorique = Map<String, List<CarnetEntretien>>.from(state.historique);
      final currentHistorique = newHistorique[vehiculeId] ?? [];
      final idx = currentHistorique.indexWhere((c) => c.id == carnetId);

      if (idx != -1) {
        final old = currentHistorique[idx];
        // create merged object
        final merged = _mergeCarnetWithUpdates(old, updates);
        final newList = [...currentHistorique];
        newList[idx] = merged;
        newHistorique[vehiculeId] = newList;
        state = state.copyWith(historique: newHistorique, error: null);
        print('✅ updateEntry fallback appliquée localement');
        return;
      }

      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  List<CarnetEntretien> entriesFor(String vehiculeId) {
    return state.historique[vehiculeId] ?? [];
  }

  CarnetStats? statsFor(String vehiculeId) {
    return state.stats[vehiculeId];
  }
}

final carnetProvider = StateNotifierProvider<CarnetEntretienNotifier, CarnetEntretienState>(
  (ref) => CarnetEntretienNotifier(ref),
);

final carnetFiltresProvider = Provider.family<List<CarnetEntretien>, String>((ref, vehiculeId) {
  final state = ref.watch(carnetProvider);
  final historique = state.historique[vehiculeId] ?? [];
  return historique;
});
