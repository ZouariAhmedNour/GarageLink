import 'dart:convert';

class ClientInfo {
  final String? nom;
  final String? telephone;
  final String? email;
  final String? adresse;

  ClientInfo({this.nom, this.telephone, this.email, this.adresse});

  factory ClientInfo.fromJson(Map<String, dynamic> json) => ClientInfo(
        nom: json['nom'] as String?,
        telephone: json['telephone'] as String?,
        email: json['email'] as String?,
        adresse: json['adresse'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'telephone': telephone,
        'email': email,
        'adresse': adresse,
      };
}

class ServiceItem {
  final String? id; // services._id
  final String? pieceId;
  final String piece;
  final int quantity;
  final double unitPrice;
  final double total;

  ServiceItem({
    this.id,
    this.pieceId,
    required this.piece,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['_id']?.toString(),
        pieceId: json['pieceId']?.toString(),
        piece: (json['piece'] ?? '') as String,
        quantity: (json['quantity'] is int)
            ? json['quantity'] as int
            : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
        unitPrice: (json['unitPrice'] is num)
            ? (json['unitPrice'] as num).toDouble()
            : double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0,
        total: (json['total'] is num)
            ? (json['total'] as num).toDouble()
            : double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'pieceId': pieceId,
        'piece': piece,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

class EstimatedTime {
  final int days;
  final int hours;
  final int minutes;

  // constructeur const — corrige l'erreur non_constant_default_value
  const EstimatedTime({this.days = 0, this.hours = 0, this.minutes = 0});

  factory EstimatedTime.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EstimatedTime();
    return EstimatedTime(
      days: json['days'] is int ? json['days'] as int : int.tryParse('${json['days']}') ?? 0,
      hours: json['hours'] is int ? json['hours'] as int : int.tryParse('${json['hours']}') ?? 0,
      minutes: json['minutes'] is int ? json['minutes'] as int : int.tryParse('${json['minutes']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'days': days,
        'hours': hours,
        'minutes': minutes,
      };
}

class Facture {
  final String? id;
  final String numeroFacture;
  final String? devisId;
  final String? clientId;
  final ClientInfo clientInfo;
  final String? vehicleInfo;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final DateTime? inspectionDate;
  final List<ServiceItem> services;
  final double maindoeuvre;
  final double tvaRate;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final double paymentAmount;
  final EstimatedTime estimatedTime;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Facture({
    this.id,
    required this.numeroFacture,
    this.devisId,
    this.clientId,
    required this.clientInfo,
    this.vehicleInfo,
    this.invoiceDate,
    this.dueDate,
    this.inspectionDate,
    this.services = const [],
    this.maindoeuvre = 0,
    this.tvaRate = 20,
    this.totalHT = 0,
    this.totalTVA = 0,
    this.totalTTC = 0,
    this.paymentStatus = 'en_attente',
    this.paymentDate,
    this.paymentMethod,
    this.paymentAmount = 0,
    this.estimatedTime = const EstimatedTime(),
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPaid => paymentStatus == 'paye' || paymentAmount >= totalTTC;
  bool get isOverdue {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(dueDate!) && paymentStatus != 'paye';
  }

  factory Facture.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Facture(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      numeroFacture: (json['numeroFacture'] ?? '') as String,
      devisId: json['devisId']?.toString(),
      clientId: json['clientId']?.toString(),
      clientInfo: ClientInfo.fromJson(json['clientInfo'] is Map ? json['clientInfo'] as Map<String, dynamic> : {}),
      vehicleInfo: json['vehicleInfo']?.toString(),
      invoiceDate: parseDate(json['invoiceDate'] ?? json['createdAt']),
      dueDate: parseDate(json['dueDate']),
      inspectionDate: parseDate(json['inspectionDate']),
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      maindoeuvre: (json['maindoeuvre'] is num) ? (json['maindoeuvre'] as num).toDouble() : double.tryParse('${json['maindoeuvre']}') ?? 0,
      tvaRate: (json['tvaRate'] is num) ? (json['tvaRate'] as num).toDouble() : double.tryParse('${json['tvaRate']}') ?? 20,
      totalHT: (json['totalHT'] is num) ? (json['totalHT'] as num).toDouble() : double.tryParse('${json['totalHT']}') ?? 0,
      totalTVA: (json['totalTVA'] is num) ? (json['totalTVA'] as num).toDouble() : double.tryParse('${json['totalTVA']}') ?? 0,
      totalTTC: (json['totalTTC'] is num) ? (json['totalTTC'] as num).toDouble() : double.tryParse('${json['totalTTC']}') ?? 0,
      paymentStatus: (json['paymentStatus'] ?? 'en_attente') as String,
      paymentDate: parseDate(json['paymentDate']),
      paymentMethod: json['paymentMethod']?.toString(),
      paymentAmount: (json['paymentAmount'] is num) ? (json['paymentAmount'] as num).toDouble() : double.tryParse('${json['paymentAmount']}') ?? 0,
      estimatedTime: EstimatedTime.fromJson(json['estimatedTime'] as Map<String, dynamic>?),
      notes: json['notes']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'numeroFacture': numeroFacture,
      if (devisId != null) 'devisId': devisId,
      if (clientId != null) 'clientId': clientId,
      'clientInfo': clientInfo.toJson(),
      'vehicleInfo': vehicleInfo,
      'invoiceDate': invoiceDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'inspectionDate': inspectionDate?.toIso8601String(),
      'services': services.map((s) => s.toJson()).toList(),
      'maindoeuvre': maindoeuvre,
      'tvaRate': tvaRate,
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalTTC,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentAmount': paymentAmount,
      'estimatedTime': estimatedTime.toJson(),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}