// lib/services/cite_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global.dart';
import '../models/city.dart';

class CiteApi {
  final Duration _timeout = const Duration(seconds: 8);

  /// Récupère les villes/délégations pour un gouvernorat donné
  /// Retourne { success: true, data: List<City> } ou { success:false, message: ... }
  Future<Map<String, dynamic>> getCities(String governorateId) async {
    final uri = Uri.parse('$UrlApi/api/cities/$governorateId');
    try {
      final res = await http.get(uri, headers: {"Content-Type": "application/json"}).timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          final list = decoded.map((e) {
            try {
              return City.fromMap(Map<String, dynamic>.from(e));
            } catch (_) {
              return City(id: e['_id']?.toString() ?? '', name: e['name'] ?? '', nameAr: e['nameAr']);
            }
          }).toList();
          return {"success": true, "data": list};
        } else {
          return {"success": false, "message": "Format inattendu reçu du serveur"};
        }
      } else {
        return {"success": false, "message": "Erreur serveur (${res.statusCode})", "statusCode": res.statusCode};
      }
    } catch (e) {
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }
}
