// lib/providers/reservation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';

// StateNotifier pour gérer les réservations
class ReservationNotifier extends StateNotifier<List<Reservation>> {
  ReservationNotifier() : super([]);

  // Ajouter une réservation
  void addReservation(Reservation reservation) {
    state = [...state, reservation];
  }

  // Mettre à jour une réservation
  void updateReservation(Reservation updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
  }

  // Supprimer une réservation
  void removeReservation(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  // Filtrer par statut
  List<Reservation> filterByStatus(List<ReservationStatus> statuses) {
    return state.where((r) => statuses.contains(r.status)).toList();
  }
}

// Provider global
final reservationsProvider =
    StateNotifierProvider<ReservationNotifier, List<Reservation>>(
  (ref) => ReservationNotifier(),
);
