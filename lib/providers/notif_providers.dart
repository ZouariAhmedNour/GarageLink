import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';

final notifProvider = Provider<List<Client>>((ref) {
  // Liste statique pour test
  return [
    Client(
      id: '1',
      nom: 'Jean Dupont',
      email: 'jean.dupont@example.com',
      tel: '12345678',
      numSerie: 'VF1AAAA0001234567', // optionnel
    ),
    Client(
      id: '2',
      nom: 'Marie Curie',
      email: 'marie.curie@example.com',
      tel: '87654321',
    ),
  ];
});