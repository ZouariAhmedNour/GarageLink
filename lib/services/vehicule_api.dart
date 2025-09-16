import 'dart:convert';
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

  /// Récupérer tous les véhicules actifs
  static Future<List<Vehicule>> getAllVehicules(String token) async {
    final url = Uri.parse('$UrlApi/vehicules');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Vehicule.fromJson(json)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des véhicules');
    }
  }

  /// Récupérer un véhicule par ID
  static Future<Vehicule> getVehiculeById(String token, String id) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return Vehicule.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du véhicule');
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
    }..removeWhere((key, value) => value == null));

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      return Vehicule.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la création du véhicule');
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
    }..removeWhere((key, value) => value == null));

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      return Vehicule.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour du véhicule');
    }
  }

  /// Supprimer un véhicule (soft delete)
  static Future<void> deleteVehicule(String token, String id) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la suppression du véhicule');
    }
  }

  /// Récupérer les véhicules par propriétaire
  static Future<List<Vehicule>> getVehiculesByProprietaire(String token, String clientId) async {
    final url = Uri.parse('$UrlApi/vehicules/proprietaire/$clientId');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Vehicule.fromJson(json)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des véhicules du propriétaire');
    }
  }
}