// lib/providers/carnet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/carnet_entretien.dart';

class CarnetNotifier extends StateNotifier<Map<String, List<CarnetEntretien>>> {
  CarnetNotifier() : super({});

  List<CarnetEntretien> entriesFor(String vehiculeId) {
    return state[vehiculeId] ?? [];
  }

  void setEntries(String vehiculeId, List<CarnetEntretien> entries) {
    state = {...state, vehiculeId: List<CarnetEntretien>.from(entries)};
  }

  void addEntry(String vehiculeId, CarnetEntretien entry) {
    final list = [entry, ...entriesFor(vehiculeId)];
    state = {...state, vehiculeId: list};
  }

  void updateEntry(String vehiculeId, String idOperation, CarnetEntretien updated) {
    final list = entriesFor(vehiculeId).map((e) => e.idOperation == idOperation ? updated : e).toList();
    state = {...state, vehiculeId: list};
  }

  void removeEntry(String vehiculeId, String idOperation) {
    final list = entriesFor(vehiculeId).where((e) => e.idOperation != idOperation).toList();
    state = {...state, vehiculeId: list};
  }

  void clearForVehicule(String vehiculeId) {
    final copy = Map<String, List<CarnetEntretien>>.from(state);
    copy.remove(vehiculeId);
    state = copy;
  }
}

final carnetProvider = StateNotifierProvider<CarnetNotifier, Map<String, List<CarnetEntretien>>>(
  (ref) => CarnetNotifier(),
);
