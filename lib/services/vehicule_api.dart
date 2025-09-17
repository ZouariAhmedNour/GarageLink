// lib/services/vehicule_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:garagelink/global.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:http/http.dart' as http;

/// Service API pour les véhicules
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

  // ---- Utils ----

  /// Extrait un identifiant depuis différentes formes possibles envoyées par le serveur :
  /// - String '64f...'
  /// - Map { "_id": "..." } ou { "id": "..." }
  /// - Map { "_id": { "$oid": "..." } } (format extended JSON)
  static String _extractId(dynamic maybeId) {
    if (maybeId == null) return '';
    if (maybeId is String) return maybeId;
    if (maybeId is Map) {
      // extended JSON { "$oid": "..." }
      if (maybeId.containsKey(r'$oid')) {
        return maybeId[r'$oid']?.toString() ?? '';
      }
      // structure { "_id": ... }
      if (maybeId.containsKey('_id')) {
        final inner = maybeId['_id'];
        if (inner is String) return inner;
        if (inner is Map && inner.containsKey(r'$oid')) return inner[r'$oid']?.toString() ?? '';
        return inner?.toString() ?? '';
      }
      // fallback 'id'
      if (maybeId.containsKey('id')) return maybeId['id']?.toString() ?? '';
    }
    // fallback générique
    try {
      return maybeId.toString();
    } catch (_) {
      return '';
    }
  }

  /// Retourne une DateTime si possible depuis plusieurs formats (String ISO, Map { '$date': ... }, int timestamp, etc.)
  static DateTime? _extractDate(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is DateTime) return raw;
      if (raw is int) {
        // timestamp en ms
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
        final asInt = int.tryParse(raw);
        if (asInt != null) {
          // heuristique : si <= 10 chiffres => seconds
          if (raw.length <= 10) return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
          return DateTime.fromMillisecondsSinceEpoch(asInt);
        }
      }
      if (raw is Map) {
        // extended Mongo { "$date": "..." } ou { "$date": { "$numberLong": "..." } }
        if (raw.containsKey(r'$date')) {
          final d = raw[r'$date'];
          return _extractDate(d);
        }
        if (raw.containsKey(r'$numberLong')) {
          final asStr = raw[r'$numberLong']?.toString();
          if (asStr != null) {
            final asInt = int.tryParse(asStr);
            if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
          }
        }
        // try common fields
        if (raw.containsKey('createdAt')) return _extractDate(raw['createdAt']);
        if (raw.containsKey('updatedAt')) return _extractDate(raw['updatedAt']);
      }
    } catch (_) {}
    return null;
  }

  /// Normalise un item JSON reçu pour le mapping vers Vehicule.fromJson
  /// - garantit que proprietaireId est une string d'id
  /// - convertit createdAt/updatedAt en string ISO si possible
  static Map<String, dynamic> _normalizeVehiculeJson(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    if (raw is Map<String, dynamic>) {
      final m = Map<String, dynamic>.from(raw);

      // proprietaireId peut être string, objet peuplé, ou absent
      dynamic prop = m['proprietaireId'] ?? m['proprietaire'] ?? m['owner'] ?? m['proprietaireObj'];
      final pid = _extractId(prop);
      m['proprietaireId'] = pid;

      // parfois le serveur renvoie le _id en tant qu'objet
      if (m.containsKey('_id') && !(m['_id'] is String)) {
        m['_id'] = _extractId(m['_id']);
      }

      // normaliser dates en string ISO (Vehicule.fromJson appelle DateTime.parse)
      try {
        final ca = _extractDate(m['createdAt']);
        if (ca != null) m['createdAt'] = ca.toIso8601String();
      } catch (_) {}
      try {
        final ua = _extractDate(m['updatedAt']);
        if (ua != null) m['updatedAt'] = ua.toIso8601String();
      } catch (_) {}

      // s'assurer que images est une liste de string
      final imgs = m['images'];
      if (imgs is List) {
        m['images'] = imgs.map((e) => e?.toString() ?? '').toList();
      } else if (imgs == null) {
        m['images'] = <String>[];
      }

      return m;
    }

    // si raw est une string (improbable) -> retourne map vide
    return <String, dynamic>{};
  }

  /// Normalise la réponse qui peut être:
  /// - une liste JSON
  /// - un objet { data: [...] } ou { vehicules: [...] }
  /// - un seul objet (on renverra une liste d'un seul élément)
  static List<dynamic> _extractListFromResponse(dynamic decoded) {
    if (decoded == null) return [];
    if (decoded is List) return decoded;
    if (decoded is Map) {
      // chercher champs usuels contenant la liste
      for (final key in ['data', 'vehicules', 'items', 'list']) {
        if (decoded.containsKey(key) && decoded[key] is List) return decoded[key] as List<dynamic>;
      }
      // si c'est un objet unique, on le retourne en liste d'un élément
      return [decoded];
    }
    return [];
  }

  // ---- Gestion d'erreurs ----
  static Exception _handleError(http.Response response) {
    String message;
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['error'] != null) {
        message = json['error'].toString();
      } else if (json is Map && json['message'] != null) {
        message = json['message'].toString();
      } else {
        message = 'Erreur serveur (${response.statusCode})';
      }
    } catch (_) {
      message = 'Erreur serveur (${response.statusCode})';
    }
    return Exception(message);
  }

  // ---- API calls ----

  /// Récupérer tous les véhicules actifs
  static Future<List<Vehicule>> getAllVehicules(String token) async {
    final url = Uri.parse('$UrlApi/vehicules');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = _extractListFromResponse(decoded);
      return list.map((e) => Vehicule.fromJson(_normalizeVehiculeJson(e))).toList();
    } else {
      throw _handleError(response);
    }
  }

  /// Récupérer un véhicule par ID
  static Future<Vehicule> getVehiculeById(String token, String id) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      // si le serveur renvoie { data: { ... } }
      if (raw is Map && raw.containsKey('data')) {
        return Vehicule.fromJson(_normalizeVehiculeJson(raw['data']));
      }
      return Vehicule.fromJson(_normalizeVehiculeJson(raw));
    } else {
      throw _handleError(response);
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
    String? picKm,
    List<String>? images,
  }) async {
    final url = Uri.parse('$UrlApi/vehicules');

    // normalisation côté client : immatriculation en upper-case sans espaces superflus
    final String immatNormalized = immatriculation.toUpperCase().trim();

    final body = jsonEncode({
      'proprietaireId': proprietaireId,
      'marque': marque.trim(),
      'modele': modele.trim(),
      'immatriculation': immatNormalized,
      'annee': annee,
      'couleur': couleur?.trim(),
      'typeCarburant': typeCarburant?.toString().split('.').last,
      'kilometrage': kilometrage,
      'picKm': picKm,
      'images': images,
    }..removeWhere((key, value) => value == null));

    final response = await http.post(url, headers: _authHeaders(token), body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      // serveur peut renvoyer le véhicule directement ou { data: vehicule }
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return Vehicule.fromJson(_normalizeVehiculeJson(data));
    } else {
      throw _handleError(response);
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
    String? picKm,
    List<String>? images,
  }) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');

    final String? immatNormalized = immatriculation != null ? immatriculation.toUpperCase().trim() : null;

    final body = jsonEncode({
      if (proprietaireId != null) 'proprietaireId': proprietaireId,
      if (marque != null) 'marque': marque.trim(),
      if (modele != null) 'modele': modele.trim(),
      if (immatNormalized != null) 'immatriculation': immatNormalized,
      if (annee != null) 'annee': annee,
      if (couleur != null) 'couleur': couleur.trim(),
      if (typeCarburant != null) 'typeCarburant': typeCarburant.toString().split('.').last,
      if (kilometrage != null) 'kilometrage': kilometrage,
      if (picKm != null) 'picKm': picKm,
      if (images != null) 'images': images,
    });

    final response = await http.put(url, headers: _authHeaders(token), body: body);

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return Vehicule.fromJson(_normalizeVehiculeJson(data));
    } else {
      throw _handleError(response);
    }
  }

  /// Supprimer un véhicule (soft delete)
  static Future<void> deleteVehicule(String token, String id) async {
    final url = Uri.parse('$UrlApi/vehicules/$id');
    final response = await http.delete(url, headers: _authHeaders(token));
    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  /// Récupérer les véhicules par propriétaire
  static Future<List<Vehicule>> getVehiculesByProprietaire(String token, String clientId) async {
    final url = Uri.parse('$UrlApi/vehicules/proprietaire/$clientId');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = _extractListFromResponse(decoded);
      return list.map((e) => Vehicule.fromJson(_normalizeVehiculeJson(e))).toList();
    } else {
      throw _handleError(response);
    }
  }

  /// Upload d'une image principale (optionnel — backend doit exposer la route)
  static Future<String> uploadVehiculeImage({
    required String token,
    required String vehiculeId,
    required File imageFile,
  }) async {
    final url = Uri.parse('$UrlApi/vehicules/$vehiculeId/upload');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('picKm', imageFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final raw = jsonDecode(response.body);
      if (raw is Map && raw['picKm'] != null) return raw['picKm'].toString();
      final normalized = _normalizeVehiculeJson(raw);
      return normalized['picKm']?.toString() ?? '';
    } else {
      throw _handleError(response);
    }
  }
}
