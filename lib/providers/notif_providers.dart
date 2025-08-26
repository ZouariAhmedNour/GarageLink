import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';

final notifProvider = Provider<List<Client>>((ref) {
  // Liste statique pour test
  return [
    Client(
      id: '1',
      nomComplet: 'Jean Dupont',
      mail: 'jean.dupont@example.com',
      telephone: '12345678',
      adresse: '12 rue de Paris, 75000 Paris',
      categorie: Categorie.particulier,
      vehiculeIds: ['VF1AAAA0001234567'], // exemple d'ID de véhicule
    ),
    Client(
      id: '2',
      nomComplet: 'Marie Curie',
      mail: 'marie.curie@example.com',
      telephone: '87654321',
      adresse: '5 avenue de Lyon, 69000 Lyon',
      categorie: Categorie.professionnel,
      nomE: 'Laboratoire Curie',
      telephoneE: '0987654321',
      mailE: 'contact@curie-lab.com',
      adresseE: '10 rue des Sciences, 69000 Lyon',
      vehiculeIds: [], // pas encore de véhicule associé
    ),
  ];
});
