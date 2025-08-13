import 'package:garagelink/models/piece.dart';

class Devis {
  final String client;
  final String numeroSerie; // VIN
  final DateTime date;
  final List<Piece> pieces;
  final double mainOeuvre; // montant total main d'œuvre
  final Duration dureeEstimee; // durée estimée de travail
  final double tva; // ex: 0.19

  const Devis({
    required this.client,
    required this.numeroSerie,
    required this.date,
    required this.pieces,
    required this.mainOeuvre,
    required this.dureeEstimee,
    this.tva = 0.19,
  });

  double get sousTotalPieces => pieces.fold(0.0, (s, p) => s + p.total);
  double get sousTotal => sousTotalPieces + mainOeuvre;
  double get montantTva => sousTotal * tva;
  double get totalTtc => sousTotal + montantTva;

  Devis copyWith({
    String? client,
    String? numeroSerie,
    DateTime? date,
    List<Piece>? pieces,
    double? mainOeuvre,
    Duration? dureeEstimee,
    double? tva,
  }) => Devis(
        client: client ?? this.client,
        numeroSerie: numeroSerie ?? this.numeroSerie,
        date: date ?? this.date,
        pieces: pieces ?? this.pieces,
        mainOeuvre: mainOeuvre ?? this.mainOeuvre,
        dureeEstimee: dureeEstimee ?? this.dureeEstimee,
        tva: tva ?? this.tva,
      );
}