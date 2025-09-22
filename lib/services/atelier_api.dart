// lib/services/atelier_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/atelier.dart';
import 'package:garagelink/global.dart';

class AtelierApi {
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return _jsonHeaders;
    }
    return {
      ..._jsonHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /getAllAteliers
  static Future<List<Atelier>> getAllAteliers({String? token}) async {
    final url = Uri.parse('$UrlApi/getAllAteliers');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      try {
        final dynamic body = jsonDecode(response.body);
        if (body is List) {
          return body.map((e) => Atelier.fromJson(e as Map<String, dynamic>)).toList();
        } else if (body is Map && body['ateliers'] is List) {
          return (body['ateliers'] as List)
              .map((e) => Atelier.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Format inattendu reçu depuis le serveur');
        }
      } catch (e) {
        throw Exception('Erreur lors du parsing de la réponse : $e');
      }
    } else if (response.statusCode == 204) {
      return [];
    } else {
      throw _buildExceptionFromResponse(response, 'Erreur lors de la récupération des ateliers');
    }
  }

  /// GET /getAtelierById/:id
  static Future<Atelier> getAtelierById(String id, {String? token}) async {
    final url = Uri.parse('$UrlApi/getAtelierById/$id');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return Atelier.fromJson(body);
      } catch (e) {
        throw Exception('Erreur lors du parsing de la réponse : $e');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Atelier non trouvé');
    } else {
      throw _buildExceptionFromResponse(response, 'Erreur lors de la récupération de l\'atelier');
    }
  }

  /// POST /createAtelier
  static Future<Atelier> createAtelier({
    required String name,
    required String localisation,
    String? token,
  }) async {
    final url = Uri.parse('$UrlApi/createAtelier');
    final body = jsonEncode({'name': name, 'localisation': localisation});

    final response = await http.post(url, headers: _authHeaders(token), body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Atelier.fromJson(json);
      } catch (e) {
        throw Exception('Erreur lors du parsing de la réponse : $e');
      }
    } else {
      throw _buildExceptionFromResponse(response, 'Erreur création atelier (${response.statusCode})');
    }
  }

  /// PUT /updateAtelier/:id
  static Future<Atelier> updateAtelier({
    required String id,
    String? name,
    String? localisation,
    String? token,
  }) async {
    final url = Uri.parse('$UrlApi/updateAtelier/$id');
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (localisation != null) data['localisation'] = localisation;

    final response = await http.put(url, headers: _authHeaders(token), body: jsonEncode(data));

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Atelier.fromJson(json);
      } catch (e) {
        throw Exception('Erreur lors du parsing de la réponse : $e');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Atelier non trouvé');
    } else {
      throw _buildExceptionFromResponse(response, 'Erreur mise à jour atelier (${response.statusCode})');
    }
  }

  /// DELETE /deleteAtelier/:id
  static Future<void> deleteAtelier(String id, {String? token}) async {
    final url = Uri.parse('$UrlApi/deleteAtelier/$id');
    final response = await http.delete(url, headers: _authHeaders(token));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Atelier non trouvé');
    } else {
      throw _buildExceptionFromResponse(response, 'Erreur suppression atelier (${response.statusCode})');
    }
  }

  // Helper : extraire message d'erreur utile depuis la réponse serveur
  static Exception _buildExceptionFromResponse(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded['error'] != null) return Exception(decoded['error'].toString());
        if (decoded['message'] != null) return Exception(decoded['message'].toString());
      }
    } catch (_) {
      // ignore parsing errors
    }
    return Exception(fallback);
  }
}
