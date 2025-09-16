import 'dart:convert';
import 'package:garagelink/models/pieces.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/global.dart'; 

class PieceApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer toutes les pièces
  static Future<List<Piece>> getAllPieces(String token) async {
    final url = Uri.parse('$UrlApi/pieces');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Piece.fromJson(json)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des pièces');
    }
  }

  /// Récupérer une pièce par ID
  static Future<Piece> getPieceById(String token, String id) async {
    final url = Uri.parse('$UrlApi/pieces/$id');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return Piece.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération de la pièce');
    }
  }

  /// Créer une nouvelle pièce
  static Future<Piece> createPiece({
    required String token,
    required String name,
    required double prix,
  }) async {
    final url = Uri.parse('$UrlApi/pieces');
    final body = jsonEncode({
      'name': name,
      'prix': prix,
    });

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      return Piece.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la création de la pièce');
    }
  }

  /// Mettre à jour une pièce
  static Future<Piece> updatePiece({
    required String token,
    required String id,
    String? name,
    double? prix,
  }) async {
    final url = Uri.parse('$UrlApi/pieces/$id');
    final body = jsonEncode({
      'name': name,
      'prix': prix,
    }..removeWhere((key, value) => value == null));

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      return Piece.fromJson(jsonDecode(response.body));
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour de la pièce');
    }
  }

  /// Supprimer une pièce
  static Future<void> deletePiece(String token, String id) async {
    final url = Uri.parse('$UrlApi/pieces/$id');
    final response = await http.delete(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la suppression de la pièce');
    }
  }
}