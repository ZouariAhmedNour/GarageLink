// lib/services/cite_api.dart
import 'dart:convert';
import 'package:garagelink/models/cite.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/global.dart';

class CityApi {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  static Future<List<City>> getCitiesByGovernorate(String token, String governorateId) async {
    // <-- URL corrigée
    final url = Uri.parse('$UrlApi/cities/$governorateId');
    final response = await http.get(url, headers: _authHeaders(token));

    print('[CityApi] GET $url -> ${response.statusCode}');
    print('[CityApi] body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is List<dynamic>) {
        return jsonBody.map((item) => City.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      String err = 'Erreur ${response.statusCode}';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json.containsKey('error')) err = json['error'].toString();
      } catch (_) {}
      throw Exception('Erreur lors de la récupération des villes par gouvernorat: $err');
    }
  }

  static Future<List<City>> getCitiesByGovernoratePublic(String governorateId) async {
    // <-- URL corrigée
    final url = Uri.parse('$UrlApi/cities/$governorateId');
    final response = await http.get(url, headers: _headers);

    print('[CityApi:public] GET $url -> ${response.statusCode}');
    print('[CityApi:public] body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is List<dynamic>) {
        return jsonBody.map((item) => City.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      String err = 'Erreur ${response.statusCode}';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json.containsKey('error')) err = json['error'].toString();
      } catch (_) {}
      throw Exception('Erreur lors de la récupération des villes (public): $err');
    }
  }
}
