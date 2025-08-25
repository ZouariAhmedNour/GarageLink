// providers/orders_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrdersNotifier extends StateNotifier<List<WorkOrder>> {
  OrdersNotifier() : super([
    WorkOrder(
      id: 'WO-001',
      clientId: '1', // fait référence à Client.id
      immatriculation: '1HGCM82633A123456',
      date: DateTime(2025, 8, 16, 9, 0),
      dateDebut: DateTime(2025, 8, 16, 9, 0),
      service: 'Révision',
      atelier: 'Atelier 2',
      description: 'Contrôle général',
      mecanicien: 'Marie',
      status: 'En cours',
    ),
    WorkOrder(
      id: 'WO-002',
      clientId: '2',
      immatriculation: '1HGCM82633A654321',
      date: DateTime(2025, 8, 17, 10, 0),
      dateDebut: DateTime(2025, 8, 17, 10, 0),
      service: 'Réparation',
      atelier: 'Atelier 1',
      description: 'Changement embrayage',
      mecanicien: 'Jean',
      status: 'En attente',
    ),
  ]);

  void updateStatus(String id, String newStatus) {
    state = state.map((order) =>
      order.id == id ? order.copyWith(status: newStatus) : order
    ).toList();
  }

  void addOrder(WorkOrder order) {
    state = [...state, order];
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<WorkOrder>>((ref) {
  return OrdersNotifier();
});
