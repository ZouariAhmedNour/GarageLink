import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';

final notifProvider = Provider<List<Client>>((ref) {
  // Liste statique pour test
  return [
    Client(nom: 'Jean Dupont', email: 'jean.dupont@example.com', tel: '12345678'),
    Client(nom: 'Marie Curie', email: 'marie.curie@example.com', tel: '87654321'),
  ];
});