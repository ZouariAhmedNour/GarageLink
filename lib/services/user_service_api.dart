// lib/services/user_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../global.dart';

class UserService {

  Future<Map<String, dynamic>> register({
  required String username,
  required String garagenom,
  required String matriculefiscal,
  required String email,
  required String password,
  required String phone,
  String? streetAddress,
  Map<String, dynamic>? location,
  String? governorateId,
  String? cityId,
}) async {
  try {
    final uri = Uri.parse('$UrlApi/signup'); // ton endpoint
    final Map<String, dynamic> body = {
  "username": username,
  "garagenom": garagenom,
  "matriculefiscal": matriculefiscal,
  "email": email,
  "password": password,
  "phone": phone,
};
    if (streetAddress != null) body['streetAddress'] = streetAddress;
    // IMPORTANT : NE PAS caster location en String — laisser comme Map pour jsonEncode()
    if (location != null) body['location'] = location;
    if (governorateId != null) body['governorateId'] = governorateId;
    if (cityId != null) body['cityId'] = cityId;

    if (kDebugMode) {
      debugPrint('[USER SERVICE] register body: ${jsonEncode(body)}');
    }

    final res = await http.post(uri,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));

    final statusOk = res.statusCode >= 200 && res.statusCode < 300;
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    if (statusOk) {
      // Normaliser la réponse pour toujours renvoyer un objet attendu
      // on enveloppe la réponse du serveur sous "data" afin d'éviter collisions
      return {
        "success": true,
        "data": decoded ?? {},
        // si le backend renvoie un message, l'exposer aussi
        "message": decoded is Map && decoded['message'] != null ? decoded['message'].toString() : 'OK'
      };
    } else {
      final serverMessage = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Erreur serveur ${res.statusCode}';
      return {"success": false, "message": serverMessage, "statusCode": res.statusCode};
    }
  } catch (e) {
    return {"success": false, "message": "Erreur: $e"};
  }
}

  // Récupérer tous les gouvernorats
  Future<Map<String, dynamic>> getGovernorates() async {
    try {
      final uri = Uri.parse('$UrlApi/governorates');
      final res = await http.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"success": true, "data": jsonDecode(res.body)};
      } else {
        return {"success": false, "message": "Erreur serveur"};
      }
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  // Récupérer villes par gouvernorat
  Future<Map<String, dynamic>> getCities(String governorateId) async {
    try {
      final uri = Uri.parse('$UrlApi/cities/$governorateId');
      final res = await http.get(uri);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"success": true, "data": jsonDecode(res.body)};
      } else {
        return {"success": false, "message": "Erreur serveur"};
      }
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  /// LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$UrlApi/login');
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"success": true, ...jsonDecode(res.body)};
      } else {
        return {"success": false, "message": jsonDecode(res.body)["message"]};
      }
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  /// GET PROFILE
  Future<UserModel?> getProfile(String token) async {
    try {
      final uri = Uri.parse('$UrlApi/profile');
      final res = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return UserModel.fromMap(jsonDecode(res.body));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// UPDATE PROFILE
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$UrlApi/profile');
      final res = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"success": true, ...jsonDecode(res.body)};
      } else {
        return {"success": false, "message": jsonDecode(res.body)["message"]};
      }
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  /// SAVE LOCATION
  Future<Map<String, dynamic>> saveLocation({
    required LatLng pos,
    required String token,
  }) async {
    final map = {
      "location": {
        "type": "Point",
        "coordinates": [pos.longitude, pos.latitude],
      },
    };
    return updateProfile(data: map, token: token);
  }
}
