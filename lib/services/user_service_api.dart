// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../global.dart';

class UserService {

  /// REGISTER
  Future<Map<String, dynamic>> register({
    required String username,
    required String garagenom,
    required String matriculefiscal,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      
      final uri = Uri.parse('$UrlApi/api/signup');
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "garagenom": garagenom,
          "matriculefiscal": matriculefiscal,
          "email": email,
          "password": password,
          "phone": phone,
        }),
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

  /// LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$UrlApi/api/login');
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
      final uri = Uri.parse('$UrlApi/api/profile');
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
      final uri = Uri.parse('$UrlApi/api/profile');
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
