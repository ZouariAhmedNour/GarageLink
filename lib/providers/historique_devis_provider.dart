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
  // Préparer un numéro de facture unique
  final invoiceId = (devis.id != null && devis.id!.isNotEmpty)
      ? 'INV_${devis.id}'
      : 'INV_${DateTime.now().millisecondsSinceEpoch}';

  // Récupérer totaux depuis le devis
  final double totalTTC = devis.totalTTC;
  final double totalHT = devis.totalHT;
  final double totalTVA = (totalTTC - totalHT) >= 0 ? (totalTTC - totalHT) : 0.0;

  // Convertir les services du Devis en ServiceItem (Facture)
  final List<ServiceItem> services = devis.services.map((s) {
    return ServiceItem(
      id: null,
      pieceId: s.pieceId,
      piece: s.piece,
      quantity: s.quantity,
      unitPrice: s.unitPrice,
      total: s.total,
    );
  }).toList();

  final facture = Facture(
    id: invoiceId,
    numeroFacture: invoiceId,
    devisId: devis.id, // lier la facture au devis si disponible
    clientInfo: ClientInfo(nom: devis.client),
    vehicleInfo: devis.vehicleInfo,
    invoiceDate: DateTime.now(), // remplace le 'date' inexistant
    inspectionDate: devis.inspectionDate,
    services: services,
    maindoeuvre: devis.maindoeuvre,
    tvaRate: devis.tvaRate,
    totalHT: totalHT,
    totalTVA: totalTVA,
    totalTTC: totalTTC,
    createdAt: DateTime.now(),
  );

  // Ajouter la facture via le provider
  try {
    ref.read(facturesProvider.notifier).addFacture(facture);
  } catch (e) {
    // gérer l'erreur ou logger (ne pas planter l'app)
    // debugPrint('onDevisAccepted: impossible d\'ajouter la facture: $e');
  }

  // Mettre à jour le status du devis dans l'historique
  if (devis.id != null) {
    ref.read(historiqueDevisProvider.notifier).updateStatusById(
      devis.id!,
      DevisStatus.accepte,
    );
  }
}

// 🔎 Provider pour la recherche (texte)
final filtreProvider = StateProvider<String>((ref) => "");

// 🔎 Provider filtré (recherche dans l'historique)
final devisFiltresProvider = Provider<List<Devis>>((ref) {
  final filtreRaw = ref.watch(filtreProvider);
  final filtre = (filtreRaw).toLowerCase().trim();
  final historique = ref.watch(historiqueDevisProvider);

  if (filtre.isEmpty) return historique;

  String norm(String? s) => (s ?? '').toLowerCase();

  return historique.where((devis) {
    final clientMatch = norm(devis.client).contains(filtre);

    // numéro/serie : on utilise vehiculeId, factureId ou empty comme fallback
    final numeroSerie = norm(devis.vehiculeId ?? devis.factureId ?? '');
    final numeroSerieMatch = numeroSerie.contains(filtre);

    final idMatch = norm(devis.id).contains(filtre);

    // date : essayer inspectionDate puis createdAt
    final dateVal = devis.inspectionDate ?? devis.createdAt;
    final dateStr = dateVal != null ? dateVal.toIso8601String().toLowerCase() : '';
    final dateMatch = dateStr.contains(filtre);

    return clientMatch || numeroSerieMatch || idMatch || dateMatch;
  }).toList();
});
