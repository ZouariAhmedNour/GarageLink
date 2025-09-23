// lib/services/carnet_entretien_api.dart
import 'dart:convert';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/global.dart';

class CarnetEntretienApi {
  /// Retrieves the maintenance history for a vehicle
  static Future<Map<String, dynamic>> getCarnetByVehiculeId(String token, String vehiculeId) async {
    final url = Uri.parse('$UrlApi/carnet-entretien/vehicule/$vehiculeId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    try {
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        final vehJson = body['vehicule'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final rawHist = body['historique'] as List<dynamic>? ?? [];

        final historique = rawHist.map<CarnetEntretien>((item) {
          if (item is Map<String, dynamic>) {
            // si l'item provient directement d'un carnet (source indiqué ou shape de carnet)
            if (item['source'] == 'carnet' ||
                // heuristique: contient des clés typiques d'un carnet
                (item.containsKey('dateCommencement') && item.containsKey('totalTTC'))) {
              return CarnetEntretien.fromJson(item);
            } else {
              // sinon on tente la conversion depuis un ordre de travail
              return _ordreToCarnetEntretien(item);
            }
          } else {
            // fallback vide si format inattendu
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
        // try to extract error message
        String errorMsg = 'Erreur lors de la récupération du carnet';
        if (body is Map && body['error'] != null) {
          errorMsg = body['error'].toString();
        } else if (body is Map && body['message'] != null) {
          errorMsg = body['message'].toString();
        } else if (response.reasonPhrase != null) {
          errorMsg = response.reasonPhrase!;
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      // Rejette avec message lisible
      throw Exception('Erreur parsing carnet: ${e.toString()}');
    }
  }

  /// Converts an OrdreTravail JSON to a CarnetEntretien-like structure
  static CarnetEntretien _ordreToCarnetEntretien(Map<String, dynamic> json) {
    // quelques gardes pour éviter exceptions si structure différente
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
      pieces: [], // OrdreTravail doesn't provide pieces in this mapping
      technicien: json['technicien']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  /// Retrieves maintenance statistics for a vehicle
  static Future<Map<String, dynamic>> getStatistiques(String token, String vehiculeId) async {
    final url = Uri.parse('$UrlApi/carnet/$vehiculeId/stats');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      final stats = (body['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final evo = (stats['evolutionDepenses'] as List<dynamic>?) ?? [];
      return {
        'totalEntretiens': stats['totalEntretiens'] ?? 0,
        'totalDepense': (stats['totalDepense'] as num?)?.toDouble() ?? 0.0,
        'moyenneParEntretien': (stats['moyenneParEntretien'] as num?)?.toDouble() ?? 0.0,
        'dernierEntretien': stats['dernierEntretien'] != null ? DateTime.tryParse(stats['dernierEntretien'].toString()) : null,
        'prochainEntretien': stats['prochainEntretien'] != null ? DateTime.tryParse(stats['prochainEntretien'].toString()) : null,
        'repartitionParType': stats['repartitionParType'] ?? {},
        'evolutionDepenses': evo.map((e) {
          try {
            return {
              'date': DateTime.parse(e['date'].toString()),
              'montant': (e['montant'] as num?)?.toDouble() ?? 0.0,
            };
          } catch (_) {
            return {'date': null, 'montant': 0.0};
          }
        }).toList(),
      };
    } else {
      String errorMsg = 'Erreur lors du calcul des statistiques';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  static Future<CarnetEntretien> updateCarnet({
    required String token,
    required String carnetId,
    required Map<String, dynamic> updates,
  }) async {
    final url = Uri.parse('$UrlApi/carnet/$carnetId');
    // debug
    print('=== [DEBUG updateCarnet] ===');
    print('➡️ URL: $url');
    print('➡️ Headers: {Content-Type: application/json, Authorization: Bearer $token}');
    print('➡️ Body envoyé: ${jsonEncode(updates)}');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    print("⬅️ Status Code: ${response.statusCode}");
    print("⬅️ Response Body: ${response.body}");

    final body = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      print("✅ updateCarnet JSON: $carnetJson");
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la mise à jour du carnet';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      print("❌ Erreur API updateCarnet: $errorMsg");
      throw Exception(errorMsg);
    }
  }

  /// Creates a manual CarnetEntretien entry
   /// Creates a manual CarnetEntretien entry
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

    // Debug - Infos avant envoi
    print("=== [DEBUG creerCarnetManuel] ===");
    print("➡️ URL: $url");
    print("➡️ Headers: {Content-Type: application/json, Authorization: Bearer $token}");
    print("➡️ Body envoyé: ${jsonEncode(requestBody)}");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    // Debug - Réponse brute
    print("⬅️ Status Code: ${response.statusCode}");
    print("⬅️ Response Body: ${response.body}");

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;

      // Debug - JSON carnet
      print("✅ CarnetEntretien JSON: $carnetJson");

      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la création du carnet';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }

      // Debug - Erreur
      print("❌ Erreur API: $errorMsg");

      throw Exception(errorMsg);
    }
  }


  /// Creates a CarnetEntretien from a Devis
  static Future<CarnetEntretien> creerDepuisDevis(String token, String devisId) async {
    final url = Uri.parse('$UrlApi/carnet/devis/$devisId');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la création du carnet depuis devis';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

  /// Marks a CarnetEntretien as completed
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'dateFinCompletion': dateFinCompletion?.toIso8601String(),
        'kilometrageEntretien': kilometrageEntretien,
        'notes': notes,
      }..removeWhere((k, v) => v == null)),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      final carnetJson = body['carnet'] as Map<String, dynamic>? ?? body;
      return CarnetEntretien.fromJson(carnetJson);
    } else {
      String errorMsg = 'Erreur lors de la mise à jour du carnet';
      if (body is Map && (body['error'] ?? body['message']) != null) {
        errorMsg = (body['error'] ?? body['message']).toString();
      }
      throw Exception(errorMsg);
    }
  }

   static Future<void> deleteCarnet(String token, String carnetId) async {
    final url = Uri.parse('$UrlApi/carnet/$carnetId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    // tenter d'extraire message d'erreur
    try {
      final body = jsonDecode(response.body);
      if (body is Map && (body['error'] ?? body['message']) != null) {
        throw Exception((body['error'] ?? body['message']).toString());
      }
    } catch (_) {
      // ignore parse error
    }

    throw Exception('Erreur lors de la suppression du carnet (code ${response.statusCode})');
  }
}
