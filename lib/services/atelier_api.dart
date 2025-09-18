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

  /// Récupérer tous les ateliers
  /// GET /getAllAteliers
  static Future<List<Atelier>> getAllAteliers({String? token}) async {
    final url = Uri.parse('$UrlApi/getAllAteliers');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map((e) => Atelier.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (body is Map && body['ateliers'] is List) {
          // fallback si structure différente
          return (body['ateliers'] as List)
              .map((e) => Atelier.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Format inattendu reçu depuis le serveur');
        }
      } catch (e) {
        throw Exception('Erreur parsing response: $e');
      }
    } else {
      String message = 'Erreur serveur (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) message = json['error'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Récupérer un atelier par son id
  /// GET /getAtelierById/:id
  static Future<Atelier> getAtelierById(String id, {String? token}) async {
    final url = Uri.parse('$UrlApi/getAtelierById/$id');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return Atelier.fromJson(body);
      } catch (e) {
        throw Exception('Erreur parsing response: $e');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Atelier non trouvé');
    } else {
      String message = 'Erreur serveur (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) message = json['error'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Créer un atelier
  /// POST /createAtelier
  static Future<Atelier> createAtelier({
    required String name,
    required String localisation,
    String? token,
  }) async {
    final url = Uri.parse('$UrlApi/createAtelier');
    final body = jsonEncode({
      'name': name,
      'localisation': localisation,
    });

    final response = await http.post(url, headers: _authHeaders(token), body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // si le controller retourne directement l'objet atelier
        return Atelier.fromJson(json);
      } catch (e) {
        throw Exception('Erreur parsing response: $e');
      }
    } else {
      String message = 'Erreur création atelier (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) message = json['error'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Mettre à jour un atelier
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
        throw Exception('Erreur parsing response: $e');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Atelier non trouvé');
    } else {
      String message = 'Erreur mise à jour atelier (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) message = json['error'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Supprimer un atelier
  /// DELETE /deleteAtelier/:id
  static Future<void> deleteAtelier(String id, {String? token}) async {
    final url = Uri.parse('$UrlApi/deleteAtelier/$id');
    final response = await http.delete(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      // backend renvoie probablement { message: ... } ou l'objet supprimé
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Atelier non trouvé');
    } else {
      String message = 'Erreur suppression atelier (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) message = json['error'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }
}
