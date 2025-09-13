import 'dart:convert';
import 'package:garagelink/models/pieceRechange.dart';
import 'package:http/http.dart' as http;

class PieceApi {
  final String baseUrl;
  PieceApi({required this.baseUrl});

  Map<String, String> getHeaders([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<Map<String, dynamic>> getAllPieces({String? token}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/pieces'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final pieces = list.map((e) => PieceRechange.fromJson(Map<String, dynamic>.from(e))).toList();
        return {'success': true, 'data': pieces};
      }
      return {'success': false, 'message': 'Erreur HTTP ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPieceById(String id, {String? token}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/pieces/$id'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': PieceRechange.fromJson(Map<String, dynamic>.from(data))};
      }
      return {'success': false, 'message': 'Erreur HTTP ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPiece(PieceRechange piece, {String? token}) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/pieces'),
          headers: getHeaders(token), body: jsonEncode(piece.toJson()));
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': PieceRechange.fromJson(Map<String, dynamic>.from(data))};
      }
      return {'success': false, 'message': 'Erreur création: ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePiece(String id, Map<String, dynamic> update, {String? token}) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/pieces/$id'),
          headers: getHeaders(token), body: jsonEncode(update));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': PieceRechange.fromJson(Map<String, dynamic>.from(data))};
      }
      return {'success': false, 'message': 'Erreur mise à jour: ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePiece(String id, {String? token}) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/pieces/$id'), headers: getHeaders(token));
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Pièce supprimée'};
      }
      return {'success': false, 'message': 'Erreur suppression: ${res.statusCode}', 'raw': res.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
