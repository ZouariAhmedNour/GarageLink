import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/services/vehicule_api.dart';

// Provider pour le token d'authentification
final authTokenProvider = StateProvider<String?>((ref) => null);

// État des véhicules
class VehiculesState {
  final List<Vehicule> vehicules;
  final bool loading;
  final String? error;

  const VehiculesState({
    this.vehicules = const [],
    this.loading = false,
    this.error,
  });

  VehiculesState copyWith({
    List<Vehicule>? vehicules,
    bool? loading,
    String? error,
  }) =>
      VehiculesState(
        vehicules: vehicules ?? this.vehicules,
        loading: loading ?? this.loading,
        error: error,
      );
}

class VehiculesNotifier extends StateNotifier<VehiculesState> {
  VehiculesNotifier(this.ref) : super(const VehiculesState());

  final Ref ref;

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setVehicules(List<Vehicule> list) => state = state.copyWith(vehicules: [...list], error: null);

  void clear() => state = const VehiculesState();

  // Réseau : charger tous les véhicules
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final vehicules = await VehiculeApi.getAllVehicules(_token!);
      setVehicules(vehicules);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : charger les véhicules d'un propriétaire et fusionner dans le cache
  Future<List<Vehicule>> loadByProprietaire(String proprietaireId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return [];
    }

    setLoading(true);
    try {
      final vehicules = await VehiculeApi.getVehiculesByProprietaire(_token!, proprietaireId);
      final others = state.vehicules.where((v) => v.proprietaireId != proprietaireId).toList();
      setVehicules([...others, ...vehicules]);
      return vehicules;
    } catch (e) {
      setError(e.toString());
      return [];
    } finally {
      setLoading(false);
    }
  }

  // Réseau : créer un véhicule
  Future<void> createVehicule({
    required String proprietaireId,
    required String marque,
    required String modele,
    required String immatriculation,
    int? annee,
    String? couleur,
    FuelType? typeCarburant,
    int? kilometrage,
    String? picKm,            // optionnel : chemin/URL de la photo principale
    List<String>? images,     // optionnel : tableau d'images (chemins/URLs)
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final vehicule = await VehiculeApi.createVehicule(
        token: _token!,
        proprietaireId: proprietaireId,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
        annee: annee,
        couleur: couleur,
        typeCarburant: typeCarburant,
        kilometrage: kilometrage,
        picKm: picKm,
        images: images,
      );
      state = state.copyWith(vehicules: [...state.vehicules, vehicule], error: null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour un véhicule
  Future<void> updateVehicule({
    required String id,
    String? proprietaireId,
    String? marque,
    String? modele,
    String? immatriculation,
    int? annee,
    String? couleur,
    FuelType? typeCarburant,
    int? kilometrage,
    String? picKm,            // ajouté
    List<String>? images,     // ajouté
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedVehicule = await VehiculeApi.updateVehicule(
        token: _token!,
        id: id,
        proprietaireId: proprietaireId,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
        annee: annee,
        couleur: couleur,
        typeCarburant: typeCarburant,
        kilometrage: kilometrage,
        picKm: picKm,
        images: images,
      );
      state = state.copyWith(
        vehicules: state.vehicules.map((v) => v.id == id ? updatedVehicule : v).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer un véhicule (soft delete)
  Future<void> removeVehicule(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await VehiculeApi.deleteVehicule(_token!, id);
      state = state.copyWith(
        vehicules: state.vehicules.where((v) => v.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Récupérer un véhicule par ID (cache local)
  Vehicule? getById(String id) {
    try {
      return state.vehicules.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Trouver les véhicules par propriétaire (cache local)
  List<Vehicule> findByProprietaire(String proprietaireId) {
    return state.vehicules.where((v) => v.proprietaireId == proprietaireId).toList();
  }
}

final vehiculesProvider = StateNotifierProvider<VehiculesNotifier, VehiculesState>((ref) {
  return VehiculesNotifier(ref);
});
