import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicule.dart';


class VehiculesState {
final List<Vehicule> vehicules;
final bool loading;


VehiculesState({this.vehicules = const [], this.loading = false});


VehiculesState copyWith({List<Vehicule>? vehicules, bool? loading}) => VehiculesState(
vehicules: vehicules ?? this.vehicules,
loading: loading ?? this.loading,
);
}


class VehiculesNotifier extends StateNotifier<VehiculesState> {
VehiculesNotifier() : super(VehiculesState());


void addVehicule(Vehicule v) {
state = state.copyWith(vehicules: [...state.vehicules, v]);
}
void updateVehicule(String id, Vehicule updated) {
state = state.copyWith(
vehicules: state.vehicules.map((v) => v.id == id ? updated : v).toList(),
);
}


void removeVehicule(String id) {
state = state.copyWith(vehicules: state.vehicules.where((v) => v.id != id).toList());
}


List<Vehicule> findByClient(String clientId) => state.vehicules.where((v) => v.clientId == clientId).toList();
}


final vehiculesProvider = StateNotifierProvider<VehiculesNotifier, VehiculesState>((ref) => VehiculesNotifier());