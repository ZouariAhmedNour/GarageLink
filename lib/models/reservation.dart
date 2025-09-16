// reservation.dart

enum ReservationStatus {
  enAttente,
  accepte,
  refuse,
  contrePropose,
  annule,
}

class Creneau {
  final DateTime? date;
  final String? heureDebut;

  Creneau({
    this.date,
    this.heureDebut,
  });

  factory Creneau.fromJson(Map<String, dynamic> json) {
    return Creneau(
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      heureDebut: json['heureDebut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'heureDebut': heureDebut,
    }..removeWhere((key, value) => value == null);
  }
}

class Reservation {
  final String? id; // _id from MongoDB
  final String garageId;
  final String clientName;
  final String clientPhone;
  final String? clientEmail;
  final String serviceId;
  final Creneau creneauDemande;
  final Creneau? creneauPropose;
  final String descriptionDepannage;
  final ReservationStatus status;
  final String? messageGarage;
  final String? messageClient;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Virtual field
  String? get serviceName => null; // Dépend de la population côté serveur

  Reservation({
    this.id,
    required this.garageId,
    required this.clientName,
    required this.clientPhone,
    this.clientEmail,
    required this.serviceId,
    required this.creneauDemande,
    this.creneauPropose,
    required this.descriptionDepannage,
    this.status = ReservationStatus.enAttente,
    this.messageGarage,
    this.messageClient,
    this.createdAt,
    this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id']?.toString(),
      garageId: json['garageId']?.toString() ?? '',
      clientName: json['clientName']?.trim() ?? '',
      clientPhone: json['clientPhone']?.trim() ?? '',
      clientEmail: json['clientEmail']?.trim(),
      serviceId: json['serviceId']?.toString() ?? '',
      creneauDemande: Creneau.fromJson(json['creneauDemande'] ?? {}),
      creneauPropose: json['creneauPropose'] != null ? Creneau.fromJson(json['creneauPropose']) : null,
      descriptionDepannage: json['descriptionDepannage']?.trim() ?? '',
      status: _parseStatus(json['status']),
      messageGarage: json['messageGarage']?.trim(),
      messageClient: json['messageClient']?.trim(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'garageId': garageId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'serviceId': serviceId,
      'creneauDemande': creneauDemande.toJson(),
      'creneauPropose': creneauPropose?.toJson(),
      'descriptionDepannage': descriptionDepannage,
      'status': status.toString().split('.').last.replaceAll('enAttente', 'en_attente').replaceAll('contrePropose', 'contre_propose'),
      'messageGarage': messageGarage,
      'messageClient': messageClient,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'serviceName': serviceName,
    }..removeWhere((key, value) => value == null);
  }

  static ReservationStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepte':
        return ReservationStatus.accepte;
      case 'refuse':
        return ReservationStatus.refuse;
      case 'contre_propose':
        return ReservationStatus.contrePropose;
      case 'annule':
        return ReservationStatus.annule;
      case 'en_attente':
      default:
        return ReservationStatus.enAttente;
    }
  }
}