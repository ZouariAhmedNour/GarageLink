// gouvernorat_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/governorate.dart';
import 'package:garagelink/global.dart';

class GovernorateApi {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Avec auth (existant)
  static Future<List<Governorate>> getAllGovernorates(String token) async {
    final url = Uri.parse('$UrlApi/governorates');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is List<dynamic>) {
        return jsonBody.map((item) => Governorate.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des gouvernorats');
    }
  }

  /// Sans auth — pour l'écran d'inscription (nouveau)
  static Future<List<Governorate>> getAllGovernoratesPublic() async {
    final url = Uri.parse('$UrlApi/governorates');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is List<dynamic>) {
        return jsonBody.map((item) => Governorate.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des gouvernorats (public)');
    }
  }
}
