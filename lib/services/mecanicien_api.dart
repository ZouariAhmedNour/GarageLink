import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/global.dart'; // Importer la constante UrlApi

class MecanicienApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer tous les mécaniciens
  static Future<List<Mecanicien>> getAllMecaniciens(String token) async {
    final url = Uri.parse('$UrlApi/mecaniciens');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => Mecanicien.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des mécaniciens');
    }
  }

  /// Récupérer un mécanicien par ID
  static Future<Mecanicien> getMecanicienById(String token, String id) async {
    final url = Uri.parse('$UrlApi/mecaniciens/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Mecanicien.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du mécanicien');
    }
  }

  /// Récupérer les mécaniciens par service
  static Future<List<Mecanicien>> getMecaniciensByService(String token, String serviceId) async {
    final url = Uri.parse('$UrlApi/mecaniciens/by-service/$serviceId');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => Mecanicien.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des mécaniciens par service');
    }
  }

  /// Créer un nouveau mécanicien
  static Future<Mecanicien> createMecanicien({
    required String token,
    required String nom,
    required DateTime dateNaissance,
    required String telephone,
    required String email,
    required Poste poste,
    required DateTime dateEmbauche,
    required TypeContrat typeContrat,
    required Statut statut,
    required double salaire,
    required List<ServiceMecanicien> services,
    required String experience,
    required PermisConduire permisConduire,
  }) async {
    final url = Uri.parse('$UrlApi/mecaniciens');
    final mecanicien = Mecanicien(
      nom: nom,
      dateNaissance: dateNaissance,
      telephone: telephone,
      email: email,
      matricule: '', // Ignored by backend (auto-generated)
      poste: poste,
      dateEmbauche: dateEmbauche,
      typeContrat: typeContrat,
      statut: statut,
      salaire: salaire,
      services: services,
      experience: experience,
      permisConduire: permisConduire,
    );
    final body = jsonEncode(mecanicien.toJson()
      ..remove('_id')
      ..remove('matricule')
      ..remove('createdAt')
      ..remove('updatedAt'));

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Mecanicien.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la création du mécanicien');
    }
  }

  /// Mettre à jour un mécanicien
  static Future<Mecanicien> updateMecanicien({
    required String token,
    required String id,
    String? nom,
    DateTime? dateNaissance,
    String? telephone,
    String? email,
    Poste? poste,
    DateTime? dateEmbauche,
    TypeContrat? typeContrat,
    Statut? statut,
    double? salaire,
    List<ServiceMecanicien>? services,
    String? experience,
    PermisConduire? permisConduire,
  }) async {
    final url = Uri.parse('$UrlApi/mecaniciens/$id');
    final body = jsonEncode({
      if (nom != null) 'nom': nom,
      if (dateNaissance != null) 'dateNaissance': dateNaissance.toIso8601String(),
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (poste != null)
        'poste': poste.toString().split('.').last.replaceAll('mecanicien', 'Mécanicien').replaceAll('electricienAuto', 'Électricien Auto').replaceAll('carrossier', 'Carrossier').replaceAll('chefDEquipe', 'Chef d\'équipe').replaceAll('apprenti', 'Apprenti'),
      if (dateEmbauche != null) 'dateEmbauche': dateEmbauche.toIso8601String(),
      if (typeContrat != null) 'typeContrat': typeContrat.toString().split('.').last.toUpperCase(),
      if (statut != null) 'statut': statut.toString().split('.').last.replaceAll('actif', 'Actif').replaceAll('conge', 'Congé').replaceAll('arretMaladie', 'Arrêt maladie').replaceAll('suspendu', 'Suspendu').replaceAll('demissionne', 'Démissionné'),
      if (salaire != null) 'salaire': salaire,
      if (services != null) 'services': services.map((service) => service.toJson()).toList(),
      if (experience != null) 'experience': experience,
      if (permisConduire != null) 'permisConduire': permisConduire.toString().split('.').last.toUpperCase(),
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Mecanicien.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour du mécanicien');
    }
  }

  /// Supprimer un mécanicien
  static Future<void> deleteMecanicien(String token, String id) async {
    final url = Uri.parse('$UrlApi/mecaniciens/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la suppression du mécanicien');
    }
  }
}