import 'dart:convert';
import 'package:garagelink/models/cite.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/global.dart'; 

class CityApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer toutes les villes
  static Future<List<City>> getAllCities(String token) async {
    final url = Uri.parse('$UrlApi/cities');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => City.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des villes');
    }
  }

  /// Récupérer les villes par gouvernorat
  static Future<List<City>> getCitiesByGovernorate(String token, String governorateId) async {
    final url = Uri.parse('$UrlApi/cities/by-governorate/$governorateId');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => City.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des villes par gouvernorat');
    }
  }
}