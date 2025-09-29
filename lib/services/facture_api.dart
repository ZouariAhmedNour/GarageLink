import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/global.dart';

class FactureApi {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Créer une facture à partir d'un devis
  /// POST $UrlApi/create/:devisId
 static Future<Facture> createFacture({
  required String token,
  required String devisId,
}) async {
  final url = Uri.parse('$UrlApi/create/$devisId');
  final headers = _authHeaders(token);

  print('➡️ createFacture: POST $url');
  print('➡️ Headers: $headers');

  final stopwatch = Stopwatch()..start();
  http.Response resp;
  try {
    resp = await http.post(url, headers: headers);
  } catch (err, st) {
    stopwatch.stop();
    print('❌ Erreur réseau lors du POST: $err');
    print('❌ Stack: $st');
    throw Exception('Erreur réseau lors de la création de la facture: $err');
  }

  stopwatch.stop();
  print('⬅️ Response status: ${resp.statusCode}  (elapsed: ${stopwatch.elapsedMilliseconds}ms)');
  final contentType = resp.headers['content-type'] ?? '';
  print('⬅️ Content-Type header: $contentType');

  final body = resp.body ?? '';
  print('⬅️ Body length: ${body.length} bytes');
  const int previewMax = 2000;
  print('⬅️ Body preview: ${body.length > previewMax ? body.substring(0, previewMax) + "...(truncated)" : body}');

  // Tentative d'analyse JSON
  dynamic parsed;
  try {
    parsed = jsonDecode(body);
    print('🔎 JSON parsed. Type: ${parsed.runtimeType}');
  } catch (e) {
    print('⚠️ Impossible de parser la réponse en JSON: $e');
    parsed = null;
  }

  // Si succès status, essayer d'extraire la facture
  if (resp.statusCode == 200 || resp.statusCode == 201) {
    try {
      // L'API peut renvoyer { facture: {...} } ou { data: {...} } ou la facture seule
      final candidate = (parsed is Map && (parsed['facture'] ?? parsed['data'] ?? parsed) != null)
          ? (parsed['facture'] ?? parsed['data'] ?? parsed)
          : parsed;

      if (candidate == null) {
        print('❌ Réponse JSON OK mais aucun objet facture détecté — parsed=$parsed');
        throw Exception('Réponse serveur invalide (facture manquante)');
      }

      if (candidate is Map<String, dynamic>) {
        print('🔍 Facture JSON keys: ${candidate.keys.toList()}');
      } else {
        print('⚠️ Candidate facture n\'est pas un Map: ${candidate.runtimeType}');
      }

      final facture = Facture.fromJson(candidate as Map<String, dynamic>);
      print('✅ Facture créée: id=${facture.id}, numero=${facture.numeroFacture}');
      return facture;
    } catch (e, st) {
      print('❌ Erreur lors de la conversion JSON -> Facture: $e');
      print('❌ Stack: $st');
      throw Exception('Erreur traitement réponse facture: $e');
    }
  }

  // Si on arrive ici, le status n'est pas 200/201 => essayer d'extraire message d'erreur du JSON
  try {
    if (parsed is Map) {
      final errMsg = parsed['message'] ?? parsed['error'] ?? parsed['detail'] ?? parsed;
      print('❌ API returned error payload: $errMsg');
      throw Exception('Erreur création facture (${resp.statusCode}): $errMsg');
    } else {
      print('❌ API returned non-JSON error body (${resp.statusCode}): ${body}');
      throw Exception('Erreur création facture (${resp.statusCode}): ${body}');
    }
  } catch (e) {
    // fallback
    throw Exception('Erreur création facture (${resp.statusCode}): ${resp.body}');
  }
}


  /// GET $UrlApi/getFactures?page=..&limit=..&...
  static Future<FacturePagination> getAllFactures({
    required String token,
    String? clientId,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 10,
    String sortBy = 'invoiceDate',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      if (clientId != null) 'clientId': clientId,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    final url = Uri.parse('$UrlApi/getFactures').replace(queryParameters: queryParams);
    final resp = await http.get(url, headers: _authHeaders(token));
    final body = resp.body;

    if (resp.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['success'] == true && (json['data'] != null || json['factures'] != null)) {
        return FacturePagination.fromJson(json);
      }
      // tolérance : si API renvoie directement la liste (rare)
      if (json['data'] is List || json['factures'] is List) {
        return FacturePagination.fromJson({
          'data': json['data'] ?? json['factures'],
          'pagination': json['pagination'] ?? {'currentPage': page, 'totalPages': 1, 'totalItems': (json['data'] ?? json['factures']).length, 'itemsPerPage': limit}
        });
      }
      throw Exception('Réponse inattendue: ${json}');
    }

    throw Exception('Erreur getAllFactures: ${resp.statusCode} $body');
  }

  /// GET $UrlApi/getFacture/:id
  static Future<Facture> getFactureById(String token, String id) async {
    final url = Uri.parse('$UrlApi/getFacture/$id');
    final resp = await http.get(url, headers: _authHeaders(token));
    final body = resp.body;
    if (resp.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final payload = json['data'] ?? json['facture'] ?? json;
      return Facture.fromJson(payload as Map<String, dynamic>);
    }
    throw Exception('Erreur getFactureById: ${resp.statusCode} $body');
  }

  /// GET $UrlApi/factureByDevis/:devisId
  static Future<Facture?> getFactureByDevis(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/factureByDevis/$devisId');
    final resp = await http.get(url, headers: _authHeaders(token));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      // backend renvoie souvent l'objet brut
      final payload = (json is Map && (json['facture'] ?? json['data']) != null) ? (json['facture'] ?? json['data']) : json;
      return Facture.fromJson(payload as Map<String, dynamic>);
    } else if (resp.statusCode == 404) {
      return null;
    }
    throw Exception('Erreur getFactureByDevis: ${resp.statusCode} ${resp.body}');
  }

  /// PUT $UrlApi/:id/payment
  static Future<Facture> marquerFacturePayed({
    required String token,
    required String id,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    DateTime? paymentDate,
  }) async {
    final url = Uri.parse('$UrlApi/$id/payment');
    final body = jsonEncode({
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod.toString().split('.').last,
      if (paymentDate != null) 'paymentDate': paymentDate.toIso8601String(),
    });

    final resp = await http.put(url, headers: _authHeaders(token), body: body);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && json['success'] == true) {
      final payload = json['facture'] ?? json['data'] ?? json;
      return Facture.fromJson(payload as Map<String, dynamic>);
    }
    throw Exception('Erreur marquerFacturePayed: ${resp.statusCode} ${resp.body}');
  }

  /// PUT $UrlApi/:id
  static Future<Facture> updateFacture({
    required String token,
    required String id,
    String? notes,
    DateTime? dueDate,
  }) async {
    final url = Uri.parse('$UrlApi/$id');
    final body = jsonEncode({
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });

    final resp = await http.put(url, headers: _authHeaders(token), body: body);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && json['success'] == true) {
      final payload = json['facture'] ?? json['data'] ?? json;
      return Facture.fromJson(payload as Map<String, dynamic>);
    }
    throw Exception('Erreur updateFacture: ${resp.statusCode} ${resp.body}');
  }

  /// DELETE $UrlApi/:id
  static Future<void> deleteFacture(String token, String id) async {
    final url = Uri.parse('$UrlApi/$id');
    final resp = await http.delete(url, headers: _authHeaders(token));
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && json['success'] == true) {
      return;
    }
    throw Exception('Erreur deleteFacture: ${resp.statusCode} ${resp.body}');
  }

  /// GET $UrlApi/stats/summary
    static Future<FactureStats> getFactureStats(String token) async {
    final url = Uri.parse('$UrlApi/stats/summary');
    final resp = await http.get(url, headers: _authHeaders(token));

    // DEBUG: log pour voir la réponse brute
    debugPrint('FactureApi.getFactureStats -> status: ${resp.statusCode}');
    debugPrint('FactureApi.getFactureStats -> body: ${resp.body}');

    if (resp.statusCode != 200) {
      // essaie d'extraire un message d'erreur si possible
      try {
        final parsedErr = jsonDecode(resp.body);
        final errMsg = (parsedErr is Map) ? (parsedErr['message'] ?? parsedErr['error'] ?? parsedErr) : parsedErr;
        throw Exception('Erreur getFactureStats: ${resp.statusCode} — $errMsg');
      } catch (_) {
        throw Exception('Erreur getFactureStats: ${resp.statusCode} — ${resp.body}');
      }
    }

    // parse JSON
    dynamic parsed;
    try {
      parsed = jsonDecode(resp.body);
    } catch (e) {
      throw Exception('Réponse non JSON pour getFactureStats: ${e.toString()} — body: ${resp.body}');
    }

    // Normaliser payload : on accepte plusieurs formes (data, stats, racine)
    Map<String, dynamic> payload;
    if (parsed is Map<String, dynamic>) {
      if (parsed['data'] is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(parsed['data']);
      } else if (parsed['stats'] is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(parsed['stats']);
      } else {
        payload = Map<String, dynamic>.from(parsed);
      }
    } else {
      throw Exception('Format inattendu pour getFactureStats: ${parsed.runtimeType}');
    }

    // helpers robustes pour convertir num/string/null -> double/int
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '.').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      if (v is String) {
        final cleaned = v.replaceAll(',', '.').trim();
        return int.tryParse(cleaned) ?? (double.tryParse(cleaned)?.toInt() ?? 0);
      }
      return 0;
    }

    // clés alternatives courantes (tolérantes)
    int totalFactures = parseInt(payload['totalFactures'] ?? payload['totalFacture'] ?? payload['count'] ?? payload['total_invoices']);
    double totalTTC = parseDouble(payload['totalTTC'] ?? payload['total'] ?? payload['total_ttc'] ?? payload['totalTtc']);
    double totalPaye = parseDouble(payload['totalPaye'] ?? payload['totalPaid'] ?? payload['total_paye']);
    double totalPayePartiel = parseDouble(payload['totalPayePartiel'] ?? payload['totalPartialPaid'] ?? payload['total_paye_partiel']);
    double totalEncaisse = parseDouble(payload['totalEncaisse'] ?? payload['encaissement'] ?? payload['collected'] ?? 0);
    double totalImpaye = parseDouble(payload['totalImpaye'] ?? payload['totalUnpaid'] ?? payload['unpaid'] ?? 0);

    int facturesPayees = parseInt(payload['facturesPayees'] ?? payload['paidInvoices'] ?? payload['invoicesPaid']);
    int facturesEnRetard = parseInt(payload['facturesEnRetard'] ?? payload['overdueInvoices'] ?? payload['invoicesOverdue']);
    int facturesPartiellesPayees = parseInt(payload['facturesPartiellesPayees'] ?? payload['partialPaidInvoices'] ?? payload['partial_paid']);
    int facturesEnAttente = parseInt(payload['facturesEnAttente'] ?? payload['pendingInvoices'] ?? payload['invoicesPending']);

    double tauxPaiement = parseDouble(payload['tauxPaiement'] ?? payload['paymentRate'] ?? payload['taux'] ?? payload['rate']);

    // Construire et retourner l'objet FactureStats en utilisant le constructeur existant
    return FactureStats(
      totalFactures: totalFactures,
      totalTTC: totalTTC,
      totalPaye: totalPaye,
      totalPayePartiel: totalPayePartiel,
      totalEncaisse: totalEncaisse,
      totalImpaye: totalImpaye,
      facturesPayees: facturesPayees,
      facturesEnRetard: facturesEnRetard,
      facturesPartiellesPayees: facturesPartiellesPayees,
      facturesEnAttente: facturesEnAttente,
      tauxPaiement: tauxPaiement,
    );
  }
}

/// Pagination / Stats classes (inchangées)
class FacturePagination {
  final List<Facture> factures;
  final PaginationInfo pagination;

  FacturePagination({
    required this.factures,
    required this.pagination,
  });

  factory FacturePagination.fromJson(Map<String, dynamic> json) {
    return FacturePagination(
      factures: (json['data'] as List<dynamic>? ?? [])
          .map((item) => Facture.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}

class FactureStats {
  final int totalFactures;
  final double totalTTC;
  final double totalPaye;
  final double totalPayePartiel;
  final double totalEncaisse;
  final double totalImpaye;
  final int facturesPayees;
  final int facturesEnRetard;
  final int facturesPartiellesPayees;
  final int facturesEnAttente;
  final double tauxPaiement;

  FactureStats({
    required this.totalFactures,
    required this.totalTTC,
    required this.totalPaye,
    required this.totalPayePartiel,
    required this.totalEncaisse,
    required this.totalImpaye,
    required this.facturesPayees,
    required this.facturesEnRetard,
    required this.facturesPartiellesPayees,
    required this.facturesEnAttente,
    required this.tauxPaiement,
  });

  factory FactureStats.fromJson(Map<String, dynamic> json) {
    return FactureStats(
      totalFactures: json['totalFactures'] ?? 0,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      totalPaye: (json['totalPaye'] as num?)?.toDouble() ?? 0.0,
      totalPayePartiel: (json['totalPayePartiel'] as num?)?.toDouble() ?? 0.0,
      totalEncaisse: (json['totalEncaisse'] as num?)?.toDouble() ?? 0.0,
      totalImpaye: (json['totalImpaye'] as num?)?.toDouble() ?? 0.0,
      facturesPayees: json['facturesPayees'] ?? 0,
      facturesEnRetard: json['facturesEnRetard'] ?? 0,
      facturesPartiellesPayees: json['facturesPartiellesPayees'] ?? 0,
      facturesEnAttente: json['facturesEnAttente'] ?? 0,
      tauxPaiement: (json['tauxPaiement'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
