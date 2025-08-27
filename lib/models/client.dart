import 'dart:convert';

enum Categorie { particulier, professionnel }

class Client {
  final String id;
  final String nomComplet;
  final String mail; // email
  final String telephone;
  final String adresse;
  final Categorie categorie;

  /// Liste d'ids des véhicules rattachés (utile pour associer véhicules)
  final List<String> vehiculeIds;

  Client({
    required this.id,
    required this.nomComplet,
    required this.mail,
    required this.telephone,
    required this.adresse,
    this.categorie = Categorie.particulier,
    this.vehiculeIds = const [],
  });

  Client copyWith({
    String? id,
    String? nomComplet,
    String? mail,
    String? telephone,
    String? adresse,
    Categorie? categorie,
    List<String>? vehiculeIds,
  }) {
    return Client(
      id: id ?? this.id,
      nomComplet: nomComplet ?? this.nomComplet,
      mail: mail ?? this.mail,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      categorie: categorie ?? this.categorie,
      vehiculeIds: vehiculeIds ?? this.vehiculeIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomComplet': nomComplet,
      'mail': mail,
      'telephone': telephone,
      'adresse': adresse,
      'categorie': categorie.index,
      'vehiculeIds': vehiculeIds,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      nomComplet: map['nomComplet'] ?? '',
      mail: map['mail'] ?? '',
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
      categorie: map['categorie'] != null
          ? Categorie.values[map['categorie'] as int]
          : Categorie.particulier,
      vehiculeIds: map['vehiculeIds'] != null
          ? List<String>.from(map['vehiculeIds'])
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) => Client.fromMap(json.decode(source));
}
