// lib/providers/factures_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/facture_api.dart';

// Assure-toi d'avoir un provider authTokenProvider quelque part dans ton projet
// import 'package:garagelink/providers/auth_provider.dart';

enum SearchField { client, paymentStatus, periode }

class FactureFilterState {
  final DateTime? start;
  final DateTime? end;
  final String clientId;
  final String paymentStatus;
  final String query;
  final List<Facture> factures;
  final SearchField searchField;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool loading;
  final String? error;

  FactureFilterState({
    this.start,
    this.end,
    this.clientId = '',
    this.paymentStatus = '',
    this.query = '',
    this.factures = const [],
    this.searchField = SearchField.client,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.itemsPerPage = 10,
    this.loading = false,
    this.error,
  });

  FactureFilterState copyWith({
    DateTime? start,
    DateTime? end,
    String? clientId,
    String? paymentStatus,
    String? query,
    List<Facture>? factures,
    SearchField? searchField,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? itemsPerPage,
    bool? loading,
    String? error,
  }) {
    return FactureFilterState(
      start: start ?? this.start,
      end: end ?? this.end,
      clientId: clientId ?? this.clientId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      query: query ?? this.query,
      factures: factures ?? this.factures,
      searchField: searchField ?? this.searchField,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class FactureNotifier extends StateNotifier<FactureFilterState> {
  FactureNotifier(this.ref) : super(FactureFilterState());

  final Ref ref;

  // Récupérer le token depuis le provider (doit exister)
  String? get _token => ref.read(authTokenProvider);

  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État helpers
  void setLoading(bool value) => state = state.copyWith(loading: value, error: value ? null : state.error);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setFactures(
    List<Facture> factures, {
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required int itemsPerPage,
  }) {
    state = state.copyWith(
      factures: factures,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: itemsPerPage,
      loading: false,
      error: null,
    );
  }

  void clear() => state = FactureFilterState();

  // Filtres
  void setDateRange(DateTime? start, DateTime? end) => state = state.copyWith(start: start, end: end);

  void setClientFilter(String clientId) => state = state.copyWith(clientId: clientId);

  void setPaymentStatusFilter(String paymentStatus) => state = state.copyWith(paymentStatus: paymentStatus);

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSearchField(SearchField field) => state = state.copyWith(searchField: field);

  void setPage(int page) => state = state.copyWith(currentPage: page);

  // Réseau : charger toutes les factures (paginées)
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final pagination = await FactureApi.getAllFactures(
        token: _token!,
        clientId: state.clientId.isNotEmpty ? state.clientId : null,
        paymentStatus: state.paymentStatus.isNotEmpty ? state.paymentStatus : null,
        dateFrom: state.start?.toIso8601String(),
        dateTo: state.end?.toIso8601String(),
        page: state.currentPage,
        limit: state.itemsPerPage,
        sortBy: 'invoiceDate',
        sortOrder: 'desc',
      );

      setFactures(
        pagination.factures,
        currentPage: pagination.pagination.currentPage,
        totalPages: pagination.pagination.totalPages,
        totalItems: pagination.pagination.totalItems,
        itemsPerPage: pagination.pagination.itemsPerPage,
      );
        } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer une facture par ID
  Future<Facture?> getById(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final facture = await FactureApi.getFactureById(_token!, id);
      return facture;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer une facture par devisId
  Future<Facture?> getByDevis(String devisId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final facture = await FactureApi.getFactureByDevis(_token!, devisId);
      return facture;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : ajouter une facture (à partir d'un devis)
  Future<void> ajouterFacture({required String devisId}) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final facture = await FactureApi.createFacture(token: _token!, devisId: devisId);

      // Remplace si existe (même numeroFacture ou même id), sinon ajoute en tête
      final existingIdx = state.factures.indexWhere((f) =>
          (f.id != null && f.id == facture.id) ||
          f.numeroFacture == facture.numeroFacture);

      List<Facture> copy = [...state.factures];
      if (existingIdx != -1) {
        copy[existingIdx] = facture;
      } else {
        copy = [facture, ...copy];
      }

      state = state.copyWith(
        factures: copy,
        totalItems: state.totalItems + (existingIdx == -1 ? 1 : 0),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour une facture (notes / dueDate)
  Future<void> updateFacture({
    required String id,
    String? notes,
    DateTime? dueDate,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedFacture = await FactureApi.updateFacture(
        token: _token!,
        id: id,
        notes: notes,
        dueDate: dueDate,
      );
      state = state.copyWith(
        factures: state.factures.map((f) => f.id == id ? updatedFacture : f).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : marquer une facture comme payée (ou paiement partiel)
  Future<void> marquerFacturePayed({
    required String id,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    DateTime? paymentDate,
  }) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedFacture = await FactureApi.marquerFacturePayed(
        token: _token!,
        id: id,
        paymentAmount: paymentAmount,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate,
      );
      state = state.copyWith(
        factures: state.factures.map((f) => f.id == id ? updatedFacture : f).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer une facture
  Future<void> supprimerFacture(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await FactureApi.deleteFacture(_token!, id);
      final newList = state.factures.where((f) => f.id != id).toList();
      final newTotal = (state.totalItems - 1).clamp(0, 1 << 31); // safety clamp
      state = state.copyWith(
        factures: newList,
        totalItems: newTotal,
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer les statistiques des factures
  Future<FactureStats?> getFactureStats() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final stats = await FactureApi.getFactureStats(_token!);
      return stats;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Calcul du montant total des factures chargées
  double totalMontant() {
    return state.factures.fold(0.0, (sum, f) => sum + f.totalTTC);
  }
}

final facturesProvider = StateNotifierProvider<FactureNotifier, FactureFilterState>(
  (ref) => FactureNotifier(ref),
);

// Provider sécurisé (safe firstWhere)
final factureByIdProvider = Provider.family<Facture?, String>((ref, id) {
  final factures = ref.watch(facturesProvider).factures;
  try {
    return factures.firstWhere((f) => f.id == id);
  } catch (_) {
    // si non trouvé, retourne null
    return null;
  }
});
