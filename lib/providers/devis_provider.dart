// lib/providers/devis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart'; // contient DevisService & Devis
// NOTE: n'importe quel import additionnel (ex: PieceRechange) n'est pas nécessaire ici

class DevisState {
  final String client;
  final String numeroSerie;
  final DateTime date;
  final List<DevisService> services;
  final double mainOeuvre;
  final Duration dureeEstimee;
  final double tva; // fraction: ex 0.19 pour 19%
  final double remise; // fraction: ex 0.10 pour 10%

  DevisState({
    this.client = '',
    this.numeroSerie = '',
    DateTime? date,
    this.services = const [],
    this.mainOeuvre = 0.0,
    this.dureeEstimee = const Duration(hours: 1),
    this.tva = 0.19,
    this.remise = 0.0,
  }) : date = date ?? DateTime.now();

  double get sousTotalPieces => services.fold(0.0, (s, srv) => s + (srv.total));
  double get sousTotal => sousTotalPieces + mainOeuvre;
  double get totalHt => sousTotal * (1.0 - remise);
  double get montantTva => totalHt * tva;
  double get totalTtc => totalHt + montantTva;

  Devis toDevis() {
    return Devis(
      client: client,
      inspectionDate: date,
      services: services,
      totalServicesHT: sousTotalPieces,
      totalHT: totalHt,
      totalTTC: totalTtc,
      tvaRate: tva * 100, // Devis.tvaRate uses percentage in your model
      maindoeuvre: mainOeuvre,
      estimatedTime: dureeEstimee,
      status: DevisStatus.brouillon,
    );
  }

  DevisState copyWith({
    String? client,
    String? numeroSerie,
    DateTime? date,
    List<DevisService>? services,
    double? mainOeuvre,
    Duration? dureeEstimee,
    double? tva,
    double? remise,
  }) {
    return DevisState(
      client: client ?? this.client,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      date: date ?? this.date,
      services: services ?? this.services,
      mainOeuvre: mainOeuvre ?? this.mainOeuvre,
      dureeEstimee: dureeEstimee ?? this.dureeEstimee,
      tva: tva ?? this.tva,
      remise: remise ?? this.remise,
    );
  }
}

class DevisNotifier extends StateNotifier<DevisState> {
  DevisNotifier() : super(DevisState());

  // setters
  void setClient(String v) => state = state.copyWith(client: v);
  void setNumeroSerie(String v) => state = state.copyWith(numeroSerie: v);
  void setDate(DateTime d) => state = state.copyWith(date: d);
  void setMainOeuvre(double m) => state = state.copyWith(mainOeuvre: m);
  void setDuree(Duration d) => state = state.copyWith(dureeEstimee: d);
  void setTva(double t) => state = state.copyWith(tva: t);
  void setRemise(double r) => state = state.copyWith(remise: r);

  // services (lignes)
  void addService(DevisService s) => state = state.copyWith(services: [...state.services, s]);

  void removeServiceAt(int i) {
    final copy = [...state.services];
    if (i >= 0 && i < copy.length) copy.removeAt(i);
    state = state.copyWith(services: copy);
  }

  void updateServiceAt(int i, DevisService s) {
    if (i < 0 || i >= state.services.length) return;
    final list = [...state.services];
    list[i] = s;
    state = state.copyWith(services: list);
  }

  // convert to Devis model (prêt à être envoyé au backend)
  Devis toDevisModel() => state.toDevis();
}

final devisProvider = StateNotifierProvider<DevisNotifier, DevisState>((ref) => DevisNotifier());
