import 'package:garagelink/mecanicien/devis/models/piece.dart';
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
  final double tva;
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
      this.status = DevisStatus.brouillon,
  }) : id = id ?? const Uuid().v4(); // génère un id unique par défaut
  

  double get sousTotalPieces => pieces.fold(0.0, (s, p) => s + p.total);
  double get sousTotal => sousTotalPieces + mainOeuvre;
  double get montantTva => sousTotal * tva;
  double get totalTtc => sousTotal + montantTva;

  Devis copyWith({
    String? id,
    String? client,
    String? numeroSerie,
    DateTime? date,
    List<Piece>? pieces,
    double? mainOeuvre,
    Duration? dureeEstimee,
    double? tva,
    DevisStatus? status
  }) => Devis(
        id: id ?? this.id,
        client: client ?? this.client,
        numeroSerie: numeroSerie ?? this.numeroSerie,
        date: date ?? this.date,
        pieces: pieces ?? this.pieces,
        mainOeuvre: mainOeuvre ?? this.mainOeuvre,
        dureeEstimee: dureeEstimee ?? this.dureeEstimee,
        tva: tva ?? this.tva,
        status: status ?? this.status,
      );
}
