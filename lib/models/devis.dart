// lib/models/devis.dart

enum DevisStatus {
  brouillon,
  envoye,
  accepte,
  refuse,
}

class Service {
  final String piece;        // Nom / désignation de la pièce ou service
  final int quantity;
  final double unitPrice;
  final double total;

  Service({
    required this.piece,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      piece: json['piece'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'piece': piece,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

class EstimatedTime {
  final int days;
  final int hours;
  final int minutes;

  EstimatedTime({
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
  });

  factory EstimatedTime.fromJson(Map<String, dynamic> json) {
    return EstimatedTime(
      days: json['days'] ?? 0,
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'hours': hours,
      'minutes': minutes,
    };
  }
}

class Devis {
  final String? id; // _id from MongoDB
  final String devisId; // Custom ID (e.g., DEV001)
  final String clientId;
  final String clientName;
  final String vehicleInfo;
  final String vehiculeId;
  final String? factureId;
  final String inspectionDate;
  final List<Service> services;
  final double totalHT;
  final double totalServicesHT;
  final double totalTTC;
  final double tvaRate;
  final double maindoeuvre;
  final EstimatedTime estimatedTime;
  final DevisStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Champs calculés
  double get totalCompletHT => totalHT + maindoeuvre;
  double get montantTVA => totalCompletHT * (tvaRate / 100);

  Devis({
    this.id,
    required this.devisId,
    required this.clientId,
    required this.clientName,
    required this.vehicleInfo,
    required this.vehiculeId,
    this.factureId,
    required this.inspectionDate,
    required this.services,
    required this.totalHT,
    required this.totalServicesHT,
    required this.totalTTC,
    this.tvaRate = 20.0,
    this.maindoeuvre = 0.0,
    required this.estimatedTime,
    this.status = DevisStatus.brouillon,
    this.createdAt,
    this.updatedAt,
  });

  factory Devis.fromJson(Map<String, dynamic> json) {
    return Devis(
      id: json['_id']?.toString(),
      devisId: json['id'] ?? '',
      clientId: json['clientId']?.toString() ?? '',
      clientName: json['clientName'] ?? '',
      vehicleInfo: json['vehicleInfo'] ?? '',
      vehiculeId: json['vehiculeId']?.toString() ?? '',
      factureId: json['factureId']?.toString(),
      inspectionDate: json['inspectionDate'] ?? '',
      services: (json['services'] as List<dynamic>? ?? [])
          .map((item) => Service.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalHT: (json['totalHT'] as num?)?.toDouble() ?? 0.0,
      totalServicesHT: (json['totalServicesHT'] as num?)?.toDouble() ?? 0.0,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      tvaRate: (json['tvaRate'] as num?)?.toDouble() ?? 20.0,
      maindoeuvre: (json['maindoeuvre'] as num?)?.toDouble() ?? 0.0,
      estimatedTime: EstimatedTime.fromJson(json['estimatedTime'] ?? {}),
      status: _parseStatus(json['status']),
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
      'id': devisId,
      'clientId': clientId,
      'clientName': clientName,
      'vehicleInfo': vehicleInfo,
      'vehiculeId': vehiculeId,
      'factureId': factureId,
      'inspectionDate': inspectionDate,
      'services': services.map((service) => service.toJson()).toList(),
      'totalHT': totalHT,
      'totalServicesHT': totalServicesHT,
      'totalTTC': totalTTC,
      'tvaRate': tvaRate,
      'maindoeuvre': maindoeuvre,
      'estimatedTime': estimatedTime.toJson(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalCompletHT': totalCompletHT,
      'montantTVA': montantTVA,
    }..removeWhere((key, value) => value == null);
  }

  static DevisStatus _parseStatus(String? status) {
    switch (status) {
      case 'envoye':
        return DevisStatus.envoye;
      case 'accepte':
        return DevisStatus.accepte;
      case 'refuse':
        return DevisStatus.refuse;
      case 'brouillon':
      default:
        return DevisStatus.brouillon;
    }
  }
}
