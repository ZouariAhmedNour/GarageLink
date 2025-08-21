// factures_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facture.dart';

final facturesProvider = StateProvider<List<Facture>>((ref) {
  return [
    Facture(id: 'F1', date: DateTime.now().subtract(Duration(days: 1)), montant: 1200, clientName: 'Ali'),
    Facture(id: 'F2', date: DateTime.now().subtract(Duration(days: 3)), montant: 800, clientName: 'Sarra'),
    // ajoute tes factures réelles ici
  ];
});
