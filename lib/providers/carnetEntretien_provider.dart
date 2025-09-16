import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/services/carnetEntretien_api.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

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

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  /// Charger l'historique et les informations du véhicule
  Future<void> loadForVehicule(String vehiculeId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final data = await CarnetEntretienApi.getCarnetByVehiculeId(_token!, vehiculeId);
      final vehicule = data['vehicule'] as Vehicule;
      final historique = data['historique'] as List<CarnetEntretien>;

      state = state.copyWith(
        vehicules: {...state.vehicules, vehiculeId: vehicule},
        historique: {...state.historique, vehiculeId: historique},
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Charger les statistiques pour un véhicule
  Future<void> loadStats(String vehiculeId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final stats = await CarnetEntretienApi.getStatistiques(_token!, vehiculeId);
      state = state.copyWith(
        stats: {...state.stats, vehiculeId: CarnetStats.fromJson(stats)},
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Ajouter une entrée manuelle
  Future<void> ajouterEntree({
    required String vehiculeId,
    required DateTime date,
    required List<ServiceEntretien> taches,
    required double cout,
    String? notes,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

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
      final currentHistorique = state.historique[vehiculeId] ?? [];
      state = state.copyWith(
        historique: {...state.historique, vehiculeId: [carnet, ...currentHistorique]},
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Créer une entrée à partir d'un devis
  Future<void> creerDepuisDevis(String vehiculeId, String devisId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final carnet = await CarnetEntretienApi.creerDepuisDevis(_token!, devisId);
      final currentHistorique = state.historique[vehiculeId] ?? [];
      state = state.copyWith(
        historique: {...state.historique, vehiculeId: [carnet, ...currentHistorique]},
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Marquer une entrée comme terminée
  Future<void> marquerTermine({
    required String vehiculeId,
    required String carnetId,
    DateTime? dateFinCompletion,
    int? kilometrageEntretien,
    String? notes,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedCarnet = await CarnetEntretienApi.marquerTermine(
        token: _token!,
        carnetId: carnetId,
        dateFinCompletion: dateFinCompletion,
        kilometrageEntretien: kilometrageEntretien,
        notes: notes,
      );
      final currentHistorique = state.historique[vehiculeId] ?? [];
      state = state.copyWith(
        historique: {
          ...state.historique,
          vehiculeId: currentHistorique
              .map((e) => e.id == carnetId ? updatedCarnet : e)
              .toList(),
        },
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Supprimer une entrée
  Future<void> supprimerEntree(String vehiculeId, String carnetId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      // Assuming a delete endpoint exists (not provided in controller, but added for completeness)
      final url = Uri.parse('http://localhost:3000/api/carnet/$carnetId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final currentHistorique = state.historique[vehiculeId] ?? [];
        state = state.copyWith(
          historique: {
            ...state.historique,
            vehiculeId: currentHistorique.where((e) => e.id != carnetId).toList(),
          },
          error: null,
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Erreur lors de la suppression du carnet';
        throw Exception(error);
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Effacer les données pour un véhicule
  void clearForVehicule(String vehiculeId) {
    state = state.copyWith(
      vehicules: {...state.vehicules}..remove(vehiculeId),
      historique: {...state.historique}..remove(vehiculeId),
      stats: {...state.stats}..remove(vehiculeId),
      error: null,
    );
  }

  /// Obtenir les entrées pour un véhicule
  List<CarnetEntretien> entriesFor(String vehiculeId) {
    return state.historique[vehiculeId] ?? [];
  }

  /// Obtenir les statistiques pour un véhicule
  CarnetStats? statsFor(String vehiculeId) {
    return state.stats[vehiculeId];
  }
}

final carnetProvider = StateNotifierProvider<CarnetEntretienNotifier, CarnetEntretienState>(
  (ref) => CarnetEntretienNotifier(ref),
);

// Provider filtré pour l'historique
final carnetFiltresProvider = Provider.family<List<CarnetEntretien>, String>((ref, vehiculeId) {
  final state = ref.watch(carnetProvider);
  final historique = state.historique[vehiculeId] ?? [];
  // Add filtering logic here if needed (e.g., by status or date)
  return historique;
});