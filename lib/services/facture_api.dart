// lib/services/facture_api.dart
import 'dart:convert';
import 'package:garagelink/global.dart';
import 'package:http/http.dart' as http;
import '../models/facture.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class FactureApi {
  // Base URL construit à partir de ton UrlApi global.
  // Remplace 'api/factures' si tu montes ton router ailleurs.
  final String baseUrl = '$UrlApi/api/factures';
  final String? token;

  FactureApi({this.token});

  Map<String, String> _defaultHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final full = '$baseUrl$path';
    if (query == null) return Uri.parse(full);
    return Uri.parse(full).replace(queryParameters: query.map((k, v) => MapEntry(k, v?.toString() ?? '')));
  }

  // CREATE facture from devisId
  Future<Facture> createFacture(String devisId) async {
    final url = _uri('/create/$devisId');
    final res = await http.post(url, headers: _defaultHeaders());
    if (res.statusCode == 201 || res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final factureJson = body['facture'] ?? body['data'] ?? body;
      return Facture.fromJson(factureJson as Map<String, dynamic>);
    }
    throw ApiException('Erreur création facture: ${res.body}', res.statusCode);
  }

  // GET all factures (avec filtres / pagination)
  Future<Map<String, dynamic>> getFactures({
    String? clientId,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 10,
    String sortBy = 'invoiceDate',
    String sortOrder = 'desc',
  }) async {
    final query = <String, dynamic>{
      if (clientId != null) 'clientId': clientId,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    final url = _uri('/getFactures', query);
    final res = await http.get(url, headers: _defaultHeaders());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> data = body['data'] ?? [];
      final factures = data.map((e) => Facture.fromJson(e as Map<String, dynamic>)).toList();
      return {
        'factures': factures,
        'pagination': body['pagination'] ?? {},
      };
    }
    throw ApiException('Erreur récupération factures: ${res.body}', res.statusCode);
  }

  // GET facture by id
  Future<Facture> getFactureById(String id) async {
    final url = _uri('/getFacture/$id');
    final res = await http.get(url, headers: _defaultHeaders());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return Facture.fromJson(data as Map<String, dynamic>);
    }
    throw ApiException('Erreur récupération facture: ${res.body}', res.statusCode);
  }

  // GET facture by devisId
  Future<Facture?> getFactureByDevis(String devisId) async {
    final url = _uri('/factureByDevis/$devisId');
    final res = await http.get(url, headers: _defaultHeaders());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return Facture.fromJson(body as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      return null;
    }
    throw ApiException('Erreur récupération facture par devis: ${res.body}', res.statusCode);
  }

  // MARK AS PAID
  Future<Facture> markAsPaid({
    required String factureId,
    required double paymentAmount,
    required String paymentMethod,
    DateTime? paymentDate,
  }) async {
    final url = _uri('/$factureId/payment');
    final body = {
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      if (paymentDate != null) 'paymentDate': paymentDate.toIso8601String(),
    };
    final res = await http.put(url, headers: _defaultHeaders(), body: jsonEncode(body));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final factureJson = data['facture'] ?? data['data'] ?? data;
      return Facture.fromJson(factureJson as Map<String, dynamic>);
    }
    throw ApiException('Erreur enregistrement paiement: ${res.body}', res.statusCode);
  }

  // UPDATE facture (notes, dueDate)
  Future<Facture> updateFacture({
    required String factureId,
    String? notes,
    DateTime? dueDate,
  }) async {
    final url = _uri('/$factureId');
    final body = {
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    };
    final res = await http.put(url, headers: _defaultHeaders(), body: jsonEncode(body));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final factureJson = data['facture'] ?? data['data'] ?? data;
      return Facture.fromJson(factureJson as Map<String, dynamic>);
    }
    throw ApiException('Erreur mise à jour facture: ${res.body}', res.statusCode);
  }

  // DELETE fact
}