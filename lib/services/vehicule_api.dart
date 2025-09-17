import 'dart:convert';
import 'dart:io';
import 'package:garagelink/global.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:http/http.dart' as http;

class VehiculeApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // Méthode utilitaire pour gestion d'erreurs
  static Exception _handleError(http.Response response) {
    String message;
    try {
      final json = jsonDecode(response.body);
      message = json['error'] ?? 'Erreur inconnue';
    } catch (_) {
      message = 'Erreur serveur (${response.statusCode})';
    }
    return Exception(message);
  }

  /// Récupérer tous les véhicules actifs
  static Future<List<Vehicule>> getAllVehicules(String token) async {
    final url = Uri.parse('$UrlApi/vehicules');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Vehicule.fromJson(json)).toList();
    } else {
      throw _handleError(response);
    }
  }

  /// Récupérer un véhicule par ID
  static Future<Vehicule> getVehiculeById(String token, String id) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return Vehicule.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  /// Créer un nouveau véhicule
  static Future<Vehicule> createVehicule({
    required String token,
    required String proprietaireId,
    required String marque,
    required String modele,
    required String immatriculation,
    int? annee,
    String? couleur,
    FuelType? typeCarburant,
    int? kilometrage,
    String? picKm,
    List<String>? images,
  }) async {
    final url = Uri.parse('$UrlApi/vehicules');
    final body = jsonEncode({
      'proprietaireId': proprietaireId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'annee': annee,
      'couleur': couleur,
      'typeCarburant': typeCarburant?.toString().split('.').last,
      'kilometrage': kilometrage,
      'picKm': picKm,
      'images': images,
    }..removeWhere((key, value) => value == null));

    final response =
        await http.post(url, headers: _authHeaders(token), body: body);

    if (response.statusCode == 201) {
      return Vehicule.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  /// Mettre à jour un véhicule
  static Future<Vehicule> updateVehicule({
    required String token,
    required String id,
    String? proprietaireId,
    String? marque,
    String? modele,
    String? immatriculation,
    int? annee,
    String? couleur,
    FuelType? typeCarburant,
    int? kilometrage,
    String? picKm,
    List<String>? images,
  }) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final body = jsonEncode({
      'proprietaireId': proprietaireId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'annee': annee,
      'couleur': couleur,
      'typeCarburant': typeCarburant?.toString().split('.').last,
      'kilometrage': kilometrage,
      'picKm': picKm,
      'images': images,
    }..removeWhere((key, value) => value == null));

    final response =
        await http.put(url, headers: _authHeaders(token), body: body);

    if (response.statusCode == 200) {
      return Vehicule.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  /// Supprimer un véhicule (soft delete)
  static Future<void> deleteVehicule(String token, String id) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final response = await http.delete(url, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  /// Récupérer les véhicules par propriétaire
  static Future<List<Vehicule>> getVehiculesByProprietaire(
      String token, String clientId) async {
    final url = Uri.parse('$UrlApi/vehicules/proprietaire/$clientId');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Vehicule.fromJson(json)).toList();
    } else {
      throw _handleError(response);
    }
  }

  /// (Optionnel) Upload d'une image principale pour un véhicule
  static Future<String> uploadVehiculeImage({
    required String token,
    required String vehiculeId,
    required File imageFile,
  }) async {
    final url = Uri.parse('$UrlApi/vehicules/$vehiculeId/upload');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('picKm', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['picKm']; // ✅ retourne l'URL de l’image
    } else {
      throw Exception('Erreur lors de l’upload de l’image');
    }
  }
}
