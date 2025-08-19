import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rapport.dart';
import 'dart:math';

class RapportNotifier extends StateNotifier<List<Rapport>> {
  RapportNotifier() : super([]);

  void addRapport(Rapport rapport) {
    state = [...state, rapport];
  }

  void updateRapport(Rapport updated) {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
  }

  Rapport? getByOrderId(String orderId) {
    return state.firstWhere(
      (r) => r.orderId == orderId,
      orElse: () => Rapport(
        id: Random().nextInt(999999).toString(),
        orderId: orderId,
        panne: '',
        pieces: '',
        notes: '',
      ),
    );
  }
}

final rapportProvider = StateNotifierProvider<RapportNotifier, List<Rapport>>(
  (ref) => RapportNotifier(),
);
