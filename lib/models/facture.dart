// facture.dart

enum PaymentStatus {
  enAttente,
  partiellementPaye,
  paye,
  enRetard,
  annule,
}

enum PaymentMethod {
  especes,
  cheque,
  virement,
  carte,
  autre,
}

class ServiceFacture {
  final String? pieceId;
  final String piece;
  final int quantity;
  final double unitPrice;
  final double total;

  ServiceFacture({
    this.pieceId,
    required this.piece,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory ServiceFacture.fromJson(Map<String, dynamic> json) {
    return ServiceFacture(
      pieceId: json['pieceId']?.toString(),
      piece: json['piece'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pieceId': pieceId,
      'piece': piece,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    }..removeWhere((key, value) => value == null);
  }
}

class ClientInfo {
  final String? nom;
  final String? telephone;
  final String? email;
  final String? adresse;

  ClientInfo({
    this.nom,
    this.telephone,
    this.email,
    this.adresse,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      nom: json['nom'],
      telephone: json['telephone'],
      email: json['email'],
      adresse: json['adresse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
    }..removeWhere((key, value) => value == null);
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

class Facture {
  final String? id; // _id from MongoDB
  final String numeroFacture;
  final String devisId;
  final String clientId;
  final ClientInfo clientInfo;
  final String vehicleInfo;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final DateTime inspectionDate;
  final List<ServiceFacture> services;
  final double maindoeuvre;
  final double tvaRate;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final PaymentMethod? paymentMethod;
  final double paymentAmount;
  final EstimatedTime estimatedTime;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Facture({
    this.id,
    required this.numeroFacture,
    required this.devisId,
    required this.clientId,
    required this.clientInfo,
    required this.vehicleInfo,
    required this.invoiceDate,
    required this.dueDate,
    required this.inspectionDate,
    required this.services,
    this.maindoeuvre = 0.0,
    this.tvaRate = 20.0,
    required this.totalHT,
    required this.totalTVA,
    required this.totalTTC,
    this.paymentStatus = PaymentStatus.enAttente,
    this.paymentDate,
    this.paymentMethod,
    this.paymentAmount = 0.0,
    required this.estimatedTime,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: json['_id']?.toString(),
      numeroFacture: json['numeroFacture'] ?? '',
      devisId: json['devisId']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      clientInfo: ClientInfo.fromJson(json['clientInfo'] ?? {}),
      vehicleInfo: json['vehicleInfo'] ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now().add(Duration(days: 30)),
      inspectionDate: json['inspectionDate'] != null
          ? DateTime.parse(json['inspectionDate'])
          : DateTime.now(),
      services: (json['services'] as List<dynamic>?)
              ?.map((item) => ServiceFacture.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      maindoeuvre: (json['maindoeuvre'] as num?)?.toDouble() ?? 0.0,
      tvaRate: (json['tvaRate'] as num?)?.toDouble() ?? 20.0,
      totalHT: (json['totalHT'] as num?)?.toDouble() ?? 0.0,
      totalTVA: (json['totalTVA'] as num?)?.toDouble() ?? 0.0,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      estimatedTime: EstimatedTime.fromJson(json['estimatedTime'] ?? {}),
      notes: json['notes'],
      createdBy: json['createdBy']?.toString(),
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
      'numeroFacture': numeroFacture,
      'devisId': devisId,
      'clientId': clientId,
      'clientInfo': clientInfo.toJson(),
      'vehicleInfo': vehicleInfo,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'inspectionDate': inspectionDate.toIso8601String(),
      'services': services.map((service) => service.toJson()).toList(),
      'maindoeuvre': maindoeuvre,
      'tvaRate': tvaRate,
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalTTC,
      'paymentStatus': paymentStatus.toString().split('.').last.replaceAll('enAttente', 'en_attente').replaceAll('partiellementPaye', 'partiellement_paye').replaceAll('enRetard', 'en_retard'),
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'paymentAmount': paymentAmount,
      'estimatedTime': estimatedTime.toJson(),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'partiellement_paye':
        return PaymentStatus.partiellementPaye;
      case 'paye':
        return PaymentStatus.paye;
      case 'en_retard':
        return PaymentStatus.enRetard;
      case 'annule':
        return PaymentStatus.annule;
      case 'en_attente':
      default:
        return PaymentStatus.enAttente;
    }
  }

  static PaymentMethod? _parsePaymentMethod(String? method) {
    switch (method) {
      case 'especes':
        return PaymentMethod.especes;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'virement':
        return PaymentMethod.virement;
      case 'carte':
        return PaymentMethod.carte;
      case 'autre':
        return PaymentMethod.autre;
      default:
        return null;
    }
  }
}