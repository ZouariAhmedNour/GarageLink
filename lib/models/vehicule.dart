// vehicule.dart

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
  final String? id; // _id from MongoDB
  final String proprietaireId; // Reference to FicheClient
  final String marque;
  final String modele;
  final String immatriculation;
  final int? annee;
  final String? couleur;
  final FuelType typeCarburant;
  final int? kilometrage;
  final VehicleStatus statut;
  final DateTime? createdAt; // From timestamps
  final DateTime? updatedAt; // From timestamps

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
    this.createdAt,
    this.updatedAt,
  });

  // Parse JSON to Vehicule object
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
      statut: json['statut'] == 'actif' ? VehicleStatus.actif : VehicleStatus.inactif,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert Vehicule object to JSON
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null); // Remove null values
  }

  // Helper method to parse fuel type
  static FuelType _parseFuelType(String? type) {
    switch (type) {
      case 'diesel':
        return FuelType.diesel;
      case 'hybride':
        return FuelType.hybride;
      case 'electrique':
        return FuelType.electrique;
      case 'gpl':
        return FuelType.gpl;
      case 'essence':
      default:
        return FuelType.essence;
    }
  }
}