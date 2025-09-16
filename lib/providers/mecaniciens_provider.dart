import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/services/mecanicien_api.dart';
import 'package:collection/collection.dart'; // Pour firstWhereOrNull

// Provider pour le token d'authentification (partagé avec autres providers)
final authTokenProvider = StateProvider<String?>((ref) => null);

// État des mécaniciens
class MecaniciensState {
  final List<Mecanicien> mecaniciens;
  final bool loading;
  final String? error;

  const MecaniciensState({
    this.mecaniciens = const [],
    this.loading = false,
    this.error,
  });

  MecaniciensState copyWith({
    List<Mecanicien>? mecaniciens,
    bool? loading,
    String? error,
  }) =>
      MecaniciensState(
        mecaniciens: mecaniciens ?? this.mecaniciens,
        loading: loading ?? this.loading,
        error: error,
      );
}

class MecaniciensNotifier extends StateNotifier<MecaniciensState> {
  MecaniciensNotifier(this.ref) : super(const MecaniciensState());

  final Ref ref;

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setMecaniciens(List<Mecanicien> list) => state = state.copyWith(mecaniciens: [...list], error: null);

  void clear() => state = const MecaniciensState();

  // Réseau : charger tous les mécaniciens
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final mecaniciens = await MecanicienApi.getAllMecaniciens(_token!);
      setMecaniciens(mecaniciens);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer un mécanicien par ID
  Future<Mecanicien?> getById(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final mecanicien = await MecanicienApi.getMecanicienById(_token!, id);
      return mecanicien;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer les mécaniciens par service
  Future<void> getByService(String serviceId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final mecaniciens = await MecanicienApi.getMecaniciensByService(_token!, serviceId);
      setMecaniciens(mecaniciens);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : ajouter un mécanicien
  Future<void> addMecanicien({
    required String nom,
    required DateTime dateNaissance,
    required String telephone,
    required String email,
    required Poste poste,
    required DateTime dateEmbauche,
    required TypeContrat typeContrat,
    required Statut statut,
    required double salaire,
    required List<ServiceMecanicien> services,
    required String experience,
    required PermisConduire permisConduire,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final mecanicien = await MecanicienApi.createMecanicien(
        token: _token!,
        nom: nom,
        dateNaissance: dateNaissance,
        telephone: telephone,
        email: email,
        poste: poste,
        dateEmbauche: dateEmbauche,
        typeContrat: typeContrat,
        statut: statut,
        salaire: salaire,
        services: services,
        experience: experience,
        permisConduire: permisConduire,
      );
      state = state.copyWith(mecaniciens: [...state.mecaniciens, mecanicien], error: null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour un mécanicien
  Future<void> updateMecanicien({
    required String id,
    String? nom,
    DateTime? dateNaissance,
    String? telephone,
    String? email,
    Poste? poste,
    DateTime? dateEmbauche,
    TypeContrat? typeContrat,
    Statut? statut,
    double? salaire,
    List<ServiceMecanicien>? services,
    String? experience,
    PermisConduire? permisConduire,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedMecanicien = await MecanicienApi.updateMecanicien(
        token: _token!,
        id: id,
        nom: nom,
        dateNaissance: dateNaissance,
        telephone: telephone,
        email: email,
        poste: poste,
        dateEmbauche: dateEmbauche,
        typeContrat: typeContrat,
        statut: statut,
        salaire: salaire,
        services: services,
        experience: experience,
        permisConduire: permisConduire,
      );
      state = state.copyWith(
        mecaniciens: state.mecaniciens.map((m) => m.id == id ? updatedMecanicien : m).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer un mécanicien
  Future<void> removeMecanicien(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await MecanicienApi.deleteMecanicien(_token!, id);
      state = state.copyWith(
        mecaniciens: state.mecaniciens.where((m) => m.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}

final mecaniciensProvider = StateNotifierProvider<MecaniciensNotifier, MecaniciensState>((ref) {
  return MecaniciensNotifier(ref);
});

final mecanicienByIdProvider = Provider.family<Mecanicien?, String>((ref, id) {
  final mecaniciens = ref.watch(mecaniciensProvider).mecaniciens;
  return mecaniciens.firstWhereOrNull((m) => m.id == id);
});