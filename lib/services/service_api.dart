import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/service.dart';
import 'package:garagelink/global.dart';

class ServiceApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification si token fourni
  static Map<String, String> _headersWithOptionalToken(String? token) {
    if (token == null || token.isEmpty) return _headers;
    return {
      ..._headers,
      'Authorization': 'Bearer $token',
    };
  }

  /// Récupérer tous les services
  static Future<List<Service>> getAllServices({String? token}) async {
    final url = Uri.parse('$UrlApi/getAllServices');
    final response = await http.get(
      url,
      headers: _headersWithOptionalToken(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Service.fromJson(json)).toList();
    } else {
      _throwApiError(response);
    }
  }

  /// Récupérer un service par ID
  static Future<Service> getServiceById({String? token, required String id}) async {
    final url = Uri.parse('$UrlApi/getServiceById/$id');
    final response = await http.get(
      url,
      headers: _headersWithOptionalToken(token),
    );

    if (response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      _throwApiError(response);
    }
  }

  /// Créer un nouveau service
  static Future<Service> createService({
    String? token,
    required String name,
    required String description,
    ServiceStatut? statut,
  }) async {
    final url = Uri.parse('$UrlApi/createService');
    final body = jsonEncode({
      'name': name,
      'description': description,
      if (statut != null) 'statut': Service.statutToString(statut),
    });

    final response = await http.post(
      url,
      headers: _headersWithOptionalToken(token),
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      _throwApiError(response);
    }
  }

  /// Mettre à jour un service
  static Future<Service> updateService({
    String? token,
    required String id,
    String? name,
    String? description,
    ServiceStatut? statut,
  }) async {
    final url = Uri.parse('$UrlApi/updateService/$id');
    final body = jsonEncode({
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (statut != null) 'statut': Service.statutToString(statut),
    });

    final response = await http.put(
      url,
      headers: _headersWithOptionalToken(token),
      body: body,
    );

    if (response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      _throwApiError(response);
    }
  }

  /// Supprimer un service
  static Future<void> deleteService({String? token, required String id}) async {
    final url = Uri.parse('$UrlApi/deleteService/$id');
    final response = await http.delete(
      url,
      headers: _headersWithOptionalToken(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      _throwApiError(response);
    }
  }

  // Helper pour parser et lancer une exception lisible
  static Never _throwApiError(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body);
      final message = (jsonBody is Map && jsonBody['error'] != null) ? jsonBody['error'] : response.body;
      throw Exception('API Error (${response.statusCode}): $message');
    } catch (_) {
      throw Exception('API Error (${response.statusCode}): ${response.reasonPhrase ?? 'Unknown error'}');
    }
  }
}
