import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/devis_api.dart';

// Assure-toi que authTokenProvider existe ailleurs dans ton code
// import 'package:garagelink/providers/auth_provider.dart';

enum DevisFilterField { clientName, status, periode }

class DevisFilterState {
  final String clientId; // MongoDB ID du client
  final String clientName; // Nom pour affichage et filtrage
  final String? vehiculeId; // MongoDB ID du véhicule
  final String? vehicleInfo; // Texte lisible (marque, modèle, immatriculation)
  final String? numeroSerie; // Numéro de série ou immatriculation
  final String? status; // Filtre de statut (brouillon, envoye, accepte, refuse)
  final DateTime? dateDebut; // Filtre de date de début
  final DateTime? dateFin; // Filtre de date de fin
  final DateTime inspectionDate; // Date d'inspection pour le formulaire
  final List<Service> services; // Services du devis
  final double maindoeuvre; // Coût de la main-d'œuvre
  final EstimatedTime estimatedTime; // Durée estimée
  final double tvaRate; // Taux de TVA en pourcentage (ex: 20.0)
  final List<Devis> devis; // Liste des devis chargés
  final DevisFilterField filterField; // Champ de filtrage actif
  final bool loading; // État de chargement
  final String? error; // Message d'erreur

  DevisFilterState({
    this.clientId = '',
    this.clientName = '',
    this.vehiculeId,
    this.vehicleInfo,
    this.numeroSerie,
    this.status,
    this.dateDebut,
    this.dateFin,
    DateTime? inspectionDate,
    List<Service>? services,
    this.maindoeuvre = 0.0,
    EstimatedTime? estimatedTime,
    this.tvaRate = 20.0,
    List<Devis>? devis,
    this.filterField = DevisFilterField.clientName,
    this.loading = false,
    this.error,
  })  : services = services ?? [],
        estimatedTime = estimatedTime ?? EstimatedTime(),
        devis = devis ?? [],
        inspectionDate = inspectionDate ?? DateTime.now();

  // Calculs
  double get sousTotalPieces =>
      services.fold(0.0, (sum, srv) => sum + (srv.total));

  double get totalHT => sousTotalPieces + maindoeuvre;

  double get montantTva => totalHT * (tvaRate / 100);

  double get totalTTC => totalHT + montantTva;

  // Convertir en modèle Devis (devisId vide => backend générera un id)
  Devis toDevis() {
    return Devis(
      devisId: '', // temporaire — le backend renverra l'id réel
      clientId: clientId,
      clientName: clientName,
      vehicleInfo: vehicleInfo ?? '',
      vehiculeId: vehiculeId ?? '',
      inspectionDate: inspectionDate.toIso8601String(),
      services: services,
      totalServicesHT: sousTotalPieces,
      totalHT: totalHT,
      totalTTC: totalTTC,
      tvaRate: tvaRate,
      maindoeuvre: maindoeuvre,
      estimatedTime: estimatedTime,
      status: DevisStatus.brouillon,
    );
  }

  DevisFilterState copyWith({
    String? clientId,
    String? clientName,
    String? vehiculeId,
    String? vehicleInfo,
    String? numeroSerie,
    String? status,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? inspectionDate,
    List<Service>? services,
    double? maindoeuvre,
    EstimatedTime? estimatedTime,
    double? tvaRate,
    List<Devis>? devis,
    DevisFilterField? filterField,
    bool? loading,
    String? error,
  }) {
    return DevisFilterState(
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      status: status ?? this.status,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      services: services ?? this.services,
      maindoeuvre: maindoeuvre ?? this.maindoeuvre,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      tvaRate: tvaRate ?? this.tvaRate,
      devis: devis ?? this.devis,
      filterField: filterField ?? this.filterField,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class DevisNotifier extends StateNotifier<DevisFilterState> {
  DevisNotifier(this.ref) : super(DevisFilterState());

  final Ref ref;

  // Récupérer le token depuis le provider (doit exister dans ton code)
  String? get _token => ref.read(authTokenProvider);

  // Vérifier si le token est disponible
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  // État helpers
  void setLoading(bool value) =>
      state = state.copyWith(loading: value, error: value ? null : state.error);

  void setError(String error) => state = state.copyWith(error: error, loading: false);

  void setDevis(List<Devis> devis) => state = state.copyWith(devis: devis, loading: false, error: null);

  void clear() => state = DevisFilterState();

  // Form setters
  void setClient(String id, String name) =>
      state = state.copyWith(clientId: id, clientName: name);

  void setVehicule(String? id, String? info) =>
      state = state.copyWith(vehiculeId: id, vehicleInfo: info);

  void setNumeroSerie(String? numero) =>
      state = state.copyWith(numeroSerie: numero);

  void setInspectionDate(DateTime date) =>
      state = state.copyWith(inspectionDate: date);

  void setMaindoeuvre(double montant) =>
      state = state.copyWith(maindoeuvre: montant);

  void setEstimatedTime(EstimatedTime time) =>
      state = state.copyWith(estimatedTime: time);

  void setTvaRate(double rate) => state = state.copyWith(tvaRate: rate);

  void setFilterField(DevisFilterField field) =>
      state = state.copyWith(filterField: field);

  void setStatusFilter(String? status) => state = state.copyWith(status: status);

  void setDateRange(DateTime? debut, DateTime? fin) =>
      state = state.copyWith(dateDebut: debut, dateFin: fin);

  void setClientNameFilter(String name) =>
      state = state.copyWith(clientName: name);

  // Services manipulation
  void addService(Service service) =>
      state = state.copyWith(services: [...state.services, service]);

  void removeServiceAt(int index) {
    if (index < 0 || index >= state.services.length) return;
    final copy = [...state.services];
    copy.removeAt(index);
    state = state.copyWith(services: copy);
  }

  void updateServiceAt(int index, Service service) {
    if (index < 0 || index >= state.services.length) return;
    final copy = [...state.services];
    copy[index] = service;
    state = state.copyWith(services: copy);
  }

  void clearServices() => state = state.copyWith(services: []);

  // Réseau : charger tous les devis
  Future<void> loadAll() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final devis = await DevisApi.getAllDevis(
        token: _token!,
        status: state.status,
        clientName: state.clientName.isNotEmpty ? state.clientName : null,
        dateDebut: state.dateDebut?.toIso8601String(),
        dateFin: state.dateFin?.toIso8601String(),
      );
      setDevis(devis);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer un devis par ID
  Future<Devis?> getById(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final devis = await DevisApi.getDevisById(_token!, id);
      return devis;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : récupérer un devis par numéro (DEVxxx) avec ordres
  Future<DevisWithOrdres?> getByNum(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return null;
    }

    setLoading(true);
    try {
      final result = await DevisApi.getDevisByNum(_token!, id);
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Réseau : ajouter un devis
  Future<void> ajouterDevis() async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    if (state.clientId.isEmpty || state.vehiculeId == null || state.vehicleInfo == null) {
      state = state.copyWith(error: 'Client et véhicule requis pour créer un devis');
      return;
    }

    setLoading(true);
    try {
      final devis = await DevisApi.createDevis(
        token: _token!,
        clientId: state.clientId,
        clientName: state.clientName,
        vehicleInfo: state.vehicleInfo!,
        vehiculeId: state.vehiculeId!,
        inspectionDate: state.inspectionDate.toIso8601String(),
        services: state.services,
        tvaRate: state.tvaRate,
        maindoeuvre: state.maindoeuvre,
        estimatedTime: state.estimatedTime,
      );
      state = state.copyWith(
        devis: [devis, ...state.devis],
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour un devis
  Future<void> updateDevis(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    if (state.clientId.isEmpty || state.vehiculeId == null || state.vehicleInfo == null) {
      state = state.copyWith(error: 'Client et véhicule requis pour mettre à jour un devis');
      return;
    }

    setLoading(true);
    try {
      final updatedDevis = await DevisApi.updateDevis(
        token: _token!,
        id: id,
        clientId: state.clientId,
        clientName: state.clientName,
        vehicleInfo: state.vehicleInfo,
        inspectionDate: state.inspectionDate.toIso8601String(),
        services: state.services,
        tvaRate: state.tvaRate,
        maindoeuvre: state.maindoeuvre,
        estimatedTime: state.estimatedTime,
      );

      state = state.copyWith(
        devis: state.devis.map((d) => d.devisId == id ? updatedDevis : d).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour le factureId
  Future<void> updateFactureId(String id, String factureId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedDevis = await DevisApi.updateFactureId(
        token: _token!,
        id: id,
        factureId: factureId,
      );
      state = state.copyWith(
        devis: state.devis.map((d) => d.id == id ? updatedDevis : d).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : supprimer un devis
  Future<void> supprimerDevis(String id) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await DevisApi.deleteDevis(_token!, id);
      state = state.copyWith(
        devis: state.devis.where((d) => d.devisId != id).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : accepter un devis
  Future<void> accepterDevis(String devisId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await DevisApi.acceptDevis(_token!, devisId);
      final updatedDevis = await DevisApi.getDevisById(_token!, devisId);
      state = state.copyWith(
        devis: state.devis.map((d) => d.id == updatedDevis.id ? updatedDevis : d).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : refuser un devis
  Future<void> refuserDevis(String devisId) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      await DevisApi.refuseDevis(_token!, devisId);
      final updatedDevis = await DevisApi.getDevisById(_token!, devisId);
      state = state.copyWith(
        devis: state.devis.map((d) => d.id == updatedDevis.id ? updatedDevis : d).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Réseau : mettre à jour le statut
  Future<void> updateDevisStatus(String id, String status) async {
    if (!_hasToken) {
      state = state.copyWith(error: 'Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final updatedDevis = await DevisApi.updateDevisStatus(
        token: _token!,
        id: id,
        status: status,
      );
      state = state.copyWith(
        devis: state.devis.map((d) => d.devisId == id ? updatedDevis : d).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Calcul du montant total des devis chargés
  double totalMontantTTC() {
    return state.devis.fold(0.0, (sum, d) => sum + d.totalTTC);
  }
}

final devisProvider = StateNotifierProvider<DevisNotifier, DevisFilterState>(
  (ref) => DevisNotifier(ref),
);

final devisByIdProvider = Provider.family<Devis?, String>((ref, id) {
  final list = ref.watch(devisProvider).devis;
  try {
    return list.firstWhere((d) => d.devisId == id);
  } catch (_) {
    return null;
  }
});
