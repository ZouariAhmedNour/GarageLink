// interventions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intervention.dart';

final interventionsProvider = StateProvider<List<Intervention>>((ref) {
  return [
    Intervention(
      id: 'I1',
      date: DateTime.now().subtract(Duration(days: 1)),
      clientName: 'Ali',
      type: 'Vidange',
      dureeMinutes: 45,
      prix: 120.0,
    ),
    Intervention(
      id: 'I2',
      date: DateTime.now().subtract(Duration(days: 2)),
      clientName: 'Sarra',
      type: 'Freins',
      dureeMinutes: 90,
      prix: 400.0,
    ),
  ];
});
