import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';


class ClientsState {
final List<Client> clients;
final bool loading;


ClientsState({this.clients = const [], this.loading = false});


ClientsState copyWith({List<Client>? clients, bool? loading}) => ClientsState(
clients: clients ?? this.clients,
loading: loading ?? this.loading,
);
}


class ClientsNotifier extends StateNotifier<ClientsState> {
ClientsNotifier() : super(ClientsState());


void addClient(Client c) {
state = state.copyWith(clients: [...state.clients, c]);
}


void updateClient(String id, Client updated) {
state = state.copyWith(
clients: state.clients.map((c) => c.id == id ? updated : c).toList(),
);
}


void removeClient(String id) {
state = state.copyWith(clients: state.clients.where((c) => c.id != id).toList());
}

List<Client> filter({String? nom, String? immat, DateTime? from, DateTime? to}) {
return state.clients.where((c) {
final matchesNom = nom == null || nom.isEmpty || c.nomComplet.toLowerCase().contains(nom.toLowerCase());
final matchesImmat = immat == null || immat.isEmpty || c.vehiculeIds.any((vid) => vid.toLowerCase().contains(immat.toLowerCase()));
final matchesPeriode = true; // si tu veux filtrer par periode selon dateNaissance ou date de création tu peux adapter
return matchesNom && matchesImmat && matchesPeriode;
}).toList();
}
}


final clientsProvider = StateNotifierProvider<ClientsNotifier, ClientsState>((ref) => ClientsNotifier());