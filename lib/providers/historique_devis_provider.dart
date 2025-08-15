// historique_devis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';

class HistoriqueDevisNotifier extends StateNotifier<List<Devis>> {
  HistoriqueDevisNotifier() : super([]);

  void ajouterDevis(Devis devis) {
    state = [...state, devis];
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
}

final historiqueDevisProvider =
    StateNotifierProvider<HistoriqueDevisNotifier, List<Devis>>(
  (ref) => HistoriqueDevisNotifier(),
);

// Provider pour le texte de recherche
final filtreProvider = StateProvider<String>((ref) => "");

// Provider filtré
final devisFiltresProvider = Provider<List<Devis>>((ref) {
  final filtre = ref.watch(filtreProvider).toLowerCase();
  final historique = ref.watch(historiqueDevisProvider);

  if (filtre.isEmpty) return historique;

  return historique.where((devis) {
    final clientMatch = devis.client.toLowerCase().contains(filtre);
    final numeroSerieMatch = devis.numeroSerie.toLowerCase().contains(filtre);
    final idMatch = devis.id?.toLowerCase().contains(filtre) ?? false;
    final dateMatch = devis.date.toString().toLowerCase().contains(filtre);
    return clientMatch || numeroSerieMatch || idMatch || dateMatch;
  }).toList();
});
