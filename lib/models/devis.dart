// lib/models/devis.dart

enum DevisStatus { brouillon, envoye, accepte, refuse, enAttente, inconnu }

DevisStatus statusFromString(String? s) {
  if (s == null) return DevisStatus.inconnu;
  switch (s.toLowerCase()) {
    case 'brouillon':
      return DevisStatus.brouillon;
    case 'envoye':
      return DevisStatus.envoye;
    case 'accepte':
      return DevisStatus.accepte;
    case 'refuse':
      return DevisStatus.refuse;
    case 'enattente':
    case 'en_attente':
    case 'en attente':
      return DevisStatus.enAttente;
    default:
      return DevisStatus.inconnu;
  }
}

String statusToString(DevisStatus s) {
  switch (s) {
    case DevisStatus.brouillon:
      return 'brouillon';
    case DevisStatus.envoye:
      return 'envoye';
    case DevisStatus.accepte:
      return 'accepte';
    case DevisStatus.refuse:
      return 'refuse';
    case DevisStatus.enAttente:
      return 'enAttente';
    default:
      return 'inconnu';
  }
}

class DevisService {
  final String? pieceId;
  final String piece; // nom
  final int quantity;
  final double unitPrice;
  final double total;

  DevisService({
    this.pieceId,
    required this.piece,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory DevisService.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'] ?? json['qty'] ?? 0;
    final up = json['unitPrice'] ?? json['prixUnitaire'] ?? json['prix'] ?? 0;
    final t = json['total'] ?? (q is num && up is num ? q * up : 0);
    return DevisService(
      pieceId: json['pieceId']?.toString(),
      piece: json['piece']?.toString() ?? json['name']?.toString() ?? '',
      quantity: _toInt(q),
      unitPrice: _toDouble(up),
      total: _toDouble(t),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pieceId != null) 'pieceId': pieceId,
      'piece': piece,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  DevisService copyWith({
    String? pieceId,
    String? piece,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return DevisService(
      pieceId: pieceId ?? this.pieceId,
      piece: piece ?? this.piece,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class Devis {
  final String? id; // champ id (DEV001) ou _id in DB
  final String? factureId;
  final String? clientId;
  final String client;
  final String? vehicleInfo;
  final String? vehiculeId;
  final DateTime? inspectionDate;
  final List<DevisService> services;
  final double totalServicesHT;
  final double totalHT;
  final double totalTTC;
  final double tvaRate;
  final double maindoeuvre;
  final Duration estimatedTime;
  final DevisStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Devis({
    this.id,
    this.factureId,
    this.clientId,
    required this.client,
    this.vehicleInfo,
    this.vehiculeId,
    this.inspectionDate,
    this.services = const [],
    required this.totalServicesHT,
    required this.totalHT,
    required this.totalTTC,
    this.tvaRate = 20.0,
    this.maindoeuvre = 0.0,
    this.estimatedTime = const Duration(),
    this.status = DevisStatus.brouillon,
    this.createdAt,
    this.updatedAt,
  });

  factory Devis.fromJson(Map<String, dynamic> json) {
    // inspectionDate is a String in backend
    DateTime? parsedDate;
    final dateRaw = json['inspectionDate'] ?? json['date'] ?? json['createdAt'];
    if (dateRaw != null) {
      try {
        parsedDate = DateTime.parse(dateRaw.toString());
      } catch (_) {
        parsedDate = null;
      }
    }

    // estimatedTime may be an object {days,hours,minutes}
    Duration duration = Duration();
    final est = json['estimatedTime'];
    if (est is Map) {
      final days = int.tryParse((est['days'] ?? 0).toString()) ?? 0;
      final hours = int.tryParse((est['hours'] ?? 0).toString()) ?? 0;
      final minutes = int.tryParse((est['minutes'] ?? 0).toString()) ?? 0;
      duration = Duration(days: days, hours: hours, minutes: minutes);
    }

    final servicesRaw = json['services'];
    List<DevisService> services = [];
    if (servicesRaw is List) {
      services = servicesRaw.map<DevisService>((e) {
        if (e is Map<String, dynamic>) return DevisService.fromJson(e);
        return DevisService.fromJson(Map<String, dynamic>.from(e));
      }).toList();
    }

    return Devis(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      factureId: json['factureId']?.toString(),
      clientId: json['clientId']?.toString(),
      client: json['clientName']?.toString() ?? json['client']?.toString() ?? '',
      vehicleInfo: json['vehicleInfo']?.toString(),
      vehiculeId: json['vehiculeId']?.toString(),
      inspectionDate: parsedDate,
      services: services,
      totalServicesHT: _toDouble(json['totalServicesHT'] ?? json['totalServices'] ?? 0),
      totalHT: _toDouble(json['totalHT'] ?? 0),
      totalTTC: _toDouble(json['totalTTC'] ?? json['total'] ?? 0),
      tvaRate: _toDouble(json['tvaRate'] ?? json['tva'] ?? 20),
      maindoeuvre: _toDouble(json['maindoeuvre'] ?? json['maindoeuvre'] ?? 0),
      estimatedTime: duration,
      status: statusFromString(json['status']?.toString()),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (factureId != null) 'factureId': factureId,
      if (clientId != null) 'clientId': clientId,
      'clientName': client,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      if (vehiculeId != null) 'vehiculeId': vehiculeId,
      if (inspectionDate != null) 'inspectionDate': inspectionDate!.toIso8601String(),
      'services': services.map((s) => s.toJson()).toList(),
      'totalServicesHT': totalServicesHT,
      'totalHT': totalHT,
      'totalTTC': totalTTC,
      'tvaRate': tvaRate,
      'maindoeuvre': maindoeuvre,
      'estimatedTime': {
        'days': estimatedTime.inDays,
        'hours': estimatedTime.inHours.remainder(24),
        'minutes': estimatedTime.inMinutes.remainder(60),
      },
      'status': statusToString(status),
    };
  }

  Devis copyWith({
    String? id,
    String? factureId,
    String? clientId,
    String? client,
    String? vehicleInfo,
    String? vehiculeId,
    DateTime? inspectionDate,
    List<DevisService>? services,
    double? totalServicesHT,
    double? totalHT,
    double? totalTTC,
    double? tvaRate,
    double? maindoeuvre,
    Duration? estimatedTime,
    DevisStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Devis(
      id: id ?? this.id,
      factureId: factureId ?? this.factureId,
      clientId: clientId ?? this.clientId,
      client: client ?? this.client,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      services: services ?? this.services,
      totalServicesHT: totalServicesHT ?? this.totalServicesHT,
      totalHT: totalHT ?? this.totalHT,
      totalTTC: totalTTC ?? this.totalTTC,
      tvaRate: tvaRate ?? this.tvaRate,
      maindoeuvre: maindoeuvre ?? this.maindoeuvre,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get sousTotalPieces => services.fold(0.0, (s, sv) => s + sv.total);
  double get sousTotal => sousTotalPieces + maindoeuvre;
  double get montantTva => (totalHT) * (tvaRate / 100);
  double get totalTtcComputed => totalHT + montantTva;

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'Devis(id: $id, client: $client, totalTTC: $totalTTC)';
}
