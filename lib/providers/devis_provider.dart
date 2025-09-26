import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/services/devis_api.dart';

enum DevisFilterField { clientName, status, periode }

class DevisFilterState {
  final String clientId;
  final String clientName;
  final String? vehiculeId;
  final String? vehicleInfo;
  final String? numeroSerie;
  final DevisStatus? status; // utiliser DevisStatus plutôt que String
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime inspectionDate;
  final List<Service> services;
  final double maindoeuvre;
  final EstimatedTime estimatedTime;
  final double tvaRate;
  final double remisePercent;
  final List<Devis> devis;
  final DevisFilterField filterField;
  final bool loading;
  final String? error;

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
    this.remisePercent = 0.0,
    List<Devis>? devis,
    this.filterField = DevisFilterField.clientName,
    this.loading = false,
    this.error,
  })  : services = services ?? [],
        estimatedTime = estimatedTime ?? EstimatedTime(),
        devis = devis ?? [],
        inspectionDate = inspectionDate ?? DateTime.now();

  // Calculs
  double get sousTotalPieces => services.fold(0.0, (sum, srv) => sum + srv.total);
  double get totalHTAvantRemise => sousTotalPieces + maindoeuvre;
  double get montantRemise => totalHTAvantRemise * (remisePercent / 100.0);
  double get totalHT => totalHTAvantRemise - montantRemise;
  double get montantTva => totalHT * (tvaRate / 100);
  double get totalTTC => totalHT + montantTva;

  // Convertir en modèle Devis
  Devis toDevis() {
    return Devis(
      devisId: '', // backend générera un ID
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
    DevisStatus? status,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? inspectionDate,
    List<Service>? services,
    double? maindoeuvre,
    EstimatedTime? estimatedTime,
    double? tvaRate,
    double? remisePercent,
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
      remisePercent: remisePercent ?? this.remisePercent,
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

  String? get _token => ref.read(authTokenProvider);
  bool get _hasToken => _token != null && _token!.isNotEmpty;

  void setLoading(bool value) =>
      state = state.copyWith(loading: value, error: value ? null : state.error);

  void setError(String error) =>
      state = state.copyWith(error: error, loading: false);

  void setDevis(List<Devis> devis) =>
      state = state.copyWith(devis: devis, loading: false, error: null);

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

  void setTvaRate(double rate) =>
      state = state.copyWith(tvaRate: rate);

  void setRemise(double percent) =>
      state = state.copyWith(remisePercent: percent);    

  void setFilterField(DevisFilterField field) =>
      state = state.copyWith(filterField: field);

  void setStatusFilter(DevisStatus? status) =>
      state = state.copyWith(status: status);

  void setDateRange(DateTime? debut, DateTime? fin) =>
      state = state.copyWith(dateDebut: debut, dateFin: fin);

  // Services manipulation
  void addService(Service service) =>
      state = state.copyWith(services: [...state.services, service]);

  void removeServiceAt(int index) {
    if (index < 0 || index >= state.services.length) return;
    final copy = [...state.services];
    copy.removeAt(index);
    state = state.copyWith(services: copy);
  }

 Future<Devis?> loadById(String id) async {
  if (!_hasToken) {
    setError('Token d\'authentification requis');
    return null;
  }

  setLoading(true);
  try {
    // Appel API principal (signature token, id)
    final dynamic resp = await DevisApi.getDevisById(_token!, id);

    debugPrint('>>> DevisApi.getDevisById runtimeType=${resp.runtimeType}');
    debugPrint('>>> DevisApi.getDevisById raw: $resp');

    if (resp == null) {
      debugPrint('loadById: réponse nulle');
      return null;
    }

    Devis? d;

    if (resp is Devis) {
      d = resp;
    } else if (resp is Map<String, dynamic>) {
      d = Devis.fromJson(resp);
    } else if (resp is String) {
      try {
        final decoded = json.decode(resp);
        debugPrint('loadById: decoded string -> ${decoded.runtimeType}');
        if (decoded is Map<String, dynamic>) {
          d = Devis.fromJson(decoded);
        } else if (decoded is Map && decoded['data'] is Map) {
          d = Devis.fromJson(Map<String, dynamic>.from(decoded['data']));
        }
      } catch (e) {
        debugPrint('loadById: erreur decode JSON string: $e');
      }
    } else {
      try {
        final maybeMap = resp as Map;
        final extracted = maybeMap['devis'] ?? maybeMap['data'] ?? maybeMap['result'] ?? maybeMap['payload'] ?? maybeMap['item'];
        if (extracted != null) {
          if (extracted is Map) d = Devis.fromJson(Map<String, dynamic>.from(extracted));
        } else {
          d = Devis.fromJson(Map<String, dynamic>.from(maybeMap));
        }
      } catch (e) {
        debugPrint('loadById: impossible de convertir resp en Map -> $e');
      }
    }

    if (d == null && resp is Map) {
      final Map m = Map<String, dynamic>.from(resp);
      final dynamic candidate = m['data'] ?? m['devis'] ?? m['result'] ?? m['payload'] ?? m['item'];
      if (candidate is Map<String, dynamic>) {
        try {
          d = Devis.fromJson(candidate);
        } catch (e) {
          debugPrint('loadById: échec Devis.fromJson sur candidate: $e');
        }
      }
    }

    if (d != null) {
      // <-- fix: créer une variable locale non-nullable pour l'analyseur
      final Devis dd = d;

      // upsert dans le cache local (state.devis)
      final idx = state.devis.indexWhere((x) => x.devisId == dd.devisId || x.id == dd.id);
      final List<Devis> copy = [...state.devis];
      if (idx >= 0) {
        copy[idx] = dd;
      } else {
        copy.insert(0, dd);
      }
      state = state.copyWith(devis: copy);
    } else {
      debugPrint('loadById: pas de Devis construit à partir de la réponse.');
    }

    return d;
  } catch (e, st) {
    debugPrint('DevisNotifier.loadById error: $e\n$st');
    setError(e.toString());
    return null;
  } finally {
    setLoading(false);
  }
}

  void updateServiceAt(int index, Service service) {
    if (index < 0 || index >= state.services.length) return;
    final copy = [...state.services];
    copy[index] = service;
    state = state.copyWith(services: copy);
  }

  void clearServices() => state = state.copyWith(services: []);

  // Réseau
  Future<void> loadAll() async {
    if (!_hasToken) {
      setError('Token d\'authentification requis');
      return;
    }

    setLoading(true);
    try {
      final devis = await DevisApi.getAllDevis(
        token: _token!,
        status: state.status?.toString().split('.').last,
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

  // Autres méthodes CRUD similaires (getById, ajouterDevis, updateDevis...) restent inchangées
  // Pense juste à utiliser DevisStatus au lieu de String pour status
}



final devisProvider = StateNotifierProvider<DevisNotifier, DevisFilterState>(
  (ref) => DevisNotifier(ref),
);

final devisByIdProvider = Provider.family<Devis?, String>((ref, id) {
  final list = ref.watch(devisProvider).devis;
  try {
    return list.firstWhere((d) => d.devisId == id || d.id == id);
  } catch (_) {
    return null;
  }
});


 