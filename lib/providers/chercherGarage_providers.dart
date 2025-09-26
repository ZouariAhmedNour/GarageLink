import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/user.dart';
import 'package:garagelink/models/governorate.dart';
import 'package:garagelink/models/cite.dart';
import 'package:garagelink/services/gouvernorat_api.dart';
import 'package:garagelink/services/cite_api.dart';
import 'package:garagelink/services/chercher_garage_api.dart';

/// Fournisseurs pour gouvernorats / villes
final governoratesProvider = FutureProvider.autoDispose<List<Governorate>>((ref) {
  return GovernorateApi.getAllGovernoratesPublic();
});

final citiesProvider = FutureProvider.family.autoDispose<List<City>, String?>((ref, governorateId) {
  if (governorateId == null || governorateId.isEmpty) {
    return Future.value(<City>[]);
  }
  return CityApi.getCitiesByGovernoratePublic(governorateId);
});

/// Notifier principal qui s'appuie sur ChercherGarageApi (endpoint /search)
class GaragesNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final Ref _ref;
  GaragesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadAll();
  }

  List<User> _allGarages = [];

  /// Charge tous les garages (appel /search sans filtres)
  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    debugPrint('[GaragesNotifier] loadAll() - appel /search (sans params)');
    try {
      final garages = await ChercherGarageApi.searchGarages();
      _allGarages = garages;
      debugPrint('[GaragesNotifier] loadAll success: ${_allGarages.length}');
      state = AsyncValue.data(_allGarages);
    } catch (e, st) {
      debugPrint('[GaragesNotifier] loadAll failed: $e\n$st');
      _allGarages = [];
      state = AsyncValue.data(_allGarages);
    }
  }

  /// Recherche côté serveur avec paramètres
  Future<void> searchWithParams({
    String? governorateId,
    String? cityId,
    double? centerLat,
    double? centerLng,
    double? radiusKm, // en km
    String? searchText,
  }) async {
    state = const AsyncValue.loading();
    debugPrint('[GaragesNotifier] searchWithParams -> gov:$governorateId city:$cityId center:($centerLat,$centerLng) radiusKm:$radiusKm search:$searchText');

    try {
      final double? passRadiusKm = (centerLat != null && centerLng != null) ? (radiusKm ?? 10) : null;

      final garages = await ChercherGarageApi.searchGarages(
        governorate: governorateId,
        city: cityId,
        latitude: centerLat,
        longitude: centerLng,
        radiusKm: passRadiusKm ?? 10,
        search: searchText,
      );

      _allGarages = garages;
      debugPrint('[GaragesNotifier] searchWithParams success: ${_allGarages.length}');
      state = AsyncValue.data(_allGarages);
    } catch (e, st) {
      debugPrint('[GaragesNotifier] searchWithParams failed: $e\n$st');
      try {
        await loadAll();
      } catch (e2, st2) {
        debugPrint('[GaragesNotifier] fallback loadAll also failed: $e2\n$st2');
        _allGarages = [];
        state = AsyncValue.data(_allGarages);
      }
    }
  }

  /// Méthode utilisée par l'UI ; délègue au serveur
  void applyFilters({
    String? governorateId,
    String? cityId,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    String? searchText,
  }) {
    debugPrint('[applyFilters] delegating to server search (gov=$governorateId, city=$cityId, center=($centerLat,$centerLng), radius=$radiusKm, search=$searchText)');

    searchWithParams(
      governorateId: governorateId,
      cityId: cityId,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
      searchText: searchText,
    ).catchError((err) => debugPrint('[applyFilters] searchWithParams error: $err'));
  }

  /// Remet l'état à la liste complète (recharge depuis serveur)
  void resetFilters() => loadAll();
}

/// Fournisseur Riverpod pour accéder au notifier
final garagesProvider = StateNotifierProvider<GaragesNotifier, AsyncValue<List<User>>>(
  (ref) => GaragesNotifier(ref),
);
