import 'dart:convert';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/vehicule.dart'; 

class CarnetEntretienApi {
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Retrieves the maintenance history for a vehicle
  static Future<Map<String, dynamic>> getCarnetByVehiculeId(String token, String vehiculeId) async {
    final url = Uri.parse('$_baseUrl/carnet/$vehiculeId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'vehicule': Vehicule.fromJson(json['vehicule'] ?? {}),
        'historique': (json['historique'] as List<dynamic>?)
                ?.map((item) => item['source'] == 'carnet'
                    ? CarnetEntretien.fromJson(item)
                    : _ordreToCarnetEntretien(item))
                .toList() ??
            [],
      };
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur lors de la récupération du carnet';
      throw Exception(error);
    }
  }

  /// Converts an OrdreTravail JSON to a CarnetEntretien-like structure
  static CarnetEntretien _ordreToCarnetEntretien(Map<String, dynamic> json) {
    return CarnetEntretien(
      id: json['_id']?.toString(),
      vehiculeId: json['vehiculeId']?.toString() ?? '',
      devisId: json['devisInfo']?['id']?.toString(),
      dateCommencement: json['dateCommencement'] != null
          ? DateTime.parse(json['dateCommencement'])
          : DateTime.now(),
      dateFinCompletion: json['dateFinReelle'] != null
          ? DateTime.parse(json['dateFinReelle'])
          : null,
      statut: CarnetStatus.termine,
      totalTTC: (json['totalTTC'] as num?)?.toDouble() ?? 0.0,
      kilometrageEntretien: json['kilometrageEntretien'],
      notes: json['notes'] ?? 'Créé depuis ordre ${json['numeroOrdre']}',
      services: (json['taches'] as List<dynamic>?)
              ?.map((tache) => ServiceEntretien(
                    nom: tache['description'] ?? '',
                    description: tache['serviceNom'],
                    quantite: tache['quantite'] ?? 1,
                    prix: (tache['prix'] as num?)?.toDouble(),
                  ))
              .toList() ??
          [],
      pieces: [], // OrdreTravail doesn't provide pieces
      technicien: json['technicien'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Retrieves maintenance statistics for a vehicle
  static Future<Map<String, dynamic>> getStatistiques(String token, String vehiculeId) async {
    final url = Uri.parse('$_baseUrl/carnet/$vehiculeId/stats');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final stats = json['stats'] as Map<String, dynamic>;
      return {
        'totalEntretiens': stats['totalEntretiens'] ?? 0,
        'totalDepense': (stats['totalDepense'] as num?)?.toDouble() ?? 0.0,
        'moyenneParEntretien': (stats['moyenneParEntretien'] as num?)?.toDouble() ?? 0.0,
        'dernierEntretien': stats['dernierEntretien'] != null
            ? DateTime.parse(stats['dernierEntretien'])
            : null,
        'prochainEntretien': stats['prochainEntretien'] != null
            ? DateTime.parse(stats['prochainEntretien'])
            : null,
        'repartitionParType': stats['repartitionParType'] ?? {},
        'evolutionDepenses': (stats['evolutionDepenses'] as List<dynamic>?)
                ?.map((e) => {
                      'date': DateTime.parse(e['date']),
                      'montant': (e['montant'] as num?)?.toDouble() ?? 0.0,
                    })
                .toList() ??
            [],
      };
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur lors du calcul des statistiques';
      throw Exception(error);
    }
  }

  /// Creates a manual CarnetEntretien entry
  static Future<CarnetEntretien> creerCarnetManuel({
    required String token,
    required String vehiculeId,
    required DateTime date,
    required List<ServiceEntretien> taches,
    required double cout,
    String? notes,
  }) async {
    final url = Uri.parse('$_baseUrl/carnet');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vehiculeId': vehiculeId,
        'date': date.toIso8601String(),
        'taches': taches.map((tache) => tache.toJson()).toList(),
        'cout': cout,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body)['carnet'] as Map<String, dynamic>;
      return CarnetEntretien.fromJson(json);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur lors de la création du carnet';
      throw Exception(error);
    }
  }

  /// Creates a CarnetEntretien from a Devis
  static Future<CarnetEntretien> creerDepuisDevis(String token, String devisId) async {
    final url = Uri.parse('$_baseUrl/carnet/devis/$devisId');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body)['carnet'] as Map<String, dynamic>;
      return CarnetEntretien.fromJson(json);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur lors de la création du carnet depuis devis';
      throw Exception(error);
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
    final url = Uri.parse('$_baseUrl/carnet/$carnetId/complete');
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
      }..removeWhere((key, value) => value == null)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body)['carnet'] as Map<String, dynamic>;
      return CarnetEntretien.fromJson(json);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Erreur lors de la mise à jour du carnet';
      throw Exception(error);
    }
  }
}