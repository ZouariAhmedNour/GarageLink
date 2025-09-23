// facture.dart
import 'package:garagelink/models/devis.dart';

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
      piece: json['piece']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
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
    }..removeWhere((k, v) => v == null);
  }
}

class ClientInfo {
  final String? nom;
  final String? telephone;
  final String? email;
  final String? adresse;

  ClientInfo({this.nom, this.telephone, this.email, this.adresse});

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      nom: json['nom']?.toString(),
      telephone: json['telephone']?.toString(),
      email: json['email']?.toString(),
      adresse: json['adresse']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
    }..removeWhere((k, v) => v == null);
  }
}

class EstimatedTime {
  final int days;
  final int hours;
  final int minutes;

  EstimatedTime({this.days = 0, this.hours = 0, this.minutes = 0});

  factory EstimatedTime.fromJson(Map<String, dynamic> json) {
    return EstimatedTime(
      days: (json['days'] as num?)?.toInt() ?? 0,
      hours: (json['hours'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'days': days, 'hours': hours, 'minutes': minutes};
  }
}

// ---------- Helpers pour normaliser id / date ----------
String? _extractId(dynamic raw) {
  try {
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map) {
      // common mongo representation: { "$oid": "..." } or _id: { "$oid": "..." }
      if (raw.containsKey(r'$oid')) return raw[r'$oid']?.toString();
      if (raw.containsKey('_id')) {
        final cand = raw['_id'];
        if (cand is Map && cand.containsKey(r'$oid')) return cand[r'$oid']?.toString();
        if (cand is String) return cand;
      }
      // If map is actually an object containing id-like fields
      if (raw.containsKey('id')) return raw['id']?.toString();
      if (raw.containsKey('_id')) return raw['_id']?.toString();
    }
    // fallback to string conversion
    return raw.toString();
  } catch (_) {
    return null;
  }
}

DateTime? _parseDate(dynamic raw) {
  try {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    if (raw is Map) {
      // mongo date form: { "$date": "2025-09-23T..." } OR { "$date": 123456789 }
      if (raw.containsKey(r'$date')) {
        final val = raw[r'$date'];
        if (val is String) return DateTime.tryParse(val);
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

// ---------- Facture model ----------
class Facture {
  final String? id; // normalized mongo _id
  final String numeroFacture;
  final String? devisId; // normalized string id if available
  final Devis? devis; // embedded Devis object if the API returned it
  final String? clientId;
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
    this.devisId,
    this.devis,
    this.clientId,
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
    // normaliser id + clientId
    final idNorm = _extractId(json['_id'] ?? json['id']);
    final clientNorm = _extractId(json['clientId'] ?? json['client'] ?? json['client_id']);

    // traiter devis peut être :
    // - une chaîne (id)
    // - un map {$oid: "..."}
    // - un objet embedded (Map contenant champs de Devis)
    String? devisIdNorm;
    Devis? embeddedDevis;
    final rawDevis = json['devisId'] ?? json['devis'] ?? json['devis_id'] ?? json['devisID'];
    if (rawDevis != null) {
      // si c'est un map qui ressemble à un Devis (contient clientName/services/etc), on essaye de parser en Devis
      if (rawDevis is Map) {
        // d'abord essayer d'extraire un oid
        devisIdNorm = _extractId(rawDevis);
        // si le map contient des champs typiques d'un devis, on essaye Devis.fromJson
        final looksLikeDevis =
            rawDevis.containsKey('clientName') || rawDevis.containsKey('services') || rawDevis.containsKey('devisId') || rawDevis.containsKey('_id') || rawDevis.containsKey('totalTTC');
        if (looksLikeDevis) {
          try {
            embeddedDevis = Devis.fromJson(Map<String, dynamic>.from(rawDevis));
            // si embeddedDevis a un id, utilisez-le si devisIdNorm vide
            final maybe = embeddedDevis.id ?? (embeddedDevis.devisId.isNotEmpty ? embeddedDevis.devisId : null);
            if (devisIdNorm == null && maybe != null) devisIdNorm = maybe;
          } catch (_) {
            // ignore parse error, keep string id if any
          }
        }
      } else {
        // si c'est une string ou autre primitive
        devisIdNorm = _extractId(rawDevis);
      }
    }

    // parser dates tolérant
    final invoiceDt = _parseDate(json['invoiceDate']) ?? DateTime.now();
    final dueDt = _parseDate(json['dueDate']) ?? invoiceDt.add(const Duration(days: 30));
    final inspectionDt = _parseDate(json['inspectionDate']) ?? DateTime.now();

    // services robuste
    final rawServices = json['services'];
    final servicesList = <ServiceFacture>[];
    if (rawServices is List) {
      for (var s in rawServices) {
        if (s is Map) {
          servicesList.add(ServiceFacture.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    return Facture(
      id: idNorm,
      numeroFacture: json['numeroFacture']?.toString() ?? '',
      devisId: devisIdNorm,
      devis: embeddedDevis,
      clientId: clientNorm,
      clientInfo: ClientInfo.fromJson(Map<String, dynamic>.from(json['clientInfo'] ?? {})),
      vehicleInfo: json['vehicleInfo']?.toString() ?? '',
      invoiceDate: invoiceDt,
      dueDate: dueDt,
      inspectionDate: inspectionDt,
      services: servicesList,
      maindoeuvre: (json['maindoeuvre'] as num?)?.toDouble() ?? 0.0,
      tvaRate: (json['tvaRate'] as num?)?.toDouble() ?? 20.0,
      totalHT: (json['totalHT'] as num?)?.toDouble() ?? 0.0,
      totalTVA: (json['totalTVA'] as num?)?.toDouble() ?? 0.0,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: _parsePaymentStatus(json['paymentStatus']?.toString()),
      paymentDate: _parseDate(json['paymentDate']),
      paymentMethod: _parsePaymentMethod(json['paymentMethod']?.toString()),
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      estimatedTime: EstimatedTime.fromJson(Map<String, dynamic>.from(json['estimatedTime'] ?? {})),
      notes: json['notes']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      '_id': id,
      'numeroFacture': numeroFacture,
      // on privilégie devisId string si disponible, sinon on expose l'objet embed si présent
      if (devisId != null) 'devisId': devisId,
      if (devis == null && devisId == null) 'devisId': null,
      'clientId': clientId,
      'clientInfo': clientInfo.toJson(),
      'vehicleInfo': vehicleInfo,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'inspectionDate': inspectionDate.toIso8601String(),
      'services': services.map((s) => s.toJson()).toList(),
      'maindoeuvre': maindoeuvre,
      'tvaRate': tvaRate,
      'totalHT': totalHT,
      'totalTVA': totalTVA,
      'totalTTC': totalTTC,
      'paymentStatus': paymentStatusToApi(paymentStatus),
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'paymentAmount': paymentAmount,
      'estimatedTime': estimatedTime.toJson(),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((k, v) => v == null);

    // si on a embed Devis et on préfère l'inclure :
    if (devis != null && (map['devisId'] == null || (map['devisId']?.toString().isEmpty ?? true))) {
      map['devis'] = devis!.toJson(); // nécessite Devis.toJson()
    }

    return map;
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

  static String paymentStatusToApi(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.partiellementPaye:
        return 'partiellement_paye';
      case PaymentStatus.paye:
        return 'paye';
      case PaymentStatus.enRetard:
        return 'en_retard';
      case PaymentStatus.annule:
        return 'annule';
      case PaymentStatus.enAttente:
      return 'en_attente';
    }
  }
}
