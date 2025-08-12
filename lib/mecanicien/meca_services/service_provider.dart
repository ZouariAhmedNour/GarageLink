import 'package:flutter_riverpod/flutter_riverpod.dart';

class Service {
  final int id;
  final String nom;
  final String description;
  final double prix;
  final int duree;
  final String categorie;
  final bool actif;

  Service({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.duree,
    required this.categorie,
    this.actif = true,
  });

  Service copyWith({
    int? id,
    String? nom,
    String? description,
    double? prix,
    int? duree,
    String? categorie,
    bool? actif,
  }) {
    return Service(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      duree: duree ?? this.duree,
      categorie: categorie ?? this.categorie,
      actif: actif ?? this.actif,
    );
  }
}

class ServiceNotifier extends StateNotifier<List<Service>> {
  ServiceNotifier() : super([
    Service(id: 1, nom: 'Vidange complète', description: 'Vidange moteur + filtre à huile', prix: 85.0, duree: 45, categorie: 'Entretien'),
    Service(id: 2, nom: 'Révision générale', description: 'Contrôle complet du véhicule', prix: 250.0, duree: 120, categorie: 'Révision'),
    Service(id: 3, nom: 'Changement plaquettes', description: 'Remplacement plaquettes de frein', prix: 120.0, duree: 90, categorie: 'Freinage'),
  ]);

  void addService(Service s) {
    state = [...state, s];
  }

  void updateService(Service s) {
    state = [
      for (final item in state)
        if (item.id == s.id) s else item
    ];
  }

  void deleteService(int id) {
    state = state.where((s) => s.id != id).toList();
  }

  void toggleActif(int id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(actif: !item.actif) else item
    ];
  }
}

final serviceProvider = StateNotifierProvider<ServiceNotifier, List<Service>>((ref) {
  return ServiceNotifier();
});
