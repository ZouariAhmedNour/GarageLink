import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/global.dart'; // Importer la constante UrlApi

class FactureApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Créer une nouvelle facture à partir d'un devis
  static Future<Facture> createFacture({
    required String token,
    required String devisId,
  }) async {
    final url = Uri.parse('$UrlApi/factures/$devisId');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Facture.fromJson(json['facture'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la création de la facture');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la création de la facture');
    }
  }

  /// Récupérer toutes les factures avec pagination et filtres
  static Future<FacturePagination> getAllFactures({
    required String token,
    String? clientId,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 10,
    String sortBy = 'invoiceDate',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
      if (clientId != null) 'clientId': clientId,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
    final url = Uri.parse('$UrlApi/factures').replace(queryParameters: queryParams);
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return FacturePagination.fromJson(json);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la récupération des factures');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la récupération des factures');
    }
  }

  /// Récupérer une facture par ID
  static Future<Facture> getFactureById(String token, String id) async {
    final url = Uri.parse('$UrlApi/factures/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Facture.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la récupération de la facture');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la récupération de la facture');
    }
  }

  /// Récupérer une facture par devisId
  static Future<Facture?> getFactureByDevis(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/factures/by-devis/$devisId');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Facture.fromJson(json);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la récupération de la facture par devis');
    }
  }

  /// Marquer une facture comme payée
  static Future<Facture> marquerFacturePayed({
    required String token,
    required String id,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    DateTime? paymentDate,
  }) async {
    final url = Uri.parse('$UrlApi/factures/$id/pay');
    final body = jsonEncode({
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod.toString().split('.').last,
      if (paymentDate != null) 'paymentDate': paymentDate.toIso8601String(),
    });

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Facture.fromJson(json['facture'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de l\'enregistrement du paiement');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de l\'enregistrement du paiement');
    }
  }

  /// Mettre à jour une facture
  static Future<Facture> updateFacture({
    required String token,
    required String id,
    String? notes,
    DateTime? dueDate,
  }) async {
    final url = Uri.parse('$UrlApi/factures/$id');
    final body = jsonEncode({
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return Facture.fromJson(json['facture'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour de la facture');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la mise à jour de la facture');
    }
  }

  /// Supprimer une facture
  static Future<void> deleteFacture(String token, String id) async {
    final url = Uri.parse('$UrlApi/factures/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return;
      }
      throw Exception(json['message'] ?? 'Erreur lors de la suppression de la facture');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la suppression de la facture');
    }
  }

  /// Récupérer les statistiques des factures
  static Future<FactureStats> getFactureStats(String token) async {
    final url = Uri.parse('$UrlApi/factures/stats');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return FactureStats.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw Exception(json['message'] ?? 'Erreur lors de la récupération des statistiques');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }
}

// Modèle pour la réponse paginée des factures
class FacturePagination {
  final List<Facture> factures;
  final PaginationInfo pagination;

  FacturePagination({
    required this.factures,
    required this.pagination,
  });

  factory FacturePagination.fromJson(Map<String, dynamic> json) {
    return FacturePagination(
      factures: (json['data'] as List<dynamic>?)
              ?.map((item) => Facture.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

// Modèle pour les informations de pagination
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}

// Modèle pour les statistiques des factures
class FactureStats {
  final int totalFactures;
  final double totalTTC;
  final double totalPaye;
  final double totalPayePartiel;
  final double totalEncaisse;
  final double totalImpaye;
  final int facturesPayees;
  final int facturesEnRetard;
  final int facturesPartiellesPayees;
  final int facturesEnAttente;
  final double tauxPaiement;

  FactureStats({
    required this.totalFactures,
    required this.totalTTC,
    required this.totalPaye,
    required this.totalPayePartiel,
    required this.totalEncaisse,
    required this.totalImpaye,
    required this.facturesPayees,
    required this.facturesEnRetard,
    required this.facturesPartiellesPayees,
    required this.facturesEnAttente,
    required this.tauxPaiement,
  });

  factory FactureStats.fromJson(Map<String, dynamic> json) {
    return FactureStats(
      totalFactures: json['totalFactures'] ?? 0,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      totalPaye: (json['totalPaye'] as num?)?.toDouble() ?? 0.0,
      totalPayePartiel: (json['totalPayePartiel'] as num?)?.toDouble() ?? 0.0,
      totalEncaisse: (json['totalEncaisse'] as num?)?.toDouble() ?? 0.0,
      totalImpaye: (json['totalImpaye'] as num?)?.toDouble() ?? 0.0,
      facturesPayees: json['facturesPayees'] ?? 0,
      facturesEnRetard: json['facturesEnRetard'] ?? 0,
      facturesPartiellesPayees: json['facturesPartiellesPayees'] ?? 0,
      facturesEnAttente: json['facturesEnAttente'] ?? 0,
      tauxPaiement: (json['tauxPaiement'] as num?)?.toDouble() ?? 0.0,
    );
  }
}