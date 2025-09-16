import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garagelink/models/reservation.dart';
import 'package:garagelink/global.dart'; // Importer la constante UrlApi

class ReservationApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification
  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  /// Récupérer toutes les réservations
  static Future<List<Reservation>> getAllReservations(String token) async {
    final url = Uri.parse('$UrlApi/reservations');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Reservation.fromJson(json)).toList();
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la récupération des réservations');
    }
  }

  /// Créer une nouvelle réservation
  static Future<Reservation> createReservation({
    required String token,
    required String garageId,
    required String clientName,
    required String clientPhone,
    String? clientEmail,
    required String serviceId,
    required DateTime creneauDemandeDate,
    required String creneauDemandeHeureDebut,
    required String descriptionDepannage,
  }) async {
    final url = Uri.parse('$UrlApi/reservations');
    final body = jsonEncode({
      'garageId': garageId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'serviceId': serviceId,
      'creneauDemande': {
        'date': creneauDemandeDate.toIso8601String(),
        'heureDebut': creneauDemandeHeureDebut,
      },
      'descriptionDepannage': descriptionDepannage,
    }..removeWhere((key, value) => value == null));

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return Reservation.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erreur lors de la création de la réservation');
    }
  }

  /// Mettre à jour une réservation
  static Future<Reservation> updateReservation({
    required String token,
    required String id,
    required String action,
    DateTime? newDate,
    String? newHeureDebut,
    String? message,
  }) async {
    final url = Uri.parse('$UrlApi/reservations/$id');
    final body = jsonEncode({
      'action': action,
      'newDate': newDate?.toIso8601String(),
      'newHeureDebut': newHeureDebut,
      'message': message,
    }..removeWhere((key, value) => value == null));

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Reservation.fromJson(json['reservation']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Erreur lors de la mise à jour de la réservation');
    }
  }
}