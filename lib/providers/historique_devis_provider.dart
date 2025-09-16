// lib/providers/historique_devis_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/providers/factures_provider.dart';
import 'package:garagelink/services/devis_api.dart';

// Assure-toi que authTokenProvider existe dans ton projet
// import 'package:garagelink/providers/auth_provider.dart';

class HistoriqueDevisNotifier extends StateNotifier<List<Devis>> {
  final Ref ref;
  HistoriqueDevisNotifier(this.ref) : super([]);

  // Helper: trouve l'index par _id (id) ou par devisId (DEVxxx)
  int _findIndexByIdOrDevisId(String idOrDevisId) {
    return state.indexWhere((d) =>
        (d.id != null && d.id == idOrDevisId) ||
        (d.devisId.isNotEmpty && d.devisId == idOrDevisId));
  }

  // Helper: convertit un Devis en nouveau Devis avec nouveau statut
  Devis _withStatus(Devis d, DevisStatus status) {
    return Devis(
      id: d.id,
      devisId: d.devisId,
      clientId: d.clientId,
      clientName: d.clientName,
      vehicleInfo: d.vehicleInfo,
      vehiculeId: d.vehiculeId,
      factureId: d.factureId,
      inspectionDate: d.inspectionDate,
      services: d.services,
      totalHT: d.totalHT,
      totalServicesHT: d.totalServicesHT,
      totalTTC: d.totalTTC,
      tvaRate: d.tvaRate,
      maindoeuvre: d.maindoeuvre,
      estimatedTime: d.estimatedTime,
      status: status,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    );
  }

  // Utilitaire pour convertir DevisStatus -> String attendu par l'API/backend
  String statusToString(DevisStatus s) {
    switch (s) {
      case DevisStatus.envoye:
        return 'envoye';
      case DevisStatus.accepte:
        return 'accepte';
      case DevisStatus.refuse:
        return 'refuse';
      case DevisStatus.brouillon:
      return 'brouillon';
    }
  }

  /// Charger tous les devis depuis le backend et remplacer l'état local
  Future<void> loadAll() async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      // pas de token -> on ne tente pas l'appel réseau
      return;
    }

    try {
      final List<Devis> devisList = await DevisApi.getAllDevis(token: token);
      state = devisList;
    } catch (e) {
      // en cas d'erreur réseau, on garde l'état local (ou tu peux logger)
    }
  }

  void ajouterDevis(Devis devis) {
    final idx = _findIndexByIdOrDevisId(devis.id ?? devis.devisId);
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

  /// Met à jour le status côté backend puis côté local (fallback local si erreur)
  Future<void> updateStatusById(String idOrDevisId, DevisStatus status) async {
    final idx = _findIndexByIdOrDevisId(idOrDevisId);
    final token = ref.read(authTokenProvider);
    final statusStr = statusToString(status);

    // Tentative API (utilise la route PUT /devis/:id/status)
    if (token != null && token.isNotEmpty) {
      try {
        final updated = await DevisApi.updateDevisStatus(
          token: token,
          id: idOrDevisId,
          status: statusStr,
        );
        // updated est un Devis selon l'implémentation du client
        final index = _findIndexByIdOrDevisId(updated.id ?? updated.devisId);
        if (index != -1) {
          modifierDevis(index, updated);
        } else {
          ajouterDevis(updated);
        }
        return;
            } catch (e) {
        // ignore and fallback to local update
      }
    }

    // fallback local update si l'API a échoué ou pas de token
    if (idx != -1) {
      final current = state[idx];
      final updatedLocal = _withStatus(current, status);
      modifierDevis(idx, updatedLocal);
    }
  }

  Devis? getById(String idOrDevisId) {
    final idx = _findIndexByIdOrDevisId(idOrDevisId);
    return idx == -1 ? null : state[idx];
  }
}

final historiqueDevisProvider =
    StateNotifierProvider<HistoriqueDevisNotifier, List<Devis>>(
  (ref) => HistoriqueDevisNotifier(ref),
);

// ✅ Fonction utilitaire pour accepter un devis et générer une facture
// Note: on délègue la création de la facture au provider Factures (qui appelle l'API)
// afin d'avoir une facture cohérente côté backend (numéro unique, totals, etc.).
Future<void> onDevisAccepted(Devis devis, WidgetRef ref) async {
  // Le provider Facture sait utiliser le token interne ; on lui passe le devisId.
  final notifier = ref.read(historiqueDevisProvider.notifier);

  final idToUse = (devis.id != null && devis.id!.isNotEmpty) ? devis.id! : devis.devisId;

  try {
    // Demander au provider factures de créer la facture côté backend
    await ref.read(facturesProvider.notifier).ajouterFacture(devisId: idToUse);

    // Mettre à jour le statut du devis (backend + local)
    await notifier.updateStatusById(idToUse, DevisStatus.accepte);
  } catch (e) {
    // Si l'appel à la création de facture échoue, on tente quand même de marquer localement
    await notifier.updateStatusById(idToUse, DevisStatus.accepte);
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

  DateTime? parseInspection(Devis d) {
    if (d.inspectionDate.isNotEmpty) {
      try {
        return DateTime.parse(d.inspectionDate);
      } catch (_) {
        return d.createdAt;
      }
    }
    return d.createdAt;
  }

  return historique.where((devis) {
    final clientMatch = norm(devis.clientName).contains(filtre);

    // numéro/serie : on utilise vehiculeId, factureId ou devisId comme fallback
    final numeroSerie = norm(devis.vehiculeId);
    final numeroSerieMatch = numeroSerie.contains(filtre);

    final idMatch = ((devis.id ?? '') + (devis.devisId)).toLowerCase().contains(filtre);

    // date : essayer inspectionDate puis createdAt
    final dateVal = parseInspection(devis);
    final dateStr = dateVal != null ? dateVal.toIso8601String().toLowerCase() : '';
    final dateMatch = dateStr.contains(filtre);

    return clientMatch || numeroSerieMatch || idMatch || dateMatch;
  }).toList();
});
