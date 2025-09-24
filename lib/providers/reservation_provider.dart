import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/reservation.dart';
import 'package:garagelink/services/reservation_api.dart';
import 'package:garagelink/providers/auth_provider.dart';

class ReservationsState {
  final List<Reservation> reservations;
  final bool loading;
  final String? error;

  const ReservationsState({
    this.reservations = const [],
    this.loading = false,
    this.error,
  });

  ReservationsState copyWith({
    List<Reservation>? reservations,
    bool? loading,
    String? error,
  }) =>
      ReservationsState(
        reservations: reservations ?? this.reservations,
        loading: loading ?? this.loading,
        error: error,
      );
}

class ReservationsNotifier extends StateNotifier<ReservationsState> {
  ReservationsNotifier(this.ref) : super(const ReservationsState());

  final Ref ref;

  // Récupérer le token depuis le provider central (peut être null)
  String? get _token => ref.read(authTokenProvider);

  // Helpers d'état
  void setLoading(bool value) => state = state.copyWith(loading: value, error: null);
  void setError(String error) => state = state.copyWith(error: error, loading: false);
  void setReservations(List<Reservation> list) =>
      state = state.copyWith(reservations: [...list], error: null);
  void clear() => state = const ReservationsState();

  /// Charger toutes les réservations (token optionnel)
  Future<void> loadAll() async {
    setLoading(true);
    try {
      final reservations = await ReservationApi.getAllReservations(token: _token);
      setReservations(reservations);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Créer une réservation (token optionnel)
  Future<void> createReservation({
    required String garageId,
    required String clientName,
    required String clientPhone,
    String? clientEmail,
    required String serviceId,
    required DateTime creneauDemandeDate,
    required String creneauDemandeHeureDebut,
    required String descriptionDepannage,
  }) async {
    setLoading(true);
    try {
      final reservation = await ReservationApi.createReservation(
        token: _token,
        garageId: garageId,
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        serviceId: serviceId,
        creneauDemandeDate: creneauDemandeDate,
        creneauDemandeHeureDebut: creneauDemandeHeureDebut,
        descriptionDepannage: descriptionDepannage,
      );

      state = state.copyWith(
        reservations: [...state.reservations, reservation],
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Mettre à jour une réservation (token optionnel)
  Future<void> updateReservation({
    required String id,
    required String action,
    DateTime? newDate,
    String? newHeureDebut,
    String? message,
  }) async {
    setLoading(true);
    try {
      final updatedReservation = await ReservationApi.updateReservation(
        token: _token,
        id: id,
        action: action,
        newDate: newDate,
        newHeureDebut: newHeureDebut,
        message: message,
      );

      state = state.copyWith(
        reservations: state.reservations.map((r) => r.id == id ? updatedReservation : r).toList(),
        error: null,
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Récupérer une réservation par ID (cache local)
  Reservation? getById(String id) {
    try {
      return state.reservations.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // Trouver les réservations par garage (cache local)
  List<Reservation> findByGarageId(String garageId) {
    return state.reservations.where((r) => r.garageId == garageId).toList();
  }

  // Filtrer les réservations par statut (cache local)
  List<Reservation> findByStatus(List<ReservationStatus> statuses) {
    return state.reservations.where((r) => statuses.contains(r.status)).toList();
  }
}

final reservationsProvider = StateNotifierProvider<ReservationsNotifier, ReservationsState>((ref) {
  return ReservationsNotifier(ref);
});
