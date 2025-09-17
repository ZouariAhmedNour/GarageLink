enum FuelType {
  essence,
  diesel,
  hybride,
  electrique,
  gpl,
}

enum VehicleStatus {
  actif,
  inactif,
}

class Vehicule {
  final String? id;
  final String proprietaireId;
  final String marque;
  final String modele;
  final String immatriculation;
  final int? annee;
  final String? couleur;
  final FuelType typeCarburant;
  final int? kilometrage;
  final VehicleStatus statut;
  final String? picKm; // image principale
  final List<String> images; // ✅ tableau d’images
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vehicule({
    this.id,
    required this.proprietaireId,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    this.annee,
    this.couleur,
    this.typeCarburant = FuelType.essence,
    this.kilometrage,
    this.statut = VehicleStatus.actif,
    this.picKm,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Vehicule.fromJson(Map<String, dynamic> json) {
    return Vehicule(
      id: json['_id']?.toString(),
      proprietaireId: json['proprietaireId']?.toString() ?? '',
      marque: json['marque'] ?? '',
      modele: json['modele'] ?? '',
      immatriculation: json['immatriculation'] ?? '',
      annee: json['annee'],
      couleur: json['couleur'],
      typeCarburant: _parseFuelType(json['typeCarburant']),
      kilometrage: json['kilometrage'],
      statut: json['statut'] == 'actif'
          ? VehicleStatus.actif
          : VehicleStatus.inactif,
      picKm: json['picKm'],
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'proprietaireId': proprietaireId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'annee': annee,
      'couleur': couleur,
      'typeCarburant': typeCarburant.toString().split('.').last,
      'kilometrage': kilometrage,
      'statut': statut == VehicleStatus.actif ? 'actif' : 'inactif',
      'picKm': picKm,
      'images': images,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  Vehicule copyWith({
    String? id,
    String? proprietaireId,
    String? marque,
    String? modele,
    String? immatriculation,
    int? annee,
    String? couleur,
    FuelType? typeCarburant,
    int? kilometrage,
    VehicleStatus? statut,
    String? picKm,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicule(
      id: id ?? this.id,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      immatriculation: immatriculation ?? this.immatriculation,
      annee: annee ?? this.annee,
      couleur: couleur ?? this.couleur,
      typeCarburant: typeCarburant ?? this.typeCarburant,
      kilometrage: kilometrage ?? this.kilometrage,
      statut: statut ?? this.statut,
      picKm: picKm ?? this.picKm,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ✅ Ajout du parseur FuelType
  static FuelType _parseFuelType(dynamic value) {
    if (value == null) return FuelType.essence;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'diesel':
        return FuelType.diesel;
      case 'hybride':
        return FuelType.hybride;
      case 'electrique':
        return FuelType.electrique;
      case 'gpl':
        return FuelType.gpl;
      default:
        return FuelType.essence;
    }
  }
}
