import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/facture.dart';

enum SearchField { client, immatriculation, id, montant, periode }

class FactureFilterState {
  final DateTime? start;
  final DateTime? end;
  final String clientFilter;
  final String query;
  final List<Facture> factures;
  final SearchField searchField;

  // plage montant
  final double? minMontant;
  final double? maxMontant;

  FactureFilterState({
    this.start,
    this.end,
    this.clientFilter = '',
    this.query = '',
    this.factures = const [],
    this.searchField = SearchField.client,
    this.minMontant,
    this.maxMontant,
  });

  FactureFilterState copyWith({
    DateTime? start,
    DateTime? end,
    String? clientFilter,
    String? query,
    List<Facture>? factures,
    SearchField? searchField,
    double? minMontant,
    double? maxMontant,
  }) {
    return FactureFilterState(
      start: start ?? this.start,
      end: end ?? this.end,
      clientFilter: clientFilter ?? this.clientFilter,
      query: query ?? this.query,
      factures: factures ?? this.factures,
      searchField: searchField ?? this.searchField,
      minMontant: minMontant ?? this.minMontant,
      maxMontant: maxMontant ?? this.maxMontant,
    );
  }
}

class FactureNotifier extends StateNotifier<FactureFilterState> {
  FactureNotifier() : super(FactureFilterState());

  // CRUD
  void setFactures(List<Facture> factures) =>
      state = state.copyWith(factures: factures);

  void addFacture(Facture facture) =>
      state = state.copyWith(factures: [facture, ...state.factures]);

  void updateFacture(String id, Facture updated) {
    final idx = state.factures.indexWhere((f) => f.id == id);
    if (idx == -1) return;
    final copy = [...state.factures];
    copy[idx] = updated;
    state = state.copyWith(factures: copy);
  }

  void removeFacture(String id) => state = state.copyWith(
      factures: state.factures.where((f) => f.id != id).toList());

  // Filtres
  void setDateRange(DateTime? start, DateTime? end) =>
      state = state.copyWith(start: start, end: end);

  void setClientFilter(String client) =>
      state = state.copyWith(clientFilter: client);

  void setQuery(String query) => state = state.copyWith(query: query);

  void setMontantRange(double? min, double? max) =>
      state = state.copyWith(minMontant: min, maxMontant: max);

  void clearMontantRange() =>
      state = state.copyWith(minMontant: null, maxMontant: null);

  void setSearchField(SearchField field) =>
      state = state.copyWith(searchField: field);

  List<Facture> filtered({DateTime? start, DateTime? end}) {
    var list = List<Facture>.from(state.factures);

    final startDate = start ?? state.start;
    final endDate = end ?? state.end;

    // Filtrage par période
    if (startDate != null && endDate != null) {
      list = list
          .where((f) =>
              f.invoiceDate != null &&
              !f.invoiceDate!.isBefore(startDate) &&
              !f.invoiceDate!.isAfter(endDate))
          .toList();
    }

    // Filtrage par client
    if (state.clientFilter.isNotEmpty) {
      final pattern = state.clientFilter.toLowerCase();
      list = list
          .where((f) =>
              (f.clientInfo.nom ?? '').toLowerCase().contains(pattern))
          .toList();
    }

    // Mode "période"
    if (state.searchField == SearchField.periode) {
      list.sort((a, b) =>
          (b.invoiceDate ?? DateTime(1970)).compareTo(a.invoiceDate ?? DateTime(1970)));
      return list;
    }

    // Mode "montant"
    if (state.searchField == SearchField.montant) {
      final min = state.minMontant;
      final max = state.maxMontant;
      if (min != null || max != null) {
        list = list.where((f) {
          final m = f.totalTTC;
          if (min != null && max != null) return m >= min && m <= max;
          if (min != null) return m >= min;
          if (max != null) return m <= max;
          return true;
        }).toList();
        list.sort((a, b) =>
            (b.invoiceDate ?? DateTime(1970)).compareTo(a.invoiceDate ?? DateTime(1970)));
        return list;
      }
      // fallback : recherche textuelle sur montant
      if (state.query.isNotEmpty) {
        final q = state.query.trim().toLowerCase();
        final qNumStr = q.replaceAll(',', '.');
        final parsed = double.tryParse(qNumStr);
        if (parsed != null) {
          list = list.where((f) {
            final m = f.totalTTC;
            return m.toString().contains(qNumStr) ||
                m.toStringAsFixed(2).contains(qNumStr) ||
                (m - parsed).abs() < 0.0001;
          }).toList();
        } else {
          list =
              list.where((f) => f.totalTTC.toString().contains(q)).toList();
        }
        list.sort((a, b) =>
            (b.invoiceDate ?? DateTime(1970)).compareTo(a.invoiceDate ?? DateTime(1970)));
        return list;
      }
    }

    // Autres modes (client / immatriculation / id)
    if (state.query.isNotEmpty) {
      final q = state.query.trim().toLowerCase();
      switch (state.searchField) {
        case SearchField.client:
          list = list
              .where((f) =>
                  (f.clientInfo.nom ?? '').toLowerCase().contains(q))
              .toList();
          break;
        case SearchField.immatriculation:
          list = list
              .where((f) => (f.vehicleInfo ?? '').toLowerCase().contains(q))
              .toList();
          break;
        case SearchField.id:
          list = list
              .where((f) => (f.id ?? '').toLowerCase().contains(q))
              .toList();
          break;
        case SearchField.montant:
        case SearchField.periode:
          break; // déjà gérés
      }
    }

    list.sort((a, b) =>
        (b.invoiceDate ?? DateTime(1970)).compareTo(a.invoiceDate ?? DateTime(1970)));
    return list;
  }

  double totalMontant({DateTime? start, DateTime? end}) {
    return filtered(start: start, end: end)
        .fold(0.0, (sum, f) => sum + f.totalTTC);
  }
}

final facturesProvider =
    StateNotifierProvider<FactureNotifier, FactureFilterState>(
  (ref) => FactureNotifier(),
);
