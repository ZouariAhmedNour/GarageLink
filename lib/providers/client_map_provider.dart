// lib/providers/client_map_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class ClientLocationState {
  final LatLng? position;
  ClientLocationState({this.position});
  ClientLocationState copyWith({LatLng? position}) => ClientLocationState(position: position ?? this.position);
}

class ClientLocationNotifier extends StateNotifier<ClientLocationState> {
  ClientLocationNotifier(): super(ClientLocationState());

  void setPosition(LatLng pos) => state = state.copyWith(position: pos);

  void clear() => state = ClientLocationState();
}

final clientLocationProvider = StateNotifierProvider<ClientLocationNotifier, ClientLocationState>(
  (ref) => ClientLocationNotifier(),
);
