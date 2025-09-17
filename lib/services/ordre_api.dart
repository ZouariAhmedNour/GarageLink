import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/global.dart'; 

class OrdreApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer tous les ordres de travail
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

    final url = Uri.parse('$UrlApi/ordres').replace(queryParameters: queryParams);
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return {
          'ordres': (json['ordres'] as List<dynamic>)
              .map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
              .toList(),
          'pagination': json['pagination'] as Map<String, dynamic>,
        };
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des ordres');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des ordres');
    }
  }

  /// Récupérer un ordre de travail par ID
  static Future<OrdreTravail> getOrdreById(String token, String id) async {
    final url = Uri.parse('$UrlApi/ordres/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de l\'ordre');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de l\'ordre');
    }
  }

  /// Créer un nouvel ordre de travail
  static Future<OrdreTravail> createOrdre({
    required String token,
    required String devisId,
    required DateTime dateCommence,
    required String atelierId,
    String priorite = 'normale',
    String? description,
    required List<Tache> taches,
  }) async {
    final url = Uri.parse('$UrlApi/ordres');
    final body = jsonEncode({
      'devisId': devisId,
      'dateCommence': dateCommence.toIso8601String(),
      'atelierId': atelierId,
      'priorite': priorite,
      'description': description,
      'taches': taches.map((tache) => tache.toJson()).toList(),
    });

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la création de l\'ordre');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la création de l\'ordre');
    }
  }

  /// Mettre à jour le statut d'un ordre de travail
  static Future<OrdreTravail> updateStatusOrdre({
    required String token,
    required String id,
    required String status,
  }) async {
    final url = Uri.parse('$UrlApi/ordres/$id/status');
    final body = jsonEncode({'status': status});

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour du statut');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour du statut');
    }
  }

  /// Démarrer un ordre de travail
  static Future<OrdreTravail> demarrerOrdre(String token, String id) async {
    final url = Uri.parse('$UrlApi/ordres/$id/demarrer');
    final response = await http.put(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
      }
      throw Exception(json['error'] ?? 'Erreur lors du démarrage de l\'ordre');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors du démarrage de l\'ordre');
    }
  }

  /// Terminer un ordre de travail
  static Future<OrdreTravail> terminerOrdre(String token, String id) async {
    final url = Uri.parse('$UrlApi/ordres/$id/terminer');
    final response = await http.put(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la terminaison de l\'ordre');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la terminaison de l\'ordre');
    }
  }

  /// Supprimer un ordre de travail (soft delete)
  static Future<void> supprimerOrdre(String token, String id) async {
    final url = Uri.parse('$UrlApi/ordres/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return;
      }
      throw Exception(json['error'] ?? 'Erreur lors de la suppression de l\'ordre');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la suppression de l\'ordre');
    }
  }

  /// Récupérer un ordre de travail par devisId
  static Future<Map<String, dynamic>> getOrdreByDevisId(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/ordres/devis/$devisId');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'exists': json['exists'] ?? false,
        'ordre': json['ordre'] != null ? OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>) : null,
      };
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de l\'ordre');
    }
  }

  /// Récupérer les ordres de travail par statut
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
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return {
          'ordres': (json['ordres'] as List<dynamic>)
              .map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
              .toList(),
          'total': json['total'] ?? 0,
        };
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des ordres');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des ordres');
    }
  }

  /// Récupérer les ordres de travail par atelier
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
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return {
          'ordres': (json['ordres'] as List<dynamic>)
              .map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
              .toList(),
          'total': json['total'] ?? 0,
        };
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des ordres');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des ordres');
    }
  }

  /// Récupérer les statistiques des ordres de travail
  static Future<Map<String, dynamic>> getStatistiques({
    required String token,
    String? atelierId,
  }) async {
    final Map<String, String> queryParams = atelierId != null ? {'atelierId': atelierId} : {};
    final url = Uri.parse('$UrlApi/ordres/statistiques').replace(queryParameters: queryParams);
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return json['statistiques'] as Map<String, dynamic>;
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des statistiques');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  /// Mettre à jour un ordre de travail
  static Future<OrdreTravail> updateOrdre({
    required String token,
    required String id,
    DateTime? dateCommence,
    String? atelierId,
    String? priorite,
    String? description,
    List<Tache>? taches,
  }) async {
    final url = Uri.parse('$UrlApi/ordres/$id');
    final body = jsonEncode({
      'dateCommence': dateCommence?.toIso8601String(),
      'atelierId': atelierId,
      'priorite': priorite,
      'description': description,
      'taches': taches?.map((tache) => tache.toJson()).toList(),
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return OrdreTravail.fromJson(json['ordre'] as Map<String, dynamic>);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour de l\'ordre');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour de l\'ordre');
    }
  }
}