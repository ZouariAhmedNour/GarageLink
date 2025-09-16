// ordre.dart

enum TacheStatus {
  nonAssignee,
  assignee,
  enCours,
  terminee,
  suspendue,
}

enum Priorite {
  faible,
  normale,
  elevee,
  urgente,
}

enum OrdreStatus {
  enAttente,
  enCours,
  termine,
  suspendu,
  supprime,
}

class Tache {
  final String? id; // _id from MongoDB
  final String description;
  final int quantite;
  final String serviceId;
  final String serviceNom;
  final String mecanicienId;
  final String mecanicienNom;
  final double estimationHeures;
  final double heuresReelles;
  final String? notes;
  final TacheStatus status;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tache({
    this.id,
    required this.description,
    this.quantite = 1,
    required this.serviceId,
    required this.serviceNom,
    required this.mecanicienId,
    required this.mecanicienNom,
    required this.estimationHeures,
    this.heuresReelles = 0.0,
    this.notes,
    this.status = TacheStatus.assignee,
    this.dateDebut,
    this.dateFin,
    this.createdAt,
    this.updatedAt,
  });

  factory Tache.fromJson(Map<String, dynamic> json) {
    return Tache(
      id: json['_id']?.toString(),
      description: json['description'] ?? '',
      quantite: json['quantite'] ?? 1,
      serviceId: json['serviceId']?.toString() ?? '',
      serviceNom: json['serviceNom'] ?? '',
      mecanicienId: json['mecanicienId']?.toString() ?? '',
      mecanicienNom: json['mecanicienNom'] ?? '',
      estimationHeures: (json['estimationHeures'] as num?)?.toDouble() ?? 1.0,
      heuresReelles: (json['heuresReelles'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      status: _parseTacheStatus(json['status']),
      dateDebut: json['dateDebut'] != null ? DateTime.parse(json['dateDebut']) : null,
      dateFin: json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'description': description,
      'quantite': quantite,
      'serviceId': serviceId,
      'serviceNom': serviceNom,
      'mecanicienId': mecanicienId,
      'mecanicienNom': mecanicienNom,
      'estimationHeures': estimationHeures,
      'heuresReelles': heuresReelles,
      'notes': notes,
      'status': status.toString().split('.').last.replaceAll('nonAssignee', 'non_assignee').replaceAll('enCours', 'en_cours').replaceAll('terminee', 'terminée'),
      'dateDebut': dateDebut?.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  static TacheStatus _parseTacheStatus(String? status) {
    switch (status) {
      case 'non_assignee':
        return TacheStatus.nonAssignee;
      case 'en_cours':
        return TacheStatus.enCours;
      case 'terminée':
        return TacheStatus.terminee;
      case 'suspendue':
        return TacheStatus.suspendue;
      case 'assignee':
      default:
        return TacheStatus.assignee;
    }
  }
}

class ClientInfo {
  final String nom;
  final String ClientId; // Note: Stored as String in JSON
  final String? telephone;
  final String? email;
  final String? adresse;

  ClientInfo({
    required this.nom,
    required this.ClientId,
    this.telephone,
    this.email,
    this.adresse,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      nom: json['nom'] ?? '',
      ClientId: json['ClientId']?.toString() ?? '',
      telephone: json['telephone'],
      email: json['email'],
      adresse: json['adresse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'ClientId': ClientId,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
    }..removeWhere((key, value) => value == null);
  }
}

class VehiculeDetails {
  final String nom;
  final String vehiculeId; // Note: Stored as String in JSON

  VehiculeDetails({
    required this.nom,
    required this.vehiculeId,
  });

  factory VehiculeDetails.fromJson(Map<String, dynamic> json) {
    return VehiculeDetails(
      nom: json['nom'] ?? '',
      vehiculeId: json['vehiculeId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'vehiculeId': vehiculeId,
    };
  }
}

class Note {
  final String? contenu;
  final String? auteur;
  final DateTime date;

  Note({
    this.contenu,
    this.auteur,
    required this.date,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      contenu: json['contenu'],
      auteur: json['auteur'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
      'auteur': auteur,
      'date': date.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}

class OrdreTravail {
  final String? id; // _id from MongoDB
  final String numeroOrdre;
  final String devisId;
  final ClientInfo clientInfo;
  final VehiculeDetails vehiculedetails;
  final DateTime dateCommence;
  final DateTime? dateFinPrevue;
  final DateTime? dateFinReelle;
  final String atelierId;
  final String atelierNom;
  final Priorite priorite;
  final OrdreStatus status;
  final String? description;
  final List<Tache> taches;
  final String? createdBy;
  final String? updatedBy;
  final double totalHeuresEstimees;
  final double totalHeuresReelles;
  final int nombreTaches;
  final int nombreTachesTerminees;
  final List<Note> notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Virtual fields
  int get progressionPourcentage =>
      nombreTaches == 0 ? 0 : ((nombreTachesTerminees / nombreTaches) * 100).round();
  bool get enRetard => dateFinPrevue != null && status != OrdreStatus.termine && DateTime.now().isAfter(dateFinPrevue!);

  OrdreTravail({
    this.id,
    required this.numeroOrdre,
    required this.devisId,
    required this.clientInfo,
    required this.vehiculedetails,
    required this.dateCommence,
    this.dateFinPrevue,
    this.dateFinReelle,
    required this.atelierId,
    required this.atelierNom,
    this.priorite = Priorite.normale,
    this.status = OrdreStatus.enAttente,
    this.description,
    required this.taches,
    this.createdBy,
    this.updatedBy,
    this.totalHeuresEstimees = 0.0,
    this.totalHeuresReelles = 0.0,
    this.nombreTaches = 0,
    this.nombreTachesTerminees = 0,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory OrdreTravail.fromJson(Map<String, dynamic> json) {
    return OrdreTravail(
      id: json['_id']?.toString(),
      numeroOrdre: json['numeroOrdre'] ?? '',
      devisId: json['devisId']?.toString() ?? '',
      clientInfo: ClientInfo.fromJson(json['clientInfo'] ?? {}),
      vehiculedetails: VehiculeDetails.fromJson(json['vehiculedetails'] ?? {}),
      dateCommence: json['dateCommence'] != null ? DateTime.parse(json['dateCommence']) : DateTime.now(),
      dateFinPrevue: json['dateFinPrevue'] != null ? DateTime.parse(json['dateFinPrevue']) : null,
      dateFinReelle: json['dateFinReelle'] != null ? DateTime.parse(json['dateFinReelle']) : null,
      atelierId: json['atelierId']?.toString() ?? '',
      atelierNom: json['atelierNom'] ?? '',
      priorite: _parsePriorite(json['priorite']),
      status: _parseOrdreStatus(json['status']),
      description: json['description'],
      taches: (json['taches'] as List<dynamic>?)
              ?.map((item) => Tache.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      totalHeuresEstimees: (json['totalHeuresEstimees'] as num?)?.toDouble() ?? 0.0,
      totalHeuresReelles: (json['totalHeuresReelles'] as num?)?.toDouble() ?? 0.0,
      nombreTaches: json['nombreTaches'] ?? 0,
      nombreTachesTerminees: json['nombreTachesTerminees'] ?? 0,
      notes: (json['notes'] as List<dynamic>?)
              ?.map((item) => Note.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'numeroOrdre': numeroOrdre,
      'devisId': devisId,
      'clientInfo': clientInfo.toJson(),
      'vehiculedetails': vehiculedetails.toJson(),
      'dateCommence': dateCommence.toIso8601String(),
      'dateFinPrevue': dateFinPrevue?.toIso8601String(),
      'dateFinReelle': dateFinReelle?.toIso8601String(),
      'atelierId': atelierId,
      'atelierNom': atelierNom,
      'priorite': priorite.toString().split('.').last,
      'status': status.toString().split('.').last.replaceAll('enAttente', 'en_attente').replaceAll('enCours', 'en_cours').replaceAll('termine', 'terminé').replaceAll('supprime', 'supprimé'),
      'description': description,
      'taches': taches.map((tache) => tache.toJson()).toList(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'totalHeuresEstimees': totalHeuresEstimees,
      'totalHeuresReelles': totalHeuresReelles,
      'nombreTaches': nombreTaches,
      'nombreTachesTerminees': nombreTachesTerminees,
      'notes': notes.map((note) => note.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'progressionPourcentage': progressionPourcentage,
      'enRetard': enRetard,
    }..removeWhere((key, value) => value == null);
  }

  static Priorite _parsePriorite(String? priorite) {
    switch (priorite) {
      case 'faible':
        return Priorite.faible;
      case 'elevee':
        return Priorite.elevee;
      case 'urgente':
        return Priorite.urgente;
      case 'normale':
      default:
        return Priorite.normale;
    }
  }

  static OrdreStatus _parseOrdreStatus(String? status) {
    switch (status) {
      case 'en_cours':
        return OrdreStatus.enCours;
      case 'terminé':
        return OrdreStatus.termine;
      case 'suspendu':
        return OrdreStatus.suspendu;
      case 'supprimé':
        return OrdreStatus.supprime;
      case 'en_attente':
      default:
        return OrdreStatus.enAttente;
    }
  }
}