// lib/services/chercher_garage_api.dart
import 'dart:convert';
import 'package:garagelink/global.dart';
import 'package:garagelink/models/user.dart';
import 'package:http/http.dart' as http;

/// Service pour consommer l'endpoint backend GET /search
/// Query params attendus : governorate, city, latitude, longitude, radius (m), search
class ChercherGarageApi {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// Retourne la liste de User.
  static Future<List<User>> searchGarages({
    String? governorate,
    String? city,
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? search,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final res = await searchGaragesWithMeta(
      governorate: governorate,
      city: city,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      search: search,
      timeout: timeout,
    );

    final List<dynamic> rawGarages = res['garages'] as List<dynamic>? ?? <dynamic>[];
    return rawGarages
        .map((j) => User.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Retourne la réponse complète (pour debug): { success, count, garages, debug, raw }
  static Future<Map<String, dynamic>> searchGaragesWithMeta({
    String? governorate,
    String? city,
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? search,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final Map<String, String> params = {};
      if (governorate != null && governorate.isNotEmpty) params['governorate'] = governorate;
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (latitude != null && longitude != null) {
        params['latitude'] = latitude.toString();
        params['longitude'] = longitude.toString();
      }
      // backend attend radius en mètres
      final int radiusMeters = (radiusKm * 1000).round();
      params['radius'] = radiusMeters.toString();

      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('$UrlApi/search').replace(queryParameters: params);

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final dynamic parsed = jsonDecode(response.body);

        // Cas 1: backend renvoie { success: true, count, garages: [...] }
        if (parsed is Map<String, dynamic>) {
          final garages = parsed['garages'] as List<dynamic>? ?? <dynamic>[];
          final count = parsed['count'] ?? garages.length;
          final debug = parsed['debug'];
          return {
            'success': parsed['success'] ?? true,
            'count': count,
            'garages': garages,
            'debug': debug,
            'raw': parsed,
          };
        }

        // Cas 2: backend renvoie directement un array [...users...]
        if (parsed is List<dynamic>) {
          return {
            'success': true,
            'count': parsed.length,
            'garages': parsed,
            'debug': null,
            'raw': parsed,
          };
        }

        // Cas inattendu
        throw Exception('Réponse inattendue du serveur');
      } else {
        String message = 'Erreur ${response.statusCode}';
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['message'] != null) message = parsed['message'];
        } catch (_) {}
        throw Exception('Recherche échouée: $message');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
