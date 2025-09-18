// lib/services/devis_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/global.dart'; // UrlApi

// --- modèles locaux pour la réponse getDevisByNum ---
class OrdreTravail {
  final String? id;
  final String devisId;
  final String? status;
  final DateTime? createdAt;

  OrdreTravail({
    this.id,
    required this.devisId,
    this.status,
    this.createdAt,
  });

  factory OrdreTravail.fromJson(Map<String, dynamic> json) {
    return OrdreTravail(
      id: json['_id']?.toString(),
      devisId: json['devisId']?.toString() ?? '',
      status: json['status'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'devisId': devisId,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    }..removeWhere((k, v) => v == null);
  }
}

class DevisWithOrdres {
  final Devis devis;
  final List<OrdreTravail> ordres;

  DevisWithOrdres({
    required this.devis,
    required this.ordres,
  });

  factory DevisWithOrdres.fromJson(Map<String, dynamic> json) {
    // Le backend renvoie { devis: {...}, ordres: [...] }
    return DevisWithOrdres(
      devis: Devis.fromJson(json['devis'] as Map<String, dynamic>),
      ordres: (json['ordres'] as List<dynamic>?)
              ?.map((item) =>
                  OrdreTravail.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
// ----------------------------------------------------

// En-têtes par défaut pour les requêtes JSON
class DevisApi {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // --------------------
  // Helpers internes
  // --------------------
  // Parse la réponse : si JSON et enveloppé {success,data} -> retourne data,
  // si JSON "nue" -> retourne la Map/List décodée,
  // si HTML/text -> retourne la string body.
  static dynamic _extractJsonData(http.Response response) {
    final body = response.body;

    // Si le body semble être du JSON, on essaie de décoder
    if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success') && decoded.containsKey('data')) {
            return decoded['data'];
          }
          // parfois backend renvoie { message: ..., data: ... } ou document direct
          if (decoded.containsKey('data')) return decoded['data'];
          return decoded;
        }
        return decoded;
      } catch (_) {
        // decode failed -> return raw body
        return body;
      }
    }

    // pas JSON (probablement HTML ou texte) -> retourne string
    return body;
  }

  static String _errorMessageFromResponse(http.Response response) {
    final body = response.body;
    // try to parse an error message from JSON
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
      }
    } catch (_) {
      // ignore
    }
    return 'Erreur HTTP ${response.statusCode} : ${response.reasonPhrase}';
  }

  // --------------------
  // API methods
  // --------------------

  /// Créer un nouveau devis
  /// Back: POST /createdevis
  static Future<Devis> createDevis({
    required String token,
    required String clientId,
    required String clientName,
    required String vehicleInfo,
    required String vehiculeId,
    required String inspectionDate,
    required List<Service> services,
    double? tvaRate,
    double? maindoeuvre,
    required EstimatedTime estimatedTime,
  }) async {
    final url = Uri.parse('$UrlApi/createdevis');
    final body = jsonEncode({
      'clientId': clientId,
      'clientName': clientName,
      'vehicleInfo': vehicleInfo,
      'vehiculeId': vehiculeId,
      'inspectionDate': inspectionDate,
      'services': services.map((s) => s.toJson()).toList(),
      if (tvaRate != null) 'tvaRate': tvaRate,
      if (maindoeuvre != null) 'maindoeuvre': maindoeuvre,
      'estimatedTime': estimatedTime.toJson(),
    });

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is Map<String, dynamic>) {
        return Devis.fromJson(data);
      } else {
        throw Exception('Réponse inattendue du serveur lors de la création du devis.');
      }
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Récupérer tous les devis avec filtres
  /// Back: GET /Devis
  static Future<List<Devis>> getAllDevis({
    required String token,
    String? status,
    String? clientName,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = {
      if (status != null && status != 'tous') 'status': status,
      if (clientName != null) 'clientName': clientName,
      if (dateDebut != null) 'dateDebut': dateDebut,
      if (dateFin != null) 'dateFin': dateFin,
    };
    final url =
        Uri.parse('$UrlApi/Devis').replace(queryParameters: queryParams);
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is List) {
        return data
            .map((item) => Devis.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        // parfois backend renvoie { success:true, data: [ ... ] }
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List)
              .map((item) => Devis.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      throw Exception('Réponse inattendue lors de la récupération des devis.');
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Récupérer un devis par ID (MongoDB _id ou custom id)
  /// Back: GET /Devis/:id
  static Future<Devis> getDevisById(String token, String id) async {
    final url = Uri.parse('$UrlApi/Devis/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is Map<String, dynamic>) {
        return Devis.fromJson(data);
      }
      // si body était directement le document (sans wrapper)
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Devis.fromJson(decoded);
        }
      } catch (_) {}
      throw Exception('Réponse inattendue lors de la récupération du devis.');
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Récupérer un devis par numéro (DEVxxx) avec ordres associés
  /// Back: GET /devis/code/:id
  static Future<DevisWithOrdres> getDevisByNum(String token, String id) async {
    final url = Uri.parse('$UrlApi/devis/code/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is Map<String, dynamic>) {
        // backend renvoie { devis: {...}, ordres: [...] } normalement
        // mais si la réponse est enveloppée dans { success, data: { devis, ordres } }
        if (data.containsKey('devis') && data.containsKey('ordres')) {
          return DevisWithOrdres.fromJson(data);
        } else if (data.containsKey('data') &&
            data['data'] is Map<String, dynamic>) {
          return DevisWithOrdres.fromJson(data['data']);
        } else if (data.containsKey('devis')) {
          return DevisWithOrdres.fromJson(data);
        }
      }

      // fallback: essayer de décoder body brut
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return DevisWithOrdres.fromJson(decoded);
      } catch (_) {
        throw Exception('Réponse inattendue du serveur pour getDevisByNum.');
      }
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Mettre à jour un devis
  /// Back: PUT /Devis/:id
  static Future<Devis> updateDevis({
    required String token,
    required String id, // custom ID (DEVxxx) or Mongo id depending usage
    String? clientId,
    String? clientName,
    String? vehicleInfo,
    String? inspectionDate,
    List<Service>? services,
    double? tvaRate,
    double? maindoeuvre,
    EstimatedTime? estimatedTime,
  }) async {
    final url = Uri.parse('$UrlApi/Devis/$id');
    final body = jsonEncode({
      if (clientId != null) 'clientId': clientId,
      if (clientName != null) 'clientName': clientName,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      if (inspectionDate != null) 'inspectionDate': inspectionDate,
      if (services != null)
        'services': services.map((s) => s.toJson()).toList(),
      if (tvaRate != null) 'tvaRate': tvaRate,
      if (maindoeuvre != null) 'maindoeuvre': maindoeuvre,
      if (estimatedTime != null) 'estimatedTime': estimatedTime.toJson(),
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is Map<String, dynamic>) {
        return Devis.fromJson(data);
      } else {
        // parfois enveloppé { success:true, data: {...} }
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['data'] != null) {
            return Devis.fromJson(decoded['data'] as Map<String, dynamic>);
          }
        } catch (_) {}
        throw Exception('Réponse inattendue lors de la mise à jour du devis');
      }
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Mettre à jour le factureId d'un devis
  /// Back: PUT /updateId/:id  (ici : id est l'_id MongoDB)
  static Future<Devis> updateFactureId({
    required String token,
    required String id, // MongoDB _id
    required String factureId,
  }) async {
    final url = Uri.parse('$UrlApi/updateId/$id');
    final body = jsonEncode({
      'factureId': factureId,
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is Map<String, dynamic>) {
        return Devis.fromJson(data);
      }
      throw Exception('Réponse inattendue lors de la mise à jour du factureId');
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Supprimer un devis
  /// Back: DELETE /Devis/:id
  static Future<void> deleteDevis(String token, String id) async {
    final url = Uri.parse('$UrlApi/Devis/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data == null || data == '' || data is Map || data is List) {
        return;
      }
      return;
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Accepter un devis (appel public utilisé depuis l'email)
  /// Back: GET /devis/:devisId/accept  (souvent attendu un _id MongoDB dans ton back)
  /// Retourne le body (HTML ou texte) pour que l'app puisse l'afficher.
  static Future<String> acceptDevis({String? token, required String devisId}) async {
    final url = Uri.parse('$UrlApi/devis/$devisId/accept');
    final response = await http.get(
      url,
      headers: token != null ? _authHeaders(token) : _headers,
    );

    if (response.statusCode == 200) {
      // Le backend renvoie une page HTML => on renvoie le body pour l'afficher
      return response.body;
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Refuser un devis (appel public utilisé depuis l'email)
  /// Back: GET /devis/:devisId/refuse
  /// Retourne le body (HTML ou texte).
  static Future<String> refuseDevis({String? token, required String devisId}) async {
    final url = Uri.parse('$UrlApi/devis/$devisId/refuse');
    final response = await http.get(
      url,
      headers: token != null ? _authHeaders(token) : _headers,
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Envoyer le devis par email (utilisé depuis l'app/backoffice)
  /// Back: POST /devis/:devisId/send-email (auth required)
  static Future<void> sendDevisByEmail({
    required String token,
    required String devisId,
  }) async {
    final url = Uri.parse('$UrlApi/devis/$devisId/send-email');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      // si backend renvoie {success:true} -> ok
      if (data == null || data == '' || data is Map || data is List) {
        return;
      }
      return;
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }

  /// Mettre à jour le statut d'un devis
  /// Back: PUT /Devis/:id/status
  static Future<Devis> updateDevisStatus({
    required String token,
    required String id, // Custom ID (DEVxxx)
    required String status,
  }) async {
    final url = Uri.parse('$UrlApi/Devis/$id/status');
    final body = jsonEncode({'status': status});

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final data = _extractJsonData(response);
      if (data is Map<String, dynamic>) {
        return Devis.fromJson(data);
      } else {
        // fallback: try to decode raw body
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['data'] != null) {
            return Devis.fromJson(decoded['data'] as Map<String, dynamic>);
          }
        } catch (_) {}
        throw Exception('Réponse inattendue lors de la mise à jour du statut');
      }
    } else {
      throw Exception(_errorMessageFromResponse(response));
    }
  }
}
