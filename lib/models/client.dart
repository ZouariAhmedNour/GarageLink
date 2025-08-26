import 'dart:convert';

enum Categorie { particulier, professionnel }

class Client {
  final String id;
  final String nomComplet;
  final DateTime? dateNaissance;
  final String mail;
  final String telephone;
  final String adresse;
  final Categorie categorie;

  // champs pro (optionnels)
  final String? nomE;
  final String? telephoneE;
  final String? mailE;
  final String? adresseE;

  final List<String> vehiculeIds; // liste d'ids des véhicules rattachés

  Client({
    required this.id,
    required this.nomComplet,
    this.dateNaissance,
    required this.mail,
    required this.telephone,
    required this.adresse,
    this.categorie = Categorie.particulier,
    this.nomE,
    this.telephoneE,
    this.mailE,
    this.adresseE,
    this.vehiculeIds = const [],
  });

  Client copyWith({
    String? id,
    String? nomComplet,
    DateTime? dateNaissance,
    String? mail,
    String? telephone,
    String? adresse,
    Categorie? categorie,
    String? nomE,
    String? telephoneE,
    String? mailE,
    String? adresseE,
    List<String>? vehiculeIds,
  }) {
    return Client(
      id: id ?? this.id,
      nomComplet: nomComplet ?? this.nomComplet,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      mail: mail ?? this.mail,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      categorie: categorie ?? this.categorie,
      nomE: nomE ?? this.nomE,
      telephoneE: telephoneE ?? this.telephoneE,
      mailE: mailE ?? this.mailE,
      adresseE: adresseE ?? this.adresseE,
      vehiculeIds: vehiculeIds ?? this.vehiculeIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomComplet': nomComplet,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'mail': mail,
      'telephone': telephone,
      'adresse': adresse,
      'categorie': categorie.index,
      'nomE': nomE,
      'telephoneE': telephoneE,
      'mailE': mailE,
      'adresseE': adresseE,
      'vehiculeIds': vehiculeIds,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      nomComplet: map['nomComplet'] ?? '',
      dateNaissance: map['dateNaissance'] != null
          ? DateTime.parse(map['dateNaissance'])
          : null,
      mail: map['mail'] ?? '',
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
      categorie: map['categorie'] != null
          ? Categorie.values[map['categorie'] as int]
          : Categorie.particulier,
      nomE: map['nomE'],
      telephoneE: map['telephoneE'],
      mailE: map['mailE'],
      adresseE: map['adresseE'],
      vehiculeIds: map['vehiculeIds'] != null
          ? List<String>.from(map['vehiculeIds'])
          : [],
    );
  }
  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) => Client.fromMap(json.decode(source));
}
