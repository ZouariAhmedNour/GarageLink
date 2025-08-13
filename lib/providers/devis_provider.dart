import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/models/piece.dart';


class DevisProvider{
  final String client;
  final String numeroSerie;
  final DateTime date;
  final List<Piece> pieces;
  final double mainOeuvre;
  final Duration dureeEstimee;
  final double tva;

   DevisProvider({
    this.client = '',
    this.numeroSerie = '',
    DateTime? date,
    this.pieces = const [],
    this.mainOeuvre = 0.0,
    this.dureeEstimee = const Duration(hours: 1),
    this.tva = 0.19,
  }) : date = date ?? DateTime.now();

  double get sousTotalPieces => pieces.fold(0.0, (s, p) => s + p.total);
  double get sousTotal => sousTotalPieces + mainOeuvre;
  double get montantTva => sousTotal * tva;
  double get totalTtc => sousTotal + montantTva;

   DevisProvider copyWith({
    String? client,
    String? numeroSerie,
    DateTime? date,
    List<Piece>? pieces,
    double? mainOeuvre,
    Duration? dureeEstimee,
    double? tva,
  }) => DevisProvider(
        client: client ?? this.client,
        numeroSerie: numeroSerie ?? this.numeroSerie,
        date: date ?? this.date,
        pieces: pieces ?? this.pieces,
        mainOeuvre: mainOeuvre ?? this.mainOeuvre,
        dureeEstimee: dureeEstimee ?? this.dureeEstimee,
        tva: tva ?? this.tva,
      );

  Devis toDevis() => Devis(
        client: client,
        numeroSerie: numeroSerie,
        date: date,
        pieces: pieces,
        mainOeuvre: mainOeuvre,
        dureeEstimee: dureeEstimee,
        tva: tva,
      );
}

class DevisNotifier extends StateNotifier<DevisProvider> {
  DevisNotifier() : super( DevisProvider());

  void setClient(String v) => state = state.copyWith(client: v);
  void setNumeroSerie(String v) => state = state.copyWith(numeroSerie: v);
  void setDate(DateTime d) => state = state.copyWith(date: d);
  void setMainOeuvre(double m) => state = state.copyWith(mainOeuvre: m);
  void setDuree(Duration d) => state = state.copyWith(dureeEstimee: d);
  void setTva(double t) => state = state.copyWith(tva: t);

  void addPiece(Piece p) => state = state.copyWith(pieces: [...state.pieces, p]);
  void removePieceAt(int i) {
    final copy = [...state.pieces];
    if (i >= 0 && i < copy.length) copy.removeAt(i);
    state = state.copyWith(pieces: copy);
  }
}

final devisProvider = StateNotifierProvider<DevisNotifier, DevisProvider>((ref) => DevisNotifier());