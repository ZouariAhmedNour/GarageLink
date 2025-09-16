import 'dart:convert';
import 'package:garagelink/models/ficheClient.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/global.dart'; 

class FicheClientApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer toutes les fiches clients
  static Future<List<FicheClient>> getFicheClients(String token) async {
    final url = Uri.parse('$UrlApi/ficheClients');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => FicheClient.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des fiches clients');
    }
  }

  /// Récupérer une fiche client par ID
  static Future<FicheClient> getFicheClientById(String token, String id) async {
    final url = Uri.parse('$UrlApi/ficheClients/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FicheClient.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de la fiche client');
    }
  }

  /// Récupérer les noms et types des clients
  static Future<List<FicheClientSummary>> getFicheClientNoms(String token) async {
    final url = Uri.parse('$UrlApi/ficheClients/noms');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json is List<dynamic>) {
        return json.map((item) => FicheClientSummary.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Réponse inattendue du serveur : liste attendue');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des noms des clients');
    }
  }

  /// Créer une nouvelle fiche client
  static Future<FicheClient> createFicheClient({
    required String token,
    required String nom,
    required ClientType type,
    required String adresse,
    required String telephone,
    required String email,
  }) async {
    final url = Uri.parse('$UrlApi/ficheClients');
    final fiche = FicheClient(
      nom: nom,
      type: type,
      adresse: adresse,
      telephone: telephone,
      email: email,
    );
    final body = jsonEncode(fiche.toJson()..remove('_id'));

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FicheClient.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la création de la fiche client');
    }
  }

  /// Mettre à jour une fiche client
  static Future<FicheClient> updateFicheClient({
    required String token,
    required String id,
    String? nom,
    ClientType? type,
    String? adresse,
    String? telephone,
    String? email,
  }) async {
    final url = Uri.parse('$UrlApi/ficheClients/$id');
    final body = jsonEncode({
      if (nom != null) 'nom': nom,
      if (type != null) 'type': type == ClientType.particulier ? 'particulier' : 'professionnel',
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FicheClient.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour de la fiche client');
    }
  }

  /// Supprimer une fiche client
  static Future<void> deleteFicheClient(String token, String id) async {
    final url = Uri.parse('$UrlApi/ficheClients/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la suppression de la fiche client');
    }
  }

  /// Récupérer l'historique des visites d'un client
  static Future<HistoriqueVisiteResponse> getHistoriqueVisiteByIdClient(String token, String clientId) async {
    final url = Uri.parse('$UrlApi/ficheClients/$clientId/historique');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return HistoriqueVisiteResponse.fromJson(json);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de l\'historique des visites');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de l\'historique des visites');
    }
  }

  /// Récupérer un résumé des visites d'un client
  static Future<HistoryVisiteResponse> getHistoryVisite(String token, String clientId) async {
    final url = Uri.parse('$UrlApi/ficheClients/$clientId/history');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return HistoryVisiteResponse.fromJson(json);
      }
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du résumé des visites');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du résumé des visites');
    }
  }
}

// Modèle pour le résumé des noms et types des clients
class FicheClientSummary {
  final String id;
  final String nom;
  final ClientType type;

  FicheClientSummary({
    required this.id,
    required this.nom,
    required this.type,
  });

  factory FicheClientSummary.fromJson(Map<String, dynamic> json) {
    return FicheClientSummary(
      id: json['_id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      type: json['type'] == 'particulier' ? ClientType.particulier : ClientType.professionnel,
    );
  }
}

// Modèle pour une tâche dans l'historique des visites
class VisiteTache {
  final String description;
  final String service;
  final String mecanicien;
  final double heuresReelles;
  final String status;

  VisiteTache({
    required this.description,
    required this.service,
    required this.mecanicien,
    required this.heuresReelles,
    required this.status,
  });

  factory VisiteTache.fromJson(Map<String, dynamic> json) {
    return VisiteTache(
      description: json['description'] ?? '',
      service: json['service'] ?? '',
      mecanicien: json['mecanicien'] ?? '',
      heuresReelles: (json['heuresReelles'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
    );
  }
}

// Modèle pour une visite dans l'historique
class Visite {
  final String id;
  final String numeroOrdre;
  final DateTime? dateVisite;
  final String vehicule;
  final String atelier;
  final double dureeHeures;
  final List<VisiteTache> taches;
  final String servicesEffectues;

  Visite({
    required this.id,
    required this.numeroOrdre,
    this.dateVisite,
    required this.vehicule,
    required this.atelier,
    required this.dureeHeures,
    required this.taches,
    required this.servicesEffectues,
  });

  factory Visite.fromJson(Map<String, dynamic> json) {
    return Visite(
      id: json['id']?.toString() ?? '',
      numeroOrdre: json['numeroOrdre'] ?? '',
      dateVisite: json['dateVisite'] != null ? DateTime.parse(json['dateVisite']) : null,
      vehicule: json['vehicule'] ?? '',
      atelier: json['atelier'] ?? '',
      dureeHeures: (json['dureeHeures'] as num?)?.toDouble() ?? 0.0,
      taches: (json['taches'] as List<dynamic>?)
              ?.map((item) => VisiteTache.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      servicesEffectues: json['servicesEffectues'] ?? '',
    );
  }
}

// Modèle pour les statistiques de l'historique des visites
class VisiteStatistiques {
  final int nombreVisites;
  final DateTime? derniereVisite;
  final double totalHeuresTravail;
  final int servicesUniques;

  VisiteStatistiques({
    required this.nombreVisites,
    this.derniereVisite,
    required this.totalHeuresTravail,
    required this.servicesUniques,
  });

  factory VisiteStatistiques.fromJson(Map<String, dynamic> json) {
    return VisiteStatistiques(
      nombreVisites: json['nombreVisites'] ?? 0,
      derniereVisite: json['derniereVisite'] != null ? DateTime.parse(json['derniereVisite']) : null,
      totalHeuresTravail: (json['totalHeuresTravail'] as num?)?.toDouble() ?? 0.0,
      servicesUniques: json['servicesUniques'] ?? 0,
    );
  }
}

// Modèle pour la réponse de l'historique des visites
class HistoriqueVisiteResponse {
  final bool success;
  final FicheClientSummary client;
  final List<Visite> historiqueVisites;
  final VisiteStatistiques statistiques;

  HistoriqueVisiteResponse({
    required this.success,
    required this.client,
    required this.historiqueVisites,
    required this.statistiques,
  });

  factory HistoriqueVisiteResponse.fromJson(Map<String, dynamic> json) {
    return HistoriqueVisiteResponse(
      success: json['success'] ?? false,
      client: FicheClientSummary.fromJson(json['client'] as Map<String, dynamic>),
      historiqueVisites: (json['historiqueVisites'] as List<dynamic>?)
              ?.map((item) => Visite.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statistiques: VisiteStatistiques.fromJson(json['statistiques'] as Map<String, dynamic>),
    );
  }
}

// Modèle pour le résumé des visites
class HistoryVisiteResponse {
  final bool success;
  final int nombreVisites;
  final DateTime? derniereVisite;

  HistoryVisiteResponse({
    required this.success,
    required this.nombreVisites,
    this.derniereVisite,
  });

  factory HistoryVisiteResponse.fromJson(Map<String, dynamic> json) {
    return HistoryVisiteResponse(
      success: json['success'] ?? false,
      nombreVisites: json['nombreVisites'] ?? 0,
      derniereVisite: json['derniereVisite'] != null && json['derniereVisite']['date'] != null
          ? DateTime.parse(json['derniereVisite']['date'])
          : null,
    );
  }
}