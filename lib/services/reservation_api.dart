// lib/services/reservation_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:garagelink/models/reservation.dart';
import 'package:garagelink/global.dart';

class ReservationApi {
  // En-têtes par défaut pour les requêtes JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // En-têtes avec authentification (token optionnel)
  static Map<String, String> _authHeaders(String? token) {
    if (token == null || token.isEmpty) return _headers;
    return {
      ..._headers,
      'Authorization': 'Bearer $token',
    };
  }

  /// Récupérer toutes les réservations
  static Future<List<Reservation>> getAllReservations({String? token}) async {
    final url = Uri.parse('$UrlApi/reservations');
    final response = await http.get(
      url,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Reservation.fromJson(json)).toList();
    } else {
      try {
        final json = jsonDecode(response.body);
        throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la récupération des réservations');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode} lors de la récupération des réservations');
      }
    }
  }

  /// Créer une nouvelle réservation
  /// POST $UrlApi/create-reservation
  static Future<Reservation> createReservation({
    String? token,
    required String garageId,
    required String clientName,
    required String clientPhone,
    String? clientEmail,
    required String serviceId,
    required DateTime creneauDemandeDate,
    required String creneauDemandeHeureDebut,
    required String descriptionDepannage,
  }) async {
    final url = Uri.parse('$UrlApi/create-reservation');

    // envoyer la date en format yyyy-MM-dd (date-only) pour éviter TZ shifts
    final dateOnly = DateFormat('yyyy-MM-dd').format(creneauDemandeDate);

    final body = jsonEncode({
      'garageId': garageId,
      'clientName': clientName.trim(),
      'clientPhone': clientPhone.trim(),
      'clientEmail': clientEmail?.trim(),
      'serviceId': serviceId,
      'creneauDemande': {
        'date': dateOnly,
        'heureDebut': creneauDemandeHeureDebut,
      },
      'descriptionDepannage': descriptionDepannage.trim(),
    }..removeWhere((key, value) => value == null));

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      // backend retourne { success: true, message: "...", data: savedReservation }
      return Reservation.fromJson(json['data']);
    } else {
      try {
        final json = jsonDecode(response.body);
        throw Exception(json['message'] ?? json['error'] ?? 'Erreur lors de la création de la réservation');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode} lors de la création de la réservation');
      }
    }
  }

  /// Mettre à jour une réservation
  /// PUT $UrlApi/update/reservations/:id
  /// Body attendu: { action, sender?, creneauPropose?, message? }
  static Future<Reservation> updateReservation({
    String? token,
    required String id,
    required String action,
    String? newDateStr, // yyyy-MM-dd
    String? newHeureDebut,
    String? message,
    String? sender, // 'client' or 'garage'
  }) async {
    final url = Uri.parse('$UrlApi/update/reservations/$id');

    final bodyMap = <String, dynamic>{
      'action': action,
    };

    if (sender != null) bodyMap['sender'] = sender;
    if (message != null) bodyMap['message'] = message;

    // only include creneauPropose if at least one of date/hour is present
    if (newDateStr != null || newHeureDebut != null) {
      bodyMap['creneauPropose'] = <String, dynamic>{};
      if (newDateStr != null) bodyMap['creneauPropose']['date'] = newDateStr;
      if (newHeureDebut != null) bodyMap['creneauPropose']['heureDebut'] = newHeureDebut;
    }

    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(bodyMap..removeWhere((k, v) => v == null)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // backend: { success: true, reservation: updatedReservation, message: "..."}
      return Reservation.fromJson(json['reservation']);
    } else {
      try {
        final json = jsonDecode(response.body);
        throw Exception(json['error'] ?? json['message'] ?? 'Erreur lors de la mise à jour de la réservation');
      } catch (_) {
        throw Exception('Erreur HTTP ${response.statusCode} lors de la mise à jour de la réservation');
      }
    }
  }
}
