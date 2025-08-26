import 'dart:convert';

class Vehicule {
  final String id;
  final String immatriculation;
  final String marque;
  final String modele;
  final int? annee;
  final int? kilometrage;
  final String? picKm; // stocke le path/local file or url
  final DateTime? dateCirculation;
  final String? clientId; // id du client propriétaire

  Vehicule({
    required this.id,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    this.annee,
    this.kilometrage,
    this.picKm,
    this.dateCirculation,
    this.clientId,
  });

  Vehicule copyWith({
    String? id,
    String? immatriculation,
    String? marque,
    String? modele,
    int? annee,
    int? kilometrage,
    String? picKm,
    DateTime? dateCirculation,
    String? clientId,
  }) {
    return Vehicule(
      id: id ?? this.id,
      immatriculation: immatriculation ?? this.immatriculation,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
      kilometrage: kilometrage ?? this.kilometrage,
      picKm: picKm ?? this.picKm,
      dateCirculation: dateCirculation ?? this.dateCirculation,
      clientId: clientId ?? this.clientId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'kilometrage': kilometrage,
      'picKm': picKm,
      'dateCirculation': dateCirculation?.toIso8601String(),
      'clientId': clientId,
    };
  }

  factory Vehicule.fromMap(Map<String, dynamic> map) {
    return Vehicule(
      id: map['id'] ?? '',
      immatriculation: map['immatriculation'] ?? '',
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      annee: map['annee'],
      kilometrage: map['kilometrage'],
      picKm: map['picKm'],
      dateCirculation: map['dateCirculation'] != null
          ? DateTime.parse(map['dateCirculation'])
          : null,
      clientId: map['clientId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Vehicule.fromJson(String source) =>
      Vehicule.fromMap(json.decode(source));
}
