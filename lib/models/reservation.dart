// lib/models/reservation.dart
import 'package:uuid/uuid.dart';

enum ReservationStatus {
  enAttente,
  accepte,
  modifie,
  rejete,
  annule,
  clientConfirmed,
  mecanicienConfirmed,
}

class Reservation {
  final String id;
  final String clientId;
  final String mecanicienId;
  final String vehiculeId;
  final DateTime dateResa;
  final String heureResa; // format "HH:mm"
  final String descriptionPanne;
  final ReservationStatus status;
  final DateTime? nvDatePropose;
  final String? nvTimePropose;

  Reservation({
    String? id,
    required this.clientId,
    required this.mecanicienId,
    required this.vehiculeId,
    required this.dateResa,
    required this.heureResa,
    required this.descriptionPanne,
    this.status = ReservationStatus.enAttente,
    this.nvDatePropose,
    this.nvTimePropose,
  }) : id = id ?? const Uuid().v4();

  Reservation copyWith({
    String? id,
    String? clientId,
    String? mecanicienId,
    String? vehiculeId,
    DateTime? dateResa,
    String? heureResa,
    String? descriptionPanne,
    ReservationStatus? status,
    DateTime? nvDatePropose,
    String? nvTimePropose,
  }) {
    return Reservation(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      mecanicienId: mecanicienId ?? this.mecanicienId,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      dateResa: dateResa ?? this.dateResa,
      heureResa: heureResa ?? this.heureResa,
      descriptionPanne: descriptionPanne ?? this.descriptionPanne,
      status: status ?? this.status,
      nvDatePropose: nvDatePropose ?? this.nvDatePropose,
      nvTimePropose: nvTimePropose ?? this.nvTimePropose,
    );
  }
}
