// lib/services/mecanicien_api.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/global.dart'; // UrlApi

class MecanicienApi {
  // En-têtes par défaut
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Construire headers (token optionnel : passer '' ou null si pas d'auth)
  static Map<String, String> _buildHeaders(String? token) {
    if (token == null || token.isEmpty) return _defaultHeaders;
    return {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // Helpers pour convertir enums en valeurs attendues par le backend
  static String _formatPoste(Poste poste) {
    switch (poste) {
      case Poste.electricienAuto:
        return 'Électricien Auto';
      case Poste.carrossier:
        return 'Carrossier';
      case Poste.chefDEquipe:
        return 'Chef d\'équipe';
      case Poste.apprenti:
        return 'Apprenti';
      case Poste.mecanicien:
      return 'Mécanicien';
    }
  }

  static String _formatTypeContrat(TypeContrat t) {
    switch (t) {
      case TypeContrat.cdd:
        return 'CDD';
      case TypeContrat.stage:
        return 'Stage';
      case TypeContrat.apprentissage:
        return 'Apprentissage';
      case TypeContrat.cdi:
      return 'CDI';
    }
  }

  static String _formatStatut(Statut s) {
    switch (s) {
      case Statut.conge:
        return 'Congé';
      case Statut.arretMaladie:
        return 'Arrêt maladie';
      case Statut.suspendu:
        return 'Suspendu';
      case Statut.demissionne:
        return 'Démissionné';
      case Statut.actif:
      return 'Actif';
    }
  }

  static String _formatPermis(PermisConduire p) {
    return p.toString().split('.').last.toUpperCase();
  }

  /// Récupérer tous les mécaniciens
  static Future<List<Mecanicien>> getAllMecaniciens(String? token) async {
    final url = Uri.parse('$UrlApi/getAllMecaniciens');
    final response = await http.get(url, headers: _buildHeaders(token));

    if (response.statusCode == 200) {
      final body = response.body;
      final jsonData = body.isNotEmpty ? jsonDecode(body) : [];
      if (jsonData is List) {
        return jsonData
            .map((e) => Mecanicien.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final body = response.body;
      try {
        final err = jsonDecode(body) as Map<String, dynamic>;
        throw Exception(err['error'] ?? 'Erreur lors de la récupération des mécaniciens');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    }
  }

  /// Récupérer un mécanicien par ID
  static Future<Mecanicien> getMecanicienById(String? token, String id) async {
    final url = Uri.parse('$UrlApi/getMecanicienById/$id');
    final response = await http.get(url, headers: _buildHeaders(token));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Mecanicien.fromJson(jsonMap);
    } else {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['error'] ?? 'Erreur lors de la récupération du mécanicien');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    }
  }

  /// Récupérer les mécaniciens par service
  static Future<List<Mecanicien>> getMecaniciensByService(String? token, String serviceId) async {
    // backend route: /mecaniciens/by-service/:serviceId
    final url = Uri.parse('$UrlApi/mecaniciens/by-service/$serviceId');
    final response = await http.get(url, headers: _buildHeaders(token));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((e) => Mecanicien.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['error'] ?? 'Erreur lors de la récupération des mécaniciens par service');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    }
  }

  /// Créer un nouveau mécanicien
  static Future<Mecanicien> createMecanicien({
  required String? token,
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
  final url = Uri.parse('$UrlApi/createMecanicien');

  final Map<String, dynamic> payload = {
    'nom': nom,
    'dateNaissance': dateNaissance.toIso8601String(),
    'telephone': telephone,
    'email': email,
    'poste': _formatPoste(poste),
    'dateEmbauche': dateEmbauche.toIso8601String(),
    'typeContrat': _formatTypeContrat(typeContrat),
    'statut': _formatStatut(statut),
    'salaire': salaire,
    'services': services.map((s) => s.toJson()).toList(),
    'experience': experience,
    'permisConduire': _formatPermis(permisConduire),
  };

  // DEBUG: log request (temporaire)
  debugPrint('POST $url');
  debugPrint('Headers: ${_buildHeaders(token)}');
  debugPrint('Payload: ${jsonEncode(payload)}');

  http.Response response;
  try {
    response = await http.post(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(payload),
    );
  } catch (err) {
    // erreur réseau (ex: timeout, host unreachable)
    debugPrint('Network error during POST createMecanicien: $err');
    throw Exception('Erreur réseau: $err');
  }

  // Toujours logger la réponse
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  if (response.statusCode == 201) {
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return Mecanicien.fromJson(jsonMap);
  } else {
    // essayer d'extraire le message d'erreur du body (s'il est JSON { error: ... })
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = err['error'] ?? err['message'] ?? response.body;
      throw Exception('Serveur: $msg (status ${response.statusCode})');
    } catch (_) {
      // body non JSON ou champ non présent
      throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

  /// Mettre à jour un mécanicien
  static Future<Mecanicien> updateMecanicien({
    required String? token,
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
    final url = Uri.parse('$UrlApi/updateMecanicien/$id');

    final Map<String, dynamic> bodyMap = {
      if (nom != null) 'nom': nom,
      if (dateNaissance != null) 'dateNaissance': dateNaissance.toIso8601String(),
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (poste != null) 'poste': _formatPoste(poste),
      if (dateEmbauche != null) 'dateEmbauche': dateEmbauche.toIso8601String(),
      if (typeContrat != null) 'typeContrat': _formatTypeContrat(typeContrat),
      if (statut != null) 'statut': _formatStatut(statut),
      if (salaire != null) 'salaire': salaire,
      if (services != null) 'services': services.map((s) => s.toJson()).toList(),
      if (experience != null) 'experience': experience,
      if (permisConduire != null) 'permisConduire': _formatPermis(permisConduire),
    };

    final response = await http.put(
      url,
      headers: _buildHeaders(token),
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Mecanicien.fromJson(jsonMap);
    } else {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['error'] ?? 'Erreur lors de la mise à jour du mécanicien');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    }
  }

  /// Supprimer un mécanicien
  static Future<void> deleteMecanicien(String? token, String id) async {
    final url = Uri.parse('$UrlApi/deleteMecanicien/$id');
    final response = await http.delete(url, headers: _buildHeaders(token));

    if (response.statusCode == 200) {
      return;
    } else {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['error'] ?? 'Erreur lors de la suppression du mécanicien');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    }
  }
}
