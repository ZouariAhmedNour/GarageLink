import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/governorate.dart';
import 'package:garagelink/global.dart'; 

class GovernorateApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer tous les gouvernorats
  static Future<List<Governorate>> getAllGovernorates(String token) async {
    final url = Uri.parse('$UrlApi/governorates');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => Governorate.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des gouvernorats');
    }
  }
}