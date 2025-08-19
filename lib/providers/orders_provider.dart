// providers/orders_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrdersNotifier extends StateNotifier<List<WorkOrder>> {
  OrdersNotifier() : super([
    WorkOrder(
      id: 'WO-001',
      client: 'Jean Dupont',
      phone: '0600000000',
      email: 'jean@test.com',
      mechanic: 'Marie',
      workshop: 'Atelier 2',
      date: DateTime(2025, 8, 16, 9, 0),
      status: 'En cours',
      vin: '1HGCM82633A123456', // Added VIN for the first order
      service: 'Révision',
    ),
    WorkOrder(
      id: 'WO-002',
      client: 'Pierre Martin',
      phone: '0611111111',
      email: 'pierre@test.com',
      mechanic: 'Jean',
      workshop: 'Atelier 1',
      date: DateTime(2025, 8, 17, 10, 0),
      status: 'En attente',
      vin: '1HGCM82633A654321', // Added VIN for the second order
      service: 'Réparation',
    ),
  ]);

  void updateStatus(String id, String newStatus) {
    state = state.map((order) {
      if (order.id == id) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();
  }

  void addOrder(WorkOrder order) {
    state = [...state, order];
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<WorkOrder>>((ref) {
  return OrdersNotifier();
});
