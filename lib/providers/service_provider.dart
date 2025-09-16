import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/services/service_api.dart';

// Provider pour le token d'authentification (partagé avec vehicules_provider.dart)
final authTokenProvider = StateProvider<String?>((ref) => null);

// État des services
class ServicesState {
  final List<Service> services;
  final bool loading;
  final String? error;

  const ServicesState({
    this.services = const [],
    this.loading = false,
    this.error,
  });

  ServicesState copyWith({
    List<Service>? services,
    bool? loading,
    String? error,
  }) =>
      ServicesState(
        services: services ?? this.services,
        loading: loading ?? this.loading,
        error: error,
      );
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  ServicesNotifier(this.ref) : super(const ServicesState());

  final Ref ref;

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setServices(List<Service> list) => state = state.copyWith(services: [...list], error: null);

  void clear() => state = const ServicesState();

  // Réseau : charger tous les services
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final services = await ServiceApi.getAllServices(_token!);
      setServices(services);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : créer un service
  Future<void> createService({
    required String name,
    required String description,
    ServiceStatut? statut,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final service = await ServiceApi.createService(
        token: _token!,
        name: name,
        description: description,
        statut: statut,
      );
      state = state.copyWith(services: [...state.services, service], error: null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour un service
  Future<void> updateService({
    required String id,
    String? name,
    String? description,
    ServiceStatut? statut,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedService = await ServiceApi.updateService(
        token: _token!,
        id: id,
        name: name,
        description: description,
        statut: statut,
      );
      state = state.copyWith(
        services: state.services.map((s) => s.id == id ? updatedService : s).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer un service
  Future<void> deleteService(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await ServiceApi.deleteService(_token!, id);
      state = state.copyWith(
        services: state.services.where((s) => s.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : basculer le statut d'un service
  Future<void> toggleStatus(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    final service = getById(id);
    if (service == null) {
      state = state.copyWith(error: 'Service non trouvé');
      return;
    }

    setLoading(true);
    try {
      final newStatut = service.statut == ServiceStatut.actif ? ServiceStatut.desactive : ServiceStatut.actif;
      final updatedService = await ServiceApi.updateService(
        token: _token!,
        id: id,
        statut: newStatut,
      );
      state = state.copyWith(
        services: state.services.map((s) => s.id == id ? updatedService : s).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Récupérer un service par ID (cache local)
  Service? getById(String id) {
    try {
      return state.services.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // Trouver les services par statut (cache local)
  List<Service> findByStatut(ServiceStatut statut) {
    return state.services.where((s) => s.statut == statut).toList();
  }
}

final serviceProvider = StateNotifierProvider<ServicesNotifier, ServicesState>((ref) {
  return ServicesNotifier(ref);
});