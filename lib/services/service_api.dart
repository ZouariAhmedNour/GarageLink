import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/service.dart';
import 'package:garagelink/global.dart'; 

class ServiceApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer tous les services
  static Future<List<Service>> getAllServices(String token) async {
    final url = Uri.parse('$UrlApi/services');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Service.fromJson(json)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des services');
    }
  }

  /// Récupérer un service par ID
  static Future<Service> getServiceById(String token, String id) async {
    final url = Uri.parse('$UrlApi/services/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du service');
    }
  }

  /// Créer un nouveau service
  static Future<Service> createService({
    required String token,
    required String name,
    required String description,
    ServiceStatut? statut,
  }) async {
    final url = Uri.parse('$UrlApi/services');
    final body = jsonEncode({
      'name': name,
      'description': description,
      'statut': statut?.toString().split('.').last.replaceAll('actif', 'Actif').replaceAll('desactive', 'Désactivé'),
    }..removeWhere((key, value) => value == null));

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la création du service');
    }
  }

  /// Mettre à jour un service
  static Future<Service> updateService({
    required String token,
    required String id,
    String? name,
    String? description,
    ServiceStatut? statut,
  }) async {
    final url = Uri.parse('$UrlApi/services/$id');
    final body = jsonEncode({
      'name': name,
      'description': description,
      'statut': statut?.toString().split('.').last.replaceAll('actif', 'Actif').replaceAll('desactive', 'Désactivé'),
    }..removeWhere((key, value) => value == null));

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour du service');
    }
  }

  /// Supprimer un service
  static Future<void> deleteService(String token, String id) async {
    final url = Uri.parse('$UrlApi/services/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la suppression du service');
    }
  }
}