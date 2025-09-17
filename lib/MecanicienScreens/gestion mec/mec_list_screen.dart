// screens/mec_list_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/providers/mecaniciens_provider.dart';
import 'package:get/get.dart';
import 'add_mec_screen.dart';
import 'widgets/search_and_sort_row.dart';
import 'widgets/service_chips.dart';
import 'widgets/mec_list_item.dart';
import 'widgets/pagination_controls.dart';

// Palette de couleurs optimisée
class MecColors {
  static const primary = Color(0xFF357ABD);
  static const primaryLight = Color(0xFF5A9BD8);
  static const success = Color(0xFF38A169);
  static const surface = Color(0xFFFAFAFA);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
}

class MecListScreen extends ConsumerStatefulWidget {
  const MecListScreen({super.key});

  @override
  ConsumerState<MecListScreen> createState() => _MecListScreenState();
}

class _MecListScreenState extends ConsumerState<MecListScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fabController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabScaleAnimation;

  // État des filtres
  final _filterState = _FilterState();
  final Set<String> _expanded = {};

  // UI state
  int _page = 0;
  int _pageSize = 8;
  int _selectedFilterIndex = 0; // 0=Poste,1=Statut,2=Contrat,3=Services,4=Ancienneté

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // charge initialement la liste (si nécessaire)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mecaniciensProvider.notifier).loadAll();
    });
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_slideController);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_slideController);

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_fabController);

    _slideController.forward();
    Future.delayed(
      const Duration(milliseconds: 200),
      () => _fabController.forward(),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  int _computeAncienneteYears(DateTime? date) {
    if (date == null) return 0;
    final now = DateTime.now();
    int years = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      years--;
    }
    return years;
  }

  List<Mecanicien> _applyFiltersAndSort(List<Mecanicien> list) {
    final filtered = list.where((m) => _filterState.matches(m, _computeAncienneteYears)).toList();
    _filterState.sortList(filtered, _computeAncienneteYears);
    return filtered;
  }

  List<Mecanicien> _paginate(List<Mecanicien> list) {
    final start = _page * _pageSize;
    if (start >= list.length) return [];
    final end = math.min(list.length, start + _pageSize);
    return list.sublist(start, end);
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(mecaniciensProvider.notifier).loadAll();
      _showSnackBar('Liste actualisée', Icons.refresh, MecColors.success);
    } catch (e) {
      _showSnackBar('Erreur lors de l\'actualisation', Icons.error, Colors.red);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filterState.reset();
      _page = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _updateFilter(VoidCallback update) {
    setState(() {
      update();
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mecaniciensProvider); // MecaniciensState
    final mecs = state.mecaniciens;
    final isLoading = state.loading;
    final hasError = state.error != null;

    final filteredSorted = _applyFiltersAndSort(mecs);
    final pageCount = (filteredSorted.isEmpty) ? 0 : (filteredSorted.length / _pageSize).ceil();
    final pageItems = _paginate(filteredSorted);

    return Scaffold(
      backgroundColor: MecColors.surface,
      appBar: _buildAppBar(filteredSorted.length),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: MecColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(filteredSorted.length),
                  _buildFiltersSection(),
                  const SizedBox(height: 8),
                  // contenu principal
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: MecColors.primary)),
                    )
                  else if (hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          state.error ?? 'Erreur inconnue',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: _buildContent(pageItems, filteredSorted),
                    ),
                  _buildPagination(pageCount),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      backgroundColor: MecColors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          _buildIconContainer(Icons.engineering),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Équipe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$count mécanicien${count > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MecColors.primary, MecColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MecColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIconContainer(Icons.people),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion de l\'équipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count résultat${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_filterState.hasActiveFilters()) _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton.icon(
      onPressed: _clearAllFilters,
      icon: const Icon(Icons.clear_all, color: Colors.white, size: 16),
      label: const Text(
        'Reset',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.search, 'Recherche et filtres'),
          const SizedBox(height: 12),
          // Recherche + tri
          SearchAndSortRow(
            onSearchChanged: (v) => _updateFilter(() => _filterState.search = v),
            onSortChanged: (v) => _updateFilter(() => _filterState.sortBy = v),
            onSortDirectionChanged: (v) => _updateFilter(() => _filterState.sortAsc = v),
            sortBy: _filterState.sortBy,
            sortAsc: _filterState.sortAsc,
          ),
          const SizedBox(height: 12),
          // Onglets filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ToggleButtons(
              isSelected: List.generate(5, (i) => i == _selectedFilterIndex),
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: MecColors.primary,
              onPressed: (index) {
                setState(() => _selectedFilterIndex = index);
              },
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Poste")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Statut")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Contrat")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Services")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Ancienneté")),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Contenu dynamique
          if (_selectedFilterIndex == 0) // Poste
            DropdownButtonFormField<String>(
              value: _filterState.posteFilter,
              items: ['Tous', 'Chef', 'Technicien', 'Apprenti']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => _updateFilter(() => _filterState.posteFilter = v ?? 'Tous'),
              decoration: const InputDecoration(labelText: "Filtrer par poste"),
            ),
          if (_selectedFilterIndex == 1) // Statut
            DropdownButtonFormField<String>(
              value: _filterState.statutFilter,
              items: ['Tous', 'Actif', 'Inactif']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => _updateFilter(() => _filterState.statutFilter = v ?? 'Tous'),
              decoration: const InputDecoration(labelText: "Filtrer par statut"),
            ),
          if (_selectedFilterIndex == 2) // Contrat
            DropdownButtonFormField<String>(
              value: _filterState.typeContratFilter,
              items: ['Tous', 'CDI', 'CDD', 'Stage']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => _updateFilter(() => _filterState.typeContratFilter = v ?? 'Tous'),
              decoration: const InputDecoration(labelText: "Filtrer par type de contrat"),
            ),
          if (_selectedFilterIndex == 3) ...[
            _buildSectionHeader(Icons.home_repair_service, 'Services'),
            const SizedBox(height: 8),
            ServicesChips(
              onServiceSelected: (c, on) => _updateFilter(() {
                if (on) _filterState.servicesFilter.add(c);
                else _filterState.servicesFilter.remove(c);
              }),
              servicesFilter: _filterState.servicesFilter,
            ),
          ],
          if (_selectedFilterIndex == 4) // Ancienneté
            DropdownButtonFormField<String>(
              value: _filterState.ancienneteFilter,
              items: ['Tous', '<1', '1-3', '3-5', '5+']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => _updateFilter(() => _filterState.ancienneteFilter = v ?? 'Tous'),
              decoration: const InputDecoration(labelText: "Filtrer par ancienneté"),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: MecColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildContent(List<Mecanicien> pageItems, List<Mecanicien> allFiltered) {
    if (pageItems.isEmpty) return _buildEmptyState(allFiltered.isEmpty);

    // Utilise Column car la pagination limite la taille de la page (évite conflits scroll imbriqués)
    final children = <Widget>[];
    for (var i = 0; i < pageItems.length; i++) {
      children.add(Container(
        decoration: _buildCardDecoration(),
        child: MecListItem(
          mec: pageItems[i],
          onDelete: (id) async {
            // supprime via le provider
            try {
              await ref.read(mecaniciensProvider.notifier).removeMecanicien(id);
              _showSnackBar('Mécanicien supprimé', Icons.delete, MecColors.success);
            } catch (e) {
              _showSnackBar('Erreur suppression', Icons.error, Colors.red);
            }
          },
          expanded: _expanded,
          onToggle: (id) {
            setState(() {
              if (_expanded.contains(id)) _expanded.remove(id);
              else _expanded.add(id);
            });
          },
        ),
      ));
      if (i < pageItems.length - 1) children.add(const SizedBox(height: 8));
    }

    return Column(children: children);
  }

  Widget _buildEmptyState(bool noResults) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noResults ? Icons.search_off : Icons.inbox_outlined,
            size: 64,
            color: MecColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            noResults ? 'Aucun mécanicien trouvé' : 'Aucune page disponible',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MecColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noResults ? 'Essayez de modifier vos critères' : 'Naviguez vers une autre page',
            style: const TextStyle(fontSize: 14, color: MecColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (noResults && _filterState.hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MecColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination(int pageCount) {
    if (pageCount <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: PaginationControls(
        page: _page,
        pageCount: pageCount,
        pageSize: _pageSize,
        onPrevPage: () {
          if (_page > 0) setState(() => _page--);
        },
        onNextPage: () {
          if (_page + 1 < pageCount) setState(() => _page++);
        },
        onPageSizeChanged: (v) => setState(() {
          _pageSize = v;
          _page = 0;
        }),
      ),
    );
  }

  Widget _buildFab() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [MecColors.primary, MecColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MecColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.to(() => const AddMecScreen());
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            'Nouveau',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: MecColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// Classe pour gérer l'état des filtres de manière optimisée
class _FilterState {
  String search = '';
  String posteFilter = 'Tous';
  String statutFilter = 'Tous';
  String typeContratFilter = 'Tous';
  String ancienneteFilter = 'Tous';
  final Set<String> servicesFilter = {};
  String sortBy = 'nom';
  bool sortAsc = true;

  bool matches(Mecanicien m, int Function(DateTime?) computeYears) {
    final idLower = (m.id ?? '').toLowerCase();
    final matchesSearch =
        search.isEmpty ||
        m.nom.toLowerCase().contains(search.toLowerCase()) ||
        idLower.contains(search.toLowerCase());

    final posteRaw = m.poste.toString().split('.').last.toLowerCase();
    final matchesPoste =
        posteFilter == 'Tous' || posteRaw == posteFilter.toLowerCase();

    final statutRaw = m.statut.toString().split('.').last.toLowerCase();
    final matchesStatut =
        statutFilter == 'Tous' || statutRaw == statutFilter.toLowerCase();

    final contratRaw = m.typeContrat.toString().split('.').last.toLowerCase();
    final matchesContrat =
        typeContratFilter == 'Tous' || contratRaw == typeContratFilter.toLowerCase();

    final years = computeYears(m.dateEmbauche);
    final matchesAnciennete = () {
      switch (ancienneteFilter) {
        case '<1':
          return years < 1;
        case '1-3':
          return years >= 1 && years <= 3;
        case '3-5':
          return years > 3 && years <= 5;
        case '5+':
          return years > 5;
        default:
          return true;
      }
    }();

    // servicesFilter contient des strings (noms). m.services contient ServiceMecanicien
    final mecanicienServiceNames = m.services.map((s) => s.name.toLowerCase()).toSet();
    final matchesCompetences = servicesFilter.isEmpty ||
        servicesFilter.every((c) => mecanicienServiceNames.contains(c.toLowerCase()));

    return matchesSearch &&
        matchesPoste &&
        matchesStatut &&
        matchesContrat &&
        matchesAnciennete &&
        matchesCompetences;
  }

  void sortList(List<Mecanicien> list, int Function(DateTime?) computeYears) {
    list.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case 'salaire':
          cmp = a.salaire.compareTo(b.salaire);
          break;
        case 'anciennete':
          cmp = computeYears(a.dateEmbauche).compareTo(computeYears(b.dateEmbauche));
          break;
        default:
          cmp = a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      }
      return sortAsc ? cmp : -cmp;
    });
  }

  bool hasActiveFilters() {
    return search.isNotEmpty ||
        posteFilter != 'Tous' ||
        statutFilter != 'Tous' ||
        typeContratFilter != 'Tous' ||
        ancienneteFilter != 'Tous' ||
        servicesFilter.isNotEmpty;
  }

  void reset() {
    search = '';
    posteFilter = 'Tous';
    statutFilter = 'Tous';
    typeContratFilter = 'Tous';
    ancienneteFilter = 'Tous';
    servicesFilter.clear();
    sortBy = 'nom';
    sortAsc = true;
  }
}
