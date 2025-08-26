// providers/service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/service.dart';

class ServiceNotifier extends StateNotifier<List<Service>> {
  ServiceNotifier() : super([
    Service(id: 'SVC-1', nomService: 'Vidange complète', description: 'Vidange moteur + filtre à huile', status: ServiceStatus.actif),
    Service(id: 'SVC-2', nomService: 'Révision générale', description: 'Contrôle complet du véhicule', status: ServiceStatus.actif),
    Service(id: 'SVC-3', nomService: 'Changement plaquettes', description: 'Remplacement plaquettes de frein', status: ServiceStatus.inactif),
  ]);

  void addService(Service s) => state = [...state, s];

  void updateService(Service s) => state = [for (final item in state) if (item.id == s.id) s else item];

  void deleteService(String id) => state = state.where((s) => s.id != id).toList();

  void toggleStatus(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: item.status == ServiceStatus.actif ? ServiceStatus.inactif : ServiceStatus.actif)
        else
          item
    ];
  }
}

final serviceProvider = StateNotifierProvider<ServiceNotifier, List<Service>>((ref) => ServiceNotifier());
