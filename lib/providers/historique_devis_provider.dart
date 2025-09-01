// lib/providers/historique_devis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/models/facture.dart';
import 'package:garagelink/providers/factures_provider.dart';

class HistoriqueDevisNotifier extends StateNotifier<List<Devis>> {
  HistoriqueDevisNotifier() : super([]);

  void ajouterDevis(Devis devis) {
    final idx = state.indexWhere((d) => d.id == devis.id);
    if (idx != -1) {
      final copie = [...state];
      copie[idx] = devis;
      state = copie;
    } else {
      state = [devis, ...state]; // ajouter en tête
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

// ✅ Fonction utilitaire pour accepter un devis et générer une facture
void onDevisAccepted(Devis devis, WidgetRef ref) {
  final facture = Facture(
    id: 'INV_${devis.id}', // logique ID simple
    date: DateTime.now(),
    montant: double.parse(devis.totalTtc.toStringAsFixed(2)),
    clientName: devis.client,
  );

  // Ici on utilise facturesProvider (pas facturesNotifierProvider)
  ref.read(facturesProvider.notifier).setFactures([
    ...ref.read(facturesProvider).factures,
    facture,
  ]);
}

// 🔎 Provider pour la recherche
final filtreProvider = StateProvider<String>((ref) => "");

// 🔎 Provider filtré
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
