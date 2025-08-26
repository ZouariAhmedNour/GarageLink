// providers/mecaniciens_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mecanicien.dart';

class MecaniciensNotifier extends StateNotifier<List<Mecanicien>> {
  MecaniciensNotifier() : super(_initialData);

  static final List<Mecanicien> _initialData = [
    Mecanicien(
      id: 'MEC-1',
      nom: 'Ahmed Ben Ali',
      dateNaissance: DateTime(1990, 3, 12),
      telephone: '21612345678',
      email: 'ahmed@example.com',
      matricule: 'MAT-001',
      poste: Poste.mecanicien,
      dateEmbauche: DateTime(2018, 6, 1),
      typeContrat: TypeContrat.cdi,
      statut: Statut.actif,
      salaire: 1200.0,
      services: ['révision', 'diagnostic'],
      experience: '6 ans en mécanique générale',
      permisConduite: 'B',
    ),
    Mecanicien(
      id: 'MEC-2',
      nom: 'Sarra Haddad',
      dateNaissance: DateTime(1995, 10, 5),
      telephone: '21698765432',
      email: 'sarra@example.com',
      matricule: 'MAT-002',
      poste: Poste.electricien,
      dateEmbauche: DateTime(2020, 1, 15),
      typeContrat: TypeContrat.cdd,
      statut: Statut.actif,
      salaire: 1100.0,
      services: ['entretien', 'climatisation'],
      experience: '3 ans électricité auto',
      permisConduite: 'B',
    ),
  ];

  void addMec(Mecanicien m) {
    state = [...state, m];
  }

  void updateMec(String id, Mecanicien updated) {
    state = state.map((m) => m.id == id ? updated : m).toList();
  }

  void removeMec(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  Mecanicien? getById(String id) {
    try {
      return state.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}



final mecaniciensProvider =
    StateNotifierProvider<MecaniciensNotifier, List<Mecanicien>>((ref) {
  return MecaniciensNotifier();
});

final mecanicienByIdProvider = Provider.family<Mecanicien?, String>((ref, id) {
  final list = ref.watch(mecaniciensProvider);
  try {
    return list.firstWhere((m) => m.id == id);
  } catch (e) {
    return null;
  }
});