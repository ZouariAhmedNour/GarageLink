import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/mecanicien_api.dart';
import 'package:get/get.dart';




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
  MecaniciensNotifier(this.ref) : super(const MecaniciensState()) {
    // Écoute du token : si token devient null => clear state (déconnexion)
    ref.listen<String?>(authTokenProvider, (previous, next) {
      if (next == null) {
        clear();
      }
    });
  }

  final Ref ref;

  // Récupérer la valeur du token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // Helpers d'état
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setMecaniciens(List<Mecanicien> list) =>
      state = state.copyWith(mecaniciens: [...list], error: null);

  void clear() => state = const MecaniciensState();

  // Charger tous les mécaniciens
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final mecaniciens = await MecanicienApi.getAllMecaniciens(_token);
      setMecaniciens(mecaniciens);
    } catch (e) {
      setError(_formatError(e));
    } finally {
      setLoading(false);
    }
  }

  // Récupérer un mécanicien par ID et le mettre en cache/merge
  Future<Mecanicien?> getById(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final mecanicien = await MecanicienApi.getMecanicienById(_token, id);

      // merge / update cache
      final List<Mecanicien> updated = [
        ...state.mecaniciens.where((m) => m.id != mecanicien.id),
        mecanicien
      ];
      state = state.copyWith(mecaniciens: updated, error: null);

      return mecanicien;
    } catch (e) {
      setError(_formatError(e));
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Récupérer les mécaniciens par service (remplace la liste courante)
  Future<void> getByService(String serviceId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final mecaniciens = await MecanicienApi.getMecaniciensByService(_token, serviceId);
      setMecaniciens(mecaniciens);
    } catch (e) {
      setError(_formatError(e));
    } finally {
      setLoading(false);
    }
  }

  // Ajouter un mécanicien (ajoute en fin de liste)
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
      print('MecaniciensNotifier.addMecanicien -> token=$_token');
      final mecanicien = await MecanicienApi.createMecanicien(
        token: _token,
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
      setError(_formatError(e));
    } finally {
      setLoading(false);
    }
  }

  // Mettre à jour un mécanicien (remplace dans la liste si présent)
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
        token: _token,
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

      final updatedList = state.mecaniciens.map((m) => m.id == id ? updatedMecanicien : m).toList();
      state = state.copyWith(mecaniciens: updatedList, error: null);
    } catch (e) {
      setError(_formatError(e));
    } finally {
      setLoading(false);
    }
  }

  // Supprimer un mécanicien (optimiste => on supprime localement après succès)
  Future<void> removeMecanicien(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await MecanicienApi.deleteMecanicien(_token, id);
      state = state.copyWith(
        mecaniciens: state.mecaniciens.where((m) => m.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(_formatError(e));
    } finally {
      setLoading(false);
    }
  }

  // Helper interne pour extraire message d'erreur lisible
  String _formatError(Object e) {
    final s = e.toString();
    // nettoie certains formats courants (par ex. Exception: msg)
    return s.replaceFirst('Exception: ', '');
  }
}

final mecaniciensProvider = StateNotifierProvider<MecaniciensNotifier, MecaniciensState>((ref) {
  return MecaniciensNotifier(ref);
});

final mecanicienByIdProvider = Provider.family<Mecanicien?, String>((ref, id) {
  final mecaniciens = ref.watch(mecaniciensProvider).mecaniciens;
  return mecaniciens.firstWhereOrNull((m) => m.id == id);
});
