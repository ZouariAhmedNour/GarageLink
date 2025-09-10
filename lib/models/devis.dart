// lib/mecanicien/devis/models/devis.dart
import 'package:garagelink/MecanicienScreens/devis/models/piece.dart';
import 'package:uuid/uuid.dart';

enum DevisStatus { brouillon, envoye, enAttente, accepte, refuse }

class Devis {
  final String id;
  final String client;
  final String numeroSerie;
  final DateTime date;
  final List<Piece> pieces;
  final double mainOeuvre;
  final Duration dureeEstimee;
  final double tva;      // fraction: 0.19 pour 19%
  final double remise;   // fraction: 0.10 pour 10%
  final DevisStatus status;

  Devis({
    String? id,
    required this.client,
    required this.numeroSerie,
    required this.date,
    required this.pieces,
    required this.mainOeuvre,
    required this.dureeEstimee,
    this.tva = 0.19,
    this.remise = 0.0,
    this.status = DevisStatus.brouillon,
  }) : id = id ?? const Uuid().v4();

  // sous-total avant remise (HT brut)
  double get sousTotalPieces => pieces.fold(0.0, (s, p) => s + p.total);
  double get sousTotal => sousTotalPieces + mainOeuvre;

  // Total HT après application de la remise
  double get totalHt => sousTotal * (1.0 - remise);

  // Montant TVA = TVA appliquée sur le Total HT
  double get montantTva => totalHt * tva;

  // Total TTC final
  double get totalTtc => totalHt + montantTva;

  Devis copyWith({
    String? id,
    String? client,
    String? numeroSerie,
    DateTime? date,
    List<Piece>? pieces,
    double? mainOeuvre,
    Duration? dureeEstimee,
    double? tva,
    double? remise,
    DevisStatus? status,
  }) =>
      Devis(
        id: id ?? this.id,
        client: client ?? this.client,
        numeroSerie: numeroSerie ?? this.numeroSerie,
        date: date ?? this.date,
        pieces: pieces ?? this.pieces,
        mainOeuvre: mainOeuvre ?? this.mainOeuvre,
        dureeEstimee: dureeEstimee ?? this.dureeEstimee,
        tva: tva ?? this.tva,
        remise: remise ?? this.remise,
        status: status ?? this.status,
      );
}
