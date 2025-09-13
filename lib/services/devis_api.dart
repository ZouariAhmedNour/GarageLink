// lib/services/devis_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/devis.dart';

class DevisApi {
  final String baseUrl;
  DevisApi({required this.baseUrl});

  Map<String, String> getHeaders([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<Map<String, dynamic>> createDevis(Map<String, dynamic> payload, {String? token}) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/createdevis'),
          headers: getHeaders(token), body: jsonEncode(payload));
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = body?['data'] ?? body;
        final devis = data is Map ? Devis.fromJson(Map<String, dynamic>.from(data)) : null;
        return {'success': true, 'data': devis, 'raw': body};
      }
      return {'success': false, 'message': 'Erreur création: ${res.statusCode}', 'raw': body ?? res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAllDevis({Map<String, String>? query, String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl/Devis').replace(queryParameters: query);
      final res = await http.get(uri, headers: getHeaders(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
        final devisList = list.map((e) => Devis.fromJson(Map<String, dynamic>.from(e))).toList();
        return {'success': true, 'data': devisList};
      }
      return {'success': false, 'message': 'Erreur HTTP ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDevisById(String id, {String? token}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/Devis/$id'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final d = Devis.fromJson(Map<String, dynamic>.from(body));
        return {'success': true, 'data': d};
      }
      return {'success': false, 'message': 'Not found ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Recherche par numéro DEV###:
  Future<Map<String, dynamic>> getDevisByNum(String num, {String? token}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/devis/code/$num'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // body may include {devis, ordres}
        final dRaw = body['devis'] ?? body;
        final d = dRaw != null ? Devis.fromJson(Map<String, dynamic>.from(dRaw)) : null;
        return {'success': true, 'data': d, 'raw': body};
      }
      return {'success': false, 'message': 'Not found ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateDevis(String id, Map<String, dynamic> updateData, {String? token}) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/Devis/$id'),
          headers: getHeaders(token), body: jsonEncode(updateData));
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (res.statusCode == 200) {
        final data = body is Map && body['data'] != null ? body['data'] : body;
        final d = data != null ? Devis.fromJson(Map<String, dynamic>.from(data)) : null;
        return {'success': true, 'data': d};
      }
      return {'success': false, 'message': 'Erreur mise à jour ${res.statusCode}', 'raw': body ?? res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteDevis(String id, {String? token}) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/Devis/$id'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
        return {'success': true, 'message': body?['message'] ?? 'Supprimé'};
      }
      return {'success': false, 'message': 'Erreur suppression ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // endpoints qui renvoient une page HTML (accept/refuse) — on les appelle si besoin
  Future<Map<String, dynamic>> acceptDevis(String devisId, {String? token}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/devis/$devisId/accept'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Devis accepté', 'html': res.body};
      }
      return {'success': false, 'message': 'Erreur accept ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> refuseDevis(String devisId, {String? token}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/devis/$devisId/refuse'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Devis refusé', 'html': res.body};
      }
      return {'success': false, 'message': 'Erreur refuse ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // envoyer un devis par email (route: POST /devis/:devisId/send-email) — auth required in backend
  Future<Map<String, dynamic>> sendDevisByEmail(String devisId, {Map<String, dynamic>? body, String? token}) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/devis/$devisId/send-email'),
          headers: getHeaders(token), body: jsonEncode(body ?? {}));
      final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': data, 'message': data?['message'] ?? 'Envoyé'};
      }
      return {'success': false, 'message': 'Erreur envoi ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
