import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:garagelink/models/ficheClient.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/ficheClient_api.dart';

final authTokenFromAuthProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.token;
});

// État des fiches clients
class FicheClientsState {
  final List<FicheClient> clients;
  final bool loading;
  final String? error;

  const FicheClientsState({
    this.clients = const [],
    this.loading = false,
    this.error,
  });

  FicheClientsState copyWith({
    List<FicheClient>? clients,
    bool? loading,
    String? error,
  }) =>
      FicheClientsState(
        clients: clients ?? this.clients,
        loading: loading ?? this.loading,
        error: error,
      );
}

class FicheClientsNotifier extends StateNotifier<FicheClientsState> {
  FicheClientsNotifier(this.ref) : super(const FicheClientsState());

  final Ref ref;

  // Récupérer le token depuis le provider
  String? get _token => ref.read(authTokenFromAuthProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setClients(List<FicheClient> list) => state = state.copyWith(clients: [...list], error: null);

  void clear() => state = const FicheClientsState();

  // Réseau : charger toutes les fiches clients
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final clients = await FicheClientApi.getFicheClients(_token!);
      setClients(clients);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer une fiche client par ID
  Future<FicheClient?> getById(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final client = await FicheClientApi.getFicheClientById(_token!, id);
      return client;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer les noms et types des clients
  Future<void> loadNoms() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final clientSummaries = await FicheClientApi.getFicheClientNoms(_token!);
      final clients = clientSummaries.map((summary) => FicheClient(
            id: summary.id,
            nom: summary.nom,
            type: summary.type,
            adresse: '',
            telephone: '',
            email: '',
          )).toList();
      setClients(clients);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : ajouter une fiche client
  Future<void> addFicheClient({
    required String nom,
    required ClientType type,
    required String adresse,
    required String telephone,
    required String email,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final client = await FicheClientApi.createFicheClient(
        token: _token!,
        nom: nom,
        type: type,
        adresse: adresse,
        telephone: telephone,
        email: email,
      );
      state = state.copyWith(clients: [...state.clients, client], error: null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour une fiche client
  Future<void> updateFicheClient({
    required String id,
    String? nom,
    ClientType? type,
    String? adresse,
    String? telephone,
    String? email,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedClient = await FicheClientApi.updateFicheClient(
        token: _token!,
        id: id,
        nom: nom,
        type: type,
        adresse: adresse,
        telephone: telephone,
        email: email,
      );
      state = state.copyWith(
        clients: state.clients.map((c) => c.id == id ? updatedClient : c).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer une fiche client
  Future<void> removeFicheClient(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await FicheClientApi.deleteFicheClient(_token!, id);
      state = state.copyWith(
        clients: state.clients.where((c) => c.id != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer l'historique des visites d'un client
  Future<HistoriqueVisiteResponse?> getHistoriqueVisite(String clientId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final history = await FicheClientApi.getHistoriqueVisiteByIdClient(_token!, clientId);
      return history;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer le résumé des visites d'un client
  Future<HistoryVisiteResponse?> getHistoryVisite(String clientId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final summary = await FicheClientApi.getHistoryVisite(_token!, clientId);
      return summary;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}

final ficheClientsProvider = StateNotifierProvider<FicheClientsNotifier, FicheClientsState>(
  (ref) => FicheClientsNotifier(ref),
);

final ficheClientByIdProvider = Provider.family<FicheClient?, String>((ref, id) {
  final clients = ref.watch(ficheClientsProvider).clients;
  return clients.firstWhereOrNull((c) => c.id == id);
});