// lib/services/carnet_entretien_api.dart
import 'dart:convert';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/global.dart';

class CarnetEntretienApi {
  static const _jsonHeader = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper pour parser la réponse et détecter HTML / JSON invalide
  static dynamic _safeDecodeResponse(http.Response response) {
    final ct = response.headers['content-type'] ?? '';
    final body = response.body ?? '';

    // debug minimal
    print('API RESPONSE status=${response.statusCode} content-type=$ct');
    if (body.length > 200) {
      print('API RESPONSE body (head): ${body.substring(0, 200)}...');
    } else {
      print('API RESPONSE body: $body');
    }

    // heuristique: si content-type dit HTML ou body commence par <!DOCTYPE ou <html
    final trimmed = body.trimLeft();
    if (ct.toLowerCase().contains('text/html') ||
        trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html')) {
      throw Exception(
        'Serveur a renvoyé du HTML au lieu de JSON (status ${response.statusCode}). '
        'Réponse (début): ${trimmed.substring(0, trimmed.length > 200 ? 200 : trimmed.length)}',
      );
    }

    // tenter jsonDecode et attraper FormatException
    try {
      return jsonDecode(body);
    } on FormatException catch (e) {
      throw Exception(
        'JSON invalide du serveur: ${e.message}. Réponse (début): ${trimmed.substring(0, trimmed.length > 200 ? 200 : trimmed.length)}',
      );
    }
  }

  static Future<Map<String, dynamic>> getCarnetByVehiculeId(String token, String vehiculeId) async {
    final url = Uri.parse('$UrlApi/carnet-entretien/vehicule/$vehiculeId');
    final response = await http.get(url, headers: {..._jsonHeader, 'Authorization': 'Bearer $token'});

    final body = _safeDecodeResponse(response);

    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      final vehJson = body['vehicule'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final rawHist = body['historique'] as List<dynamic>? ?? [];

      final historique = rawHist.map<CarnetEntretien>((item) {
        if (item is Map<String, dynamic>) {
          if (item['source'] == 'carnet' ||
              (item.containsKey('dateCommencement') && item.containsKey('totalTTC'))) {
            return CarnetEntretien.fromJson(item);
          } else {
            return _ordreToCarnetEntretien(item);
          }
        } else {
          return CarnetEntretien(
            id: null,
            vehiculeId: vehiculeId,
            dateCommencement: DateTime.now(),
            totalTTC: 0.0,
            services: [],
            pieces: [],
          );
        }
      }).toList();

      return {
        'vehicule': Vehicule.fromJson(vehJson),
        'historique': historique,
      };
    } else {
      String errorMsg = 'Erreur lors de la récupération du carnet (code ${response.statusCode})';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  static CarnetEntretien _ordreToCarnetEntretien(Map<String, dynamic> json) {
    List<dynamic>? tachesRaw = json['taches'] as List<dynamic>?;
    final services = (tachesRaw ?? []).map<ServiceEntretien>((tache) {
      if (tache is Map<String, dynamic>) {
        return ServiceEntretien(
          nom: (tache['description'] ?? tache['nom'] ?? '').toString(),
          description: tache['serviceNom']?.toString(),
          quantite: (tache['quantite'] as int?) ?? (tache['quantity'] as int?) ?? 1,
          prix: (tache['prix'] as num?)?.toDouble() ?? (tache['price'] as num?)?.toDouble(),
        );
      } else {
        return ServiceEntretien(nom: tache?.toString() ?? '', description: null);
      }
    }).toList();

    return CarnetEntretien(
      id: json['_id']?.toString(),
      vehiculeId: json['vehiculeId']?.toString() ?? '',
      devisId: json['devisInfo'] is Map ? (json['devisInfo']['id']?.toString()) : json['devisInfo']?.toString(),
      dateCommencement: json['dateCommencement'] != null
          ? DateTime.parse(json['dateCommencement'])
          : DateTime.now(),
      dateFinCompletion: json['dateFinReelle'] != null ? DateTime.parse(json['dateFinReelle']) : null,
      statut: CarnetStatus.termine,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      kilometrageEntretien: json['kilometrageEntretien'] is int ? json['kilometrageEntretien'] as int : (json['kilometrage'] as int?),
      notes: json['notes']?.toString() ?? (json['description']?.toString()),
      services: services,
      pieces: [],
      technicien: json['technicien']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  // static Future<Map<String, dynamic>> getStatistiques(String token, String vehiculeId) async {
  //   final url = Uri.parse('$UrlApi/carnet/$vehiculeId/stats');
  //   final response = await http.get(url, headers: {..._jsonHeader, 'Authorization': 'Bearer $token'});

  //   final body = _safeDecodeResponse(response);

  //   if (response.statusCode == 200 && body is Map<String, dynamic>) {
  //     final stats = (body['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  //     final evo = (stats['evolutionDepenses'] as List<dynamic>?) ?? [];
  //     return {
  //       'totalEntretiens': stats['totalEntretiens'] ?? 0,
  //       'totalDepense': (stats['totalDepense'] as num?)?.toDouble() ?? 0.0,
  //       'moyenneParEntretien': (stats['moyenneParEntretien'] as num?)?.toDouble() ?? 0.0,
  //       'dernierEntretien': stats['dernierEntretien'] != null ? DateTime.tryParse(stats['dernierEntretien'].toString()) : null,
  //       'prochainEntretien': stats['prochainEntretien'] != null ? DateTime.tryParse(stats['prochainEntretien'].toString()) : null,
  //       'repartitionParType': stats['repartitionParType'] ?? {},
  //       'evolutionDepenses': evo.map((e) {
  //         try {
  //           return {
  //             'date': DateTime.parse(e['date'].toString()),
  //             'montant': (e['montant'] as num?)?.toDouble() ?? 0.0,
  //           };
  //         } catch (_) {
  //           return {'date': null, 'montant': 0.0};
  //         }
  //       }).toList(),
  //     };
  //   } else {
  //     String errorMsg = 'Erreur lors du calcul des statistiques (code ${response.statusCode})';
  //     if (body is Map && (body['error'] ?? body['message']) != null) {
  //       errorMsg = (body['error'] ?? body['message']).toString();
  //     }
  //     throw Exception(errorMsg);
  //   }
  // }

  static Future<CarnetEntretien> updateCarnet({
    required String token,
    required String carnetId,
    required Map<String, dynamic> updates,
  }) async {
    final url = Uri.parse('$UrlApi/carnet/$carnetId');
    print('=== [DEBUG updateCarnet] URL: $url');
    final response = await http.put(
      url,
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode(updates),
    );

    final body = _safeDecodeResponse(response);

    if ((response.statusCode == 200 || response.statusCode == 201) && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la mise à jour du carnet (code ${response.statusCode})';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  static Future<CarnetEntretien> creerCarnetManuel({
    required String token,
    required String vehiculeId,
    required DateTime date,
    required List<ServiceEntretien> taches,
    required double cout,
    String? notes,
  }) async {
    final url = Uri.parse('$UrlApi/creer-manuel');

    final requestBody = {
      'vehiculeId': vehiculeId,
      'date': date.toIso8601String(),
      'taches': taches.map((t) => t.toJson()).toList(),
      'cout': cout,
      'notes': notes,
    }..removeWhere((k, v) => v == null);

    print('=== [DEBUG creerCarnetManuel] URL: $url Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      url,
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode(requestBody),
    );

    final body = _safeDecodeResponse(response);

    if (response.statusCode == 201 && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la création du carnet (code ${response.statusCode})';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  static Future<CarnetEntretien> creerDepuisDevis(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/carnet/devis/$devisId');
    final response = await http.post(url, headers: {..._jsonHeader, 'Authorization': 'Bearer $token'});

    final body = _safeDecodeResponse(response);

    if (response.statusCode == 201 && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la création du carnet depuis devis (code ${response.statusCode})';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  static Future<CarnetEntretien> marquerTermine({
    required String token,
    required String carnetId,
    DateTime? dateFinCompletion,
    int? kilometrageEntretien,
    String? notes,
  }) async {
    final url = Uri.parse('$UrlApi/carnet/$carnetId/complete');
    final response = await http.put(
      url,
      headers: {..._jsonHeader, 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'dateFinCompletion': dateFinCompletion?.toIso8601String(),
        'kilometrageEntretien': kilometrageEntretien,
        'notes': notes,
      }..removeWhere((k, v) => v == null)),
    );

    final body = _safeDecodeResponse(response);
    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la mise à jour du carnet (code ${response.statusCode})';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  static Future<void> deleteCarnet(String token, String carnetId) async {
    final url = Uri.parse('$UrlApi/carnet/$carnetId');
    final response = await http.delete(url, headers: {..._jsonHeader, 'Authorization': 'Bearer $token'});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    // try decode for message
    try {
      final body = _safeDecodeResponse(response);
      if (body is Map && (body['error'] ?? body['message']) != null) {
        throw Exception((body['error'] ?? body['message']).toString());
      }
    } catch (_) {
      // si decode a échoué, tombera plus bas avec code d'erreur
    }

    throw Exception('Erreur lors de la suppression du carnet (code ${response.statusCode})');
  }
}
