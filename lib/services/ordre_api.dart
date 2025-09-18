// ordre_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/global.dart';

class OrdreApi {
  // base: UrlApi is the API root, we append route segments exactly as in your router file.
  // If your UrlApi already ends with "/ordres", change `base` to just UrlApi.
  static final String base = '$UrlApi/ordres';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer tous les ordres (GET /ordres)
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

    final url = Uri.parse(base).replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && (json['success'] == true || json.containsKey('ordres'))) {
      return {
        'ordres': (json['ordres'] as List<dynamic>?)
                ?.map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        'pagination': json['pagination'] as Map<String, dynamic>? ?? {},
      };
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des ordres');
    }
  }

  /// Récupérer un ordre par ID
  /// Note: backend route = GET /ordres/getOrdreTravailById/:id
  static Future<OrdreTravail> getOrdreById(String token, String id) async {
    final url = Uri.parse('$base/getOrdreTravailById/$id');
    final response = await http.get(url, headers: _authHeaders(token));

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération de l\'ordre');
    }
  }

  /// Créer un nouvel ordre (POST /ordres)
  static Future<OrdreTravail> createOrdre({
    required String token,
    required String devisId,
    required DateTime dateCommence,
    required String atelierId,
    String priorite = 'normale',
    String? description,
    required List<Tache> taches,
  }) async {
    final url = Uri.parse(base);
    final body = jsonEncode({
      'devisId': devisId,
      'dateCommence': dateCommence.toIso8601String(),
      'atelierId': atelierId,
      'priorite': priorite,
      'description': description,
      'taches': taches.map((t) => t.toJson()).toList(),
    });

    final response = await http.post(url, headers: _authHeaders(token), body: body);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la création de l\'ordre');
    }
  }

  /// Mettre à jour le statut (PUT /ordres/:id/status)
  static Future<OrdreTravail> updateStatusOrdre({
    required String token,
    required String id,
    required String status,
  }) async {
    final url = Uri.parse('$base/$id/status');
    final body = jsonEncode({'status': status});

    final response = await http.put(url, headers: _authHeaders(token), body: body);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la mise à jour du statut');
    }
  }

  /// Démarrer un ordre (PUT /ordre-travail/:id/demarrer)
  static Future<OrdreTravail> demarrerOrdre(String token, String id) async {
    final url = Uri.parse('$UrlApi/ordre-travail/$id/demarrer');
    final response = await http.put(url, headers: _authHeaders(token));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors du démarrage de l\'ordre');
    }
  }

  /// Terminer un ordre (PUT /ordre-travail/:id/terminer)
  static Future<OrdreTravail> terminerOrdre(String token, String id) async {
    final url = Uri.parse('$UrlApi/ordre-travail/$id/terminer');
    final response = await http.put(url, headers: _authHeaders(token));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la terminaison de l\'ordre');
    }
  }

  /// Supprimer un ordre (soft delete) (DELETE /ordres/:id)
  static Future<void> supprimerOrdre(String token, String id) async {
    final url = Uri.parse('$base/$id');
    final response = await http.delete(url, headers: _authHeaders(token));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return;
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la suppression de l\'ordre');
    }
  }

  /// Récupérer un ordre par devisId (GET /ordre-travail/by-devis/:devisId)
  static Future<Map<String, dynamic>> getOrdreByDevisId(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/ordre-travail/by-devis/$devisId');
    final response = await http.get(url, headers: _authHeaders(token));
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

  /// Récupérer les ordres par statut (GET /ordres/status/:status)
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

    final url = Uri.parse('$UrlApi/ordres/status/$status').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));
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

  /// Récupérer les ordres par atelier (GET /ordres/atelier/:atelierId)
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

    final url = Uri.parse('$UrlApi/ordres/atelier/$atelierId').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));
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

  /// Récupérer les statistiques (GET /ordres/statistiques) -> route backend: /statistiques
  static Future<Map<String, dynamic>> getStatistiques({
    required String token,
    String? atelierId,
  }) async {
    final Map<String, String> queryParams = atelierId != null ? {'atelierId': atelierId} : {};
    // backend route shown: router.get('/statistiques', getStatistiques);
    // if the router is mounted at /ordres, full path is /ordres/statistiques
    final url = Uri.parse('$UrlApi/ordres/statistiques').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _authHeaders(token));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return json['statistiques'] as Map<String, dynamic>;
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  /// Mettre à jour un ordre (PUT /ordres/modifier/:id)
  static Future<OrdreTravail> updateOrdre({
    required String token,
    required String id,
    DateTime? dateCommence,
    String? atelierId,
    String? priorite,
    String? description,
    List<Tache>? taches,
  }) async {
    final url = Uri.parse('$base/modifier/$id');
    final body = jsonEncode({
      'dateCommence': dateCommence?.toIso8601String(),
      'atelierId': atelierId,
      'priorite': priorite,
      'description': description,
      'taches': taches?.map((t) => t.toJson()).toList(),
    });

    final response = await http.put(url, headers: _authHeaders(token), body: body);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && json['success'] == true) {
      return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la mise à jour de l\'ordre');
    }
  }
}
