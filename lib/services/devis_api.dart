import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/global.dart'; // Importer la constante UrlApi

// Modèle pour OrdreTravail (simplifié, à ajuster selon le modèle backend)
class OrdreTravail {
  final String? id;
  final String devisId;
  final String? status;
  final DateTime? createdAt;

  OrdreTravail({
    this.id,
    required this.devisId,
    this.status,
    this.createdAt,
  });

  factory OrdreTravail.fromJson(Map<String, dynamic> json) {
    return OrdreTravail(
      id: json['_id']?.toString(),
      devisId: json['devisId']?.toString() ?? '',
      status: json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'devisId': devisId,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}

// Modèle pour la réponse de getDevisByNum
class DevisWithOrdres {
  final Devis devis;
  final List<OrdreTravail> ordres;

  DevisWithOrdres({
    required this.devis,
    required this.ordres,
  });

  factory DevisWithOrdres.fromJson(Map<String, dynamic> json) {
    return DevisWithOrdres(
      devis: Devis.fromJson(json['devis'] as Map<String, dynamic>),
      ordres: (json['ordres'] as List<dynamic>?)
              ?.map((item) => OrdreTravail.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DevisApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Créer un nouveau devis
  static Future<Devis> createDevis({
    required String token,
    required String clientId,
    required String clientName,
    required String vehicleInfo,
    required String vehiculeId,
    required String inspectionDate,
    required List<Service> services,
    double? tvaRate,
    double? maindoeuvre,
    required EstimatedTime estimatedTime,
  }) async {
    final url = Uri.parse('$UrlApi/devis');
    final body = jsonEncode({
      'clientId': clientId,
      'clientName': clientName,
      'vehicleInfo': vehicleInfo,
      'vehiculeId': vehiculeId,
      'inspectionDate': inspectionDate,
      'services': services.map((s) => s.toJson()).toList(),
      if (tvaRate != null) 'tvaRate': tvaRate,
      if (maindoeuvre != null) 'maindoeuvre': maindoeuvre,
      'estimatedTime': estimatedTime.toJson(),
    });

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Devis.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la création du devis');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la création du devis');
    }
  }

  /// Récupérer tous les devis avec filtres
  static Future<List<Devis>> getAllDevis({
    required String token,
    String? status,
    String? clientName,
    String? dateDebut,
    String? dateFin,
  }) async {
    final queryParams = {
      if (status != null && status != 'tous') 'status': status,
      if (clientName != null) 'clientName': clientName,
      if (dateDebut != null) 'dateDebut': dateDebut,
      if (dateFin != null) 'dateFin': dateFin,
    };
    final url = Uri.parse('$UrlApi/devis').replace(queryParameters: queryParams);
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return (json['data'] as List<dynamic>)
            .map((item) => Devis.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception(json['message'] ?? 'Erreur lors de la récupération des devis');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la récupération des devis');
    }
  }

  /// Récupérer un devis par ID (MongoDB _id ou custom id)
  static Future<Devis> getDevisById(String token, String id) async {
    final url = Uri.parse('$UrlApi/devis/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Devis.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du devis');
    }
  }

  /// Récupérer un devis par numéro (DEVxxx) avec ordres associés
  static Future<DevisWithOrdres> getDevisByNum(String token, String id) async {
    final url = Uri.parse('$UrlApi/devis/by-num/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return DevisWithOrdres.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['error'] ?? 'Erreur lors de la récupération du devis');
    }
  }

  /// Mettre à jour un devis
  static Future<Devis> updateDevis({
    required String token,
    required String id, // Custom ID (DEVxxx)
    String? clientId,
    String? clientName,
    String? vehicleInfo,
    String? inspectionDate,
    List<Service>? services,
    double? tvaRate,
    double? maindoeuvre,
    EstimatedTime? estimatedTime,
  }) async {
    final url = Uri.parse('$UrlApi/devis/$id');
    final body = jsonEncode({
      if (clientId != null) 'clientId': clientId,
      if (clientName != null) 'clientName': clientName,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      if (inspectionDate != null) 'inspectionDate': inspectionDate,
      if (services != null) 'services': services.map((s) => s.toJson()).toList(),
      if (tvaRate != null) 'tvaRate': tvaRate,
      if (maindoeuvre != null) 'maindoeuvre': maindoeuvre,
      if (estimatedTime != null) 'estimatedTime': estimatedTime.toJson(),
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Devis.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du devis');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du devis');
    }
  }

  /// Mettre à jour le factureId d'un devis
  static Future<Devis> updateFactureId({
    required String token,
    required String id, // MongoDB _id
    required String factureId,
  }) async {
    final url = Uri.parse('$UrlApi/devis/$id');
    final body = jsonEncode({
      'factureId': factureId,
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Devis.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du factureId');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du factureId');
    }
  }

  /// Supprimer un devis
  static Future<void> deleteDevis(String token, String id) async {
    final url = Uri.parse('$UrlApi/devis/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return;
      }
      throw Exception(json['message'] ?? 'Erreur lors de la suppression du devis');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la suppression du devis');
    }
  }

  /// Accepter un devis
  static Future<void> acceptDevis(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/devis/$devisId/accept');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Erreur lors de l\'acceptation du devis');
    }
  }

  /// Refuser un devis
  static Future<void> refuseDevis(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/devis/$devisId/refuse');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Erreur lors du refus du devis');
    }
  }

  /// Mettre à jour le statut d'un devis
  static Future<Devis> updateDevisStatus({
    required String token,
    required String id, // Custom ID (DEVxxx)
    required String status,
  }) async {
    final url = Uri.parse('$UrlApi/devis/$id/status');
    final body = jsonEncode({'status': status});

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Devis.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du statut');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour du statut');
    }
  }
}