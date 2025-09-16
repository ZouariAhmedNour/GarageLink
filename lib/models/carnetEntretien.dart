// carnet_entretien.dart

enum CarnetStatus {
  enCours,
  termine,
  annule,
}

class ServiceEntretien {
  final String nom;
  final String? description;
  final int quantite;
  final double? prix;

  ServiceEntretien({
    required this.nom,
    this.description,
    this.quantite = 1,
    this.prix,
  });

  factory ServiceEntretien.fromJson(Map<String, dynamic> json) {
    return ServiceEntretien(
      nom: json['nom'] ?? '',
      description: json['description'],
      quantite: json['quantite'] ?? 1,
      prix: (json['prix'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'quantite': quantite,
      'prix': prix,
    }..removeWhere((key, value) => value == null);
  }
}

class PieceEntretien {
  final String? nom;
  final String? reference;
  final int quantite;
  final double? prix;

  PieceEntretien({
    this.nom,
    this.reference,
    this.quantite = 1,
    this.prix,
  });

  factory PieceEntretien.fromJson(Map<String, dynamic> json) {
    return PieceEntretien(
      nom: json['nom'],
      reference: json['reference'],
      quantite: json['quantite'] ?? 1,
      prix: (json['prix'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'reference': reference,
      'quantite': quantite,
      'prix': prix,
    }..removeWhere((key, value) => value == null);
  }
}

class DureeEntretien {
  final int jours;
  final int heures;

  DureeEntretien({
    required this.jours,
    required this.heures,
  });

  factory DureeEntretien.fromJson(Map<String, dynamic> json) {
    return DureeEntretien(
      jours: json['jours'] ?? 0,
      heures: json['heures'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jours': jours,
      'heures': heures,
    };
  }
}

class CarnetEntretien {
  final String? id; // _id from MongoDB
  final String vehiculeId;
  final String? devisId;
  final DateTime dateCommencement;
  final DateTime? dateFinCompletion;
  final CarnetStatus statut;
  final double totalTTC;
  final int? kilometrageEntretien;
  final String? notes;
  final List<ServiceEntretien> services;
  final List<PieceEntretien> pieces;
  final String? technicien;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Virtual field as getter
  DureeEntretien? get dureeEntretien {
    if (dateFinCompletion == null) return null;
    final diffMs = dateFinCompletion!.difference(dateCommencement).inMilliseconds;
    return DureeEntretien(
      jours: diffMs ~/ (1000 * 60 * 60 * 24),
      heures: (diffMs % (1000 * 60 * 60 * 24)) ~/ (1000 * 60 * 60),
    );
  }

  CarnetEntretien({
    this.id,
    required this.vehiculeId,
    this.devisId,
    required this.dateCommencement,
    this.dateFinCompletion,
    this.statut = CarnetStatus.enCours,
    required this.totalTTC,
    this.kilometrageEntretien,
    this.notes,
    required this.services,
    required this.pieces,
    this.technicien,
    this.createdAt,
    this.updatedAt,
  });

  factory CarnetEntretien.fromJson(Map<String, dynamic> json) {
    return CarnetEntretien(
      id: json['_id']?.toString(),
      vehiculeId: json['vehiculeId']?.toString() ?? '',
      devisId: json['devisId']?.toString(),
      dateCommencement: json['dateCommencement'] != null
          ? DateTime.parse(json['dateCommencement'])
          : DateTime.now(),
      dateFinCompletion: json['dateFinCompletion'] != null
          ? DateTime.parse(json['dateFinCompletion'])
          : null,
      statut: _parseStatus(json['statut']),
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      kilometrageEntretien: json['kilometrageEntretien'],
      notes: json['notes'],
      services: (json['services'] as List<dynamic>?)
              ?.map((item) => ServiceEntretien.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pieces: (json['pieces'] as List<dynamic>?)
              ?.map((item) => PieceEntretien.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      technicien: json['technicien'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehiculeId': vehiculeId,
      'devisId': devisId,
      'dateCommencement': dateCommencement.toIso8601String(),
      'dateFinCompletion': dateFinCompletion?.toIso8601String(),
      'statut': statut.toString().split('.').last.replaceAll('enCours', 'en_cours'),
      'totalTTC': totalTTC,
      'kilometrageEntretien': kilometrageEntretien,
      'notes': notes,
      'services': services.map((service) => service.toJson()).toList(),
      'pieces': pieces.map((piece) => piece.toJson()).toList(),
      'technicien': technicien,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'dureeEntretien': dureeEntretien?.toJson(),
    }..removeWhere((key, value) => value == null);
  }

  static CarnetStatus _parseStatus(String? status) {
    switch (status) {
      case 'termine':
        return CarnetStatus.termine;
      case 'annule':
        return CarnetStatus.annule;
      case 'en_cours':
      default:
        return CarnetStatus.enCours;
    }
  }
}