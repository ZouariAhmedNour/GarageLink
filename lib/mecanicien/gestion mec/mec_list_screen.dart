import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mecanicien.dart';
import 'package:garagelink/providers/mecaniciens_provider.dart';
import 'package:get/get.dart';
import 'add_mec_screen.dart';
import 'widgets/search_and_sort_row.dart';
import 'widgets/filter_row.dart';
import 'widgets/competence_chips.dart';
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
  bool _isFilterExpanded = false;
  bool _isLoading = false;
  int _page = 0;
  int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    _initAnimations();
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
).chain(CurveTween(curve: Curves.easeOutCubic))
 .animate(_slideController);
    
   _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
    .chain(CurveTween(curve: Curves.easeInOut))
    .animate(_slideController);

_fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
    .chain(CurveTween(curve: Curves.elasticOut))
    .animate(_fabController);

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _fabController.forward());
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
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
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
    return list.sublist(start, (_page + 1) * _pageSize.clamp(0, list.length));
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() => _isLoading = false);
      _showSnackBar('Liste actualisée', Icons.refresh, MecColors.success);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(message),
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
    final mecs = ref.watch(mecaniciensProvider);
    final filteredSorted = _applyFiltersAndSort(mecs);
    final pageCount = (filteredSorted.length / _pageSize).ceil();
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
            child: Column(
              children: [
                _buildHeader(filteredSorted.length),
                _buildFiltersSection(),
                Expanded(child: _buildContent(pageItems, filteredSorted)),
                _buildPagination(pageCount),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      elevation: 0,
      backgroundColor: MecColors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          _buildIconContainer(Icons.engineering, ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Équipe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('$count mécanicien${count > 1 ? 's' : ''}',
                     style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white,),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: Icon(_isFilterExpanded ? Icons.filter_list_off : Icons.filter_list, color: Colors.white,),
          onPressed: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
          tooltip: 'Filtres',
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
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count résultat${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_filterState.hasActiveFilters())
            _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton.icon(
      onPressed: _clearAllFilters,
      icon: const Icon(Icons.clear_all, color: Colors.white, size: 16),
      label: const Text('Reset', style: TextStyle(color: Colors.white, fontSize: 12)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? null : 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: _buildCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.search, 'Recherche et filtres'),
            const SizedBox(height: 12),
            SearchAndSortRow(
              onSearchChanged: (v) => _updateFilter(() => _filterState.search = v),
              onSortChanged: (v) => _updateFilter(() => _filterState.sortBy = v),
              onSortDirectionChanged: (v) => _updateFilter(() => _filterState.sortAsc = v),
              sortBy: _filterState.sortBy,
              sortAsc: _filterState.sortAsc,
            ),
            const SizedBox(height: 12),
            FilterRow(
              onPosteChanged: (v) => _updateFilter(() => _filterState.posteFilter = v),
              onStatutChanged: (v) => _updateFilter(() => _filterState.statutFilter = v),
              onContratChanged: (v) => _updateFilter(() => _filterState.typeContratFilter = v),
              onAncienneteChanged: (v) => _updateFilter(() => _filterState.ancienneteFilter = v),
              posteFilter: _filterState.posteFilter,
              statutFilter: _filterState.statutFilter,
              typeContratFilter: _filterState.typeContratFilter,
              ancienneteFilter: _filterState.ancienneteFilter,
            ),
            const SizedBox(height: 12),
            _buildSectionHeader(Icons.psychology, 'Compétences :'),
            const SizedBox(height: 8),
            CompetenceChips(
              onCompetenceSelected: (c, on) => _updateFilter(() {
                if (on) _filterState.servicesFilter.add(c);
                else _filterState.servicesFilter.remove(c);
              }),
              competencesFilter: _filterState.servicesFilter,
            ),
          ],
        ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: MecColors.primary));
    }

    if (pageItems.isEmpty) {
      return _buildEmptyState(allFiltered.isEmpty);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: pageItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Container(
            decoration: _buildCardDecoration(),
            child: MecListItem(
  mec: pageItems[index],
  onDelete: (id) => ref.read(mecaniciensProvider.notifier).removeMec(id),
  expanded: _expanded,
  onToggle: (id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  },
),

          );
        },
      ),
    );
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: MecColors.textSecondary),
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
        onPrevPage: () => setState(() => _page--),
        onNextPage: () => setState(() => _page++),
        onPageSizeChanged: (v) => setState(() { _pageSize = v; _page = 0; }),
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
          label: const Text('Nouveau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    final matchesSearch = search.isEmpty ||
        m.nom.toLowerCase().contains(search.toLowerCase()) ||
        m.id.toLowerCase().contains(search.toLowerCase());

    final matchesPoste = posteFilter == 'Tous' || 
        m.poste.toString().split('.').last.toLowerCase() == posteFilter.toLowerCase();

    final matchesStatut = statutFilter == 'Tous' || 
        m.statut.toString().split('.').last.toLowerCase() == statutFilter.toLowerCase();

    final matchesContrat = typeContratFilter == 'Tous' || 
        m.typeContrat.toString().split('.').last.toLowerCase() == typeContratFilter.toLowerCase();

    final years = computeYears(m.dateEmbauche);
    final matchesAnciennete = switch (ancienneteFilter) {
      '<1' => years < 1,
      '1-3' => years >= 1 && years <= 3,
      '3-5' => years > 3 && years <= 5,
      '5+' => years > 5,
      _ => true,
    };

    final matchesCompetences = servicesFilter.isEmpty || 
        servicesFilter.every((c) => m.services.contains(c));

    return matchesSearch && matchesPoste && matchesStatut && 
           matchesContrat && matchesAnciennete && matchesCompetences;
  }

  void sortList(List<Mecanicien> list, int Function(DateTime?) computeYears) {
    list.sort((a, b) {
      final cmp = switch (sortBy) {
        'salaire' => a.salaire.compareTo(b.salaire),
        'anciennete' => computeYears(a.dateEmbauche).compareTo(computeYears(b.dateEmbauche)),
        _ => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()),
      };
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
  }
}