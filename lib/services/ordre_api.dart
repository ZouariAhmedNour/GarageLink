// ordre_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/global.dart';

class OrdreApi {
  // UrlApi vient de global.dart (ex: 'http://172.16.58.13:5000/api')
  // Certaines routes du backend sont montées sur la racine /api,
  // d'autres sont sous /api/ordres — on gère les deux bases ici.
  static final String baseRoot = UrlApi; // ex: http://.../api
  static final String baseOrdres = '$UrlApi/ordres'; // ex: http://.../api/ordres

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // Helper pour vérifier si la réponse est du JSON
  static void _ensureJsonResponse(http.Response response) {
    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    if (!contentType.contains('application/json')) {
      throw Exception('Réponse inattendue du serveur (${response.statusCode}) : ${response.body}');
    }
  }

  /// Récupérer tous les ordres (GET /api)
  static Future<Map<String, dynamic>> getAllOrdres({
  required String token,
  int page = 1,
  int limit = 10,
  String? status,
  String? atelierId,
  String? priorite,
  DateTime? dateDebut,
  DateTime? dateFin,
  String sortBy = 'createdAt',
  String sortOrder = 'desc',
}) async {
  final Map<String, String> queryParams = {
    'page': page.toString(),
    'limit': limit.toString(),
    if (status != null) 'status': status,
    if (atelierId != null) 'atelier': atelierId,
    if (priorite != null) 'priorite': priorite,
    if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String(),
    if (dateFin != null) 'dateFin': dateFin.toIso8601String(),
    'sortBy': sortBy,
    'sortOrder': sortOrder,
  };

  // ← utiliser baseRoot (ex: http://172.16.58.13:5000/api) pour la route '/'
  final url = Uri.parse(baseRoot).replace(queryParameters: queryParams);

  print('➡️ GET Ordres URL: $url');
  print('➡️ Headers: ${_authHeaders(token)}');

  final response = await http.get(url, headers: _authHeaders(token));

  print('⬅️ Response status: ${response.statusCode}');
  print('⬅️ Response body: ${response.body}');

  _ensureJsonResponse(response);

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode == 200 && (json['success'] == true || json.containsKey('ordres'))) {
    return {
      'ordres': (json['ordres'] as List<dynamic>? ?? [])
          .map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
          .toList(),
      'pagination': json['pagination'] as Map<String, dynamic>? ?? {},
    };
  } else {
    throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des ordres');
  }
}


  /// Récupérer un ordre par ID (GET /api/getOrdreTravailById/:id)
  static Future<OrdreTravail> getOrdreById(String token, String id) async {
    final url = Uri.parse('$baseRoot/getOrdreTravailById/$id');
    final response = await http.get(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération de l\'ordre');
    }
  }

  /// Créer un nouvel ordre (POST /api)  <-- backend: router.post('/', createOrdreTravail)
  static Future<OrdreTravail> createOrdre({
    required String token,
    required String devisId,
    required DateTime dateCommence,
    required String atelierId,
    String priorite = 'normale',
    String? description,
    required List<Tache> taches,
  }) async {
    final url = Uri.parse(baseRoot); // POST sur la racine /api
    final body = jsonEncode({
      'devisId': devisId,
      'dateCommence': dateCommence.toIso8601String(),
      'atelierId': atelierId,
      'priorite': priorite,
      'description': description,
      'taches': taches.map((t) => t.toJson()).toList(),
    });

    print('⤴ POST $url');
    print('Headers: ${_authHeaders(token)}');
    print('Body: $body');

    final response = await http.post(url, headers: _authHeaders(token), body: body);
    print('⤵ Response ${response.statusCode}: ${response.body}');
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if ((response.statusCode == 201 || response.statusCode == 200) && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la création de l\'ordre');
    }
  }

  /// Mettre à jour le statut (PUT /api/:id/status)
  static Future<OrdreTravail> updateStatusOrdre({
    required String token,
    required String id,
    required String status,
  }) async {
    final url = Uri.parse('$baseRoot/$id/status');
    final body = jsonEncode({'status': status});

    final response = await http.put(url, headers: _authHeaders(token), body: body);
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la mise à jour du statut');
    }
  }

  /// Démarrer un ordre (PUT /api/ordre-travail/:id/demarrer)
  static Future<OrdreTravail> demarrerOrdre(String token, String id) async {
    final url = Uri.parse('$baseRoot/ordre-travail/$id/demarrer');
    final response = await http.put(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors du démarrage de l\'ordre');
    }
  }

  /// Terminer un ordre (PUT /api/ordre-travail/:id/terminer)
  static Future<OrdreTravail> terminerOrdre(String token, String id) async {
    final url = Uri.parse('$baseRoot/ordre-travail/$id/terminer');
    final response = await http.put(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la terminaison de l\'ordre');
    }
  }

  /// Supprimer un ordre (soft delete) (DELETE /api/:id)
  static Future<void> supprimerOrdre(String token, String id) async {
    final url = Uri.parse('$baseRoot/$id');
    final response = await http.delete(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return;
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la suppression de l\'ordre');
    }
  }

  /// Récupérer un ordre par devisId (GET /api/ordre-travail/by-devis/:devisId)
  static Future<Map<String, dynamic>> getOrdreByDevisId(String token, String devisId) async {
    final url = Uri.parse('$baseRoot/ordre-travail/by-devis/$devisId');
    final response = await http.get(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return {
        'exists': json['exists'] ?? false,
        'ordre': json['ordre'] != null ? OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>) : null,
      };
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération de l\'ordre par devis');
    }
  }

  /// Récupérer les ordres par statut (GET /api/ordres/status/:status)
  static Future<Map<String, dynamic>> getOrdresByStatus({
    required String token,
    required String status,
    int page = 1,
    int limit = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final url = Uri.parse('$baseOrdres/status/$status').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return {
        'ordres': (json['ordres'] as List<dynamic>?)
                ?.map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        'total': json['total'] ?? 0,
      };
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des ordres');
    }
  }

  /// Récupérer les ordres par atelier (GET /api/ordres/atelier/:atelierId)
  static Future<Map<String, dynamic>> getOrdresByAtelier({
    required String token,
    required String atelierId,
    int page = 1,
    int limit = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final url = Uri.parse('$baseOrdres/atelier/$atelierId').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return {
        'ordres': (json['ordres'] as List<dynamic>?)
                ?.map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        'total': json['total'] ?? 0,
      };
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des ordres');
    }
  }

  /// Récupérer les statistiques (GET /api/statistiques)
  static Future<Map<String, dynamic>> getStatistiques({
    required String token,
    String? atelierId,
  }) async {
    final Map<String, String> queryParams = atelierId != null ? {'atelierId': atelierId} : {};
    final url = Uri.parse('$baseRoot/statistiques').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return json['statistiques'] as Map<String, dynamic>;
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  /// Mettre à jour un ordre (PUT /api/modifier/:id)
  static Future<OrdreTravail> updateOrdre({
    required String token,
    required String id,
    DateTime? dateCommence,
    String? atelierId,
    String? priorite,
    String? description,
    List<Tache>? taches,
  }) async {
    final url = Uri.parse('$baseRoot/modifier/$id');
    final body = jsonEncode({
      'dateCommence': dateCommence?.toIso8601String(),
      'atelierId': atelierId,
      'priorite': priorite,
      'description': description,
      'taches': taches?.map((t) => t.toJson()).toList(),
    });

    final response = await http.put(url, headers: _authHeaders(token), body: body);
    _ensureJsonResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la mise à jour de l\'ordre');
    }
  }
}
