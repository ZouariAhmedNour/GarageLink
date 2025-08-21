// lib/providers/historique_devis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';

class HistoriqueDevisNotifier extends StateNotifier<List<Devis>> {
  HistoriqueDevisNotifier() : super([]);

  void ajouterDevis(Devis devis) {
    // si déjà présent (même id), on remplace
    final idx = state.indexWhere((d) => d.id == devis.id);
    if (idx != -1) {
      final copie = [...state];
      copie[idx] = devis;
      state = copie;
    } else {
      // on préfixe la liste (les plus récents en haut)
      state = [devis, ...state];
    }
  }

  void modifierDevis(int index, Devis devis) {
    if (index >= 0 && index < state.length) {
      final copie = [...state];
      copie[index] = devis;
      state = copie;
    }
  }

  void supprimerDevis(int index) {
    if (index >= 0 && index < state.length) {
      final copie = [...state];
      copie.removeAt(index);
      state = copie;
    }
  }

  int _findIndexById(String id) => state.indexWhere((d) => d.id == id);

  void updateStatusById(String id, DevisStatus status) {
    final idx = _findIndexById(id);
    if (idx != -1) {
      final d = state[idx];
      final updated = d.copyWith(status: status);
      modifierDevis(idx, updated);
    }
  }

  Devis? getById(String id) {
    final idx = _findIndexById(id);
    return idx == -1 ? null : state[idx];
  }
}

final historiqueDevisProvider =
    StateNotifierProvider<HistoriqueDevisNotifier, List<Devis>>(
  (ref) => HistoriqueDevisNotifier(),
);

// Search filter provider (conserver ton implementation)
final filtreProvider = StateProvider<String>((ref) => "");

// filtered provider (conserver ton logic)
final devisFiltresProvider = Provider<List<Devis>>((ref) {
  final filtre = ref.watch(filtreProvider).toLowerCase();
  final historique = ref.watch(historiqueDevisProvider);

  if (filtre.isEmpty) return historique;

  return historique.where((devis) {
    final clientMatch = devis.client.toLowerCase().contains(filtre);
    final numeroSerieMatch = devis.numeroSerie.toLowerCase().contains(filtre);
    final idMatch = devis.id.toLowerCase().contains(filtre);
    final dateMatch = devis.date.toString().toLowerCase().contains(filtre);
    return clientMatch || numeroSerieMatch || idMatch || dateMatch;
  }).toList();
});
