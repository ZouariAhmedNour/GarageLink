import 'dart:convert';
import 'package:garagelink/global.dart';
import 'package:garagelink/models/user.dart';
import 'package:http/http.dart' as http;


class UserApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Inscription d'un nouvel utilisateur
  static Future<User> register({
    required String username,
    required String garagenom,
    required String matriculefiscal,
    required String email,
    required String password,
    required String phone,
  }) async {
    final url = Uri.parse('$UrlApi/signup');
    final body = jsonEncode({
      'username': username,
      'garagenom': garagenom,
      'matriculefiscal': matriculefiscal,
      'email': email,
      'password': password,
      'phone': phone,
    });

    final response = await http.post(
      url,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return User(
        id: json['userId']?.toString(),
        username: username,
        garagenom: garagenom,
        matriculefiscal: matriculefiscal,
        email: email,
        phone: phone,
        isVerified: false,
      );
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de l\'inscription');
    }
  }

  /// Connexion d'un utilisateur
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$UrlApi/login');
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await http.post(
      url,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['token'] as String;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de la connexion');
    }
  }

  /// Vérification de l'email
  static Future<void> verifyEmail(String token) async {
    final url = Uri.parse('$UrlApi/verify-email/$token');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de la vérification de l\'email');
    }
  }

  /// Vérification du token JWT
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    final url = Uri.parse('$UrlApi/verify-token');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la vérification du token');
    }
  }

  /// Demande de réinitialisation de mot de passe
  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$UrlApi/forgot-password');
    final body = jsonEncode({'email': email});

    final response = await http.post(
      url,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de la demande de réinitialisation');
    }
  }

  /// Réinitialisation du mot de passe
  static Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$UrlApi/reset-password');
    final body = jsonEncode({
      'email': email,
      'token': token,
      'newPassword': newPassword,
    });

    final response = await http.post(
      url,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de la réinitialisation du mot de passe');
    }
  }

  /// Récupérer le profil utilisateur
 static Future<User> getProfile(String token) async {
  final url = Uri.parse('$UrlApi/get-profile');
  final response = await http.get(url, headers: _authHeaders(token));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return User.fromJson(json);
  } else if (response.statusCode == 401) {
    // tente de parser le corps (backend devrait envoyer { error: 'TokenExpired', message: '...' })
    try {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? json['error'] ?? 'Unauthorized');
    } catch (_) {
      throw Exception('Unauthorized');
    }
  } else {
    final json = jsonDecode(response.body);
    throw Exception(json['message'] ?? 'Erreur lors de la récupération du profil');
  }
}

  /// Mettre à jour le profil utilisateur
  static Future<User> completeProfile({
    required String token,
    required String username,
    required String garagenom,
    required String matriculefiscal,
    required String email,
    required String phone,
    required String governorateId,
    required String cityId,
    String? governorateName,
    String? cityName,
    String? streetAddress,
    Location? location,
  }) async {
    final url = Uri.parse('$UrlApi/complete-profile');
    final body = jsonEncode({
      'username': username,
      'garagenom': garagenom,
      'matriculefiscal': matriculefiscal,
      'email': email,
      'phone': phone,
      'governorateId': governorateId,
      'governorateName': governorateName,
      'cityId': cityId,
      'cityName': cityName,
      'streetAddress': streetAddress,
      'location': location?.toJson(),
    });

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return User.fromJson(json['user']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du profil');
    }
  }
}