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

// Palette de couleurs pour la gestion des mécaniciens
class MecColors {
  static const Color primary = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF5A9BD8);
  static const Color primaryDark = Color(0xFF2A5F8F);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFED8936);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
}

class MecListScreen extends ConsumerStatefulWidget {
  const MecListScreen({super.key});

  @override
  ConsumerState<MecListScreen> createState() => _MecListScreenState();
}

class _MecListScreenState extends ConsumerState<MecListScreen>
    with TickerProviderStateMixin {
  // Controllers d'animation
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabScaleAnimation;

  // Filtres et tri
  String _search = '';
  String _posteFilter = 'Tous';
  String _statutFilter = 'Tous';
  String _typeContratFilter = 'Tous';
  String _ancienneteFilter = 'Tous';
  final Set<String> _servicesFilter = {};
  String _sortBy = 'nom';
  bool _sortAsc = true;

  // Pagination
  int _page = 0;
  int _pageSize = 8;

  // UI state
  final Set<String> _expanded = {};
  bool _isFilterExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  int _computeAncienneteYears(DateTime? dateEmbauche) {
    if (dateEmbauche == null) return 0;
    final now = DateTime.now();
    int years = now.year - dateEmbauche.year;
    if (now.month < dateEmbauche.month || 
        (now.month == dateEmbauche.month && now.day < dateEmbauche.day)) {
      years--;
    }
    return years;
  }

  List<Mecanicien> _applyFiltersAndSort(List<Mecanicien> list) {
    final filtered = list.where((m) {
      final matchesSearch = _search.isEmpty ||
          m.nom.toLowerCase().contains(_search.toLowerCase()) ||
          m.id.toLowerCase().contains(_search.toLowerCase());

      final posteStr = m.poste.toString().split('.').last.toLowerCase();
      final matchesPoste = _posteFilter == 'Tous' || posteStr == _posteFilter.toLowerCase();

      final statutStr = m.statut.toString().split('.').last.toLowerCase();
      final matchesStatut = _statutFilter == 'Tous' || statutStr == _statutFilter.toLowerCase();

      final contratStr = m.typeContrat.toString().split('.').last.toLowerCase();
      final matchesContrat = _typeContratFilter == 'Tous' || contratStr == _typeContratFilter.toLowerCase();

      final years = _computeAncienneteYears(m.dateEmbauche);
      bool matchesAnciennete = true;
      switch (_ancienneteFilter) {
        case '<1': matchesAnciennete = years < 1; break;
        case '1-3': matchesAnciennete = years >= 1 && years <= 3; break;
        case '3-5': matchesAnciennete = years > 3 && years <= 5; break;
        case '5+': matchesAnciennete = years > 5; break;
        default: matchesAnciennete = true;
      }

      bool matchesCompetences = true;
      if (_servicesFilter.isNotEmpty) {
        matchesCompetences = _servicesFilter.every((c) => m.services.contains(c));
      }

      return matchesSearch && matchesPoste && matchesStatut && 
             matchesContrat && matchesAnciennete && matchesCompetences;
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'salaire': cmp = a.salaire.compareTo(b.salaire); break;
        case 'anciennete': cmp = _computeAncienneteYears(a.dateEmbauche)
                              .compareTo(_computeAncienneteYears(b.dateEmbauche)); break;
        default: cmp = a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      }
      return _sortAsc ? cmp : -cmp;
    });

    return filtered;
  }

  List<Mecanicien> _paginate(List<Mecanicien> list) {
    final start = _page * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: MecColors.success),
              const SizedBox(width: 8),
              const Text('Liste actualisée'),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _clearAllFilters() {
    setState(() {
      _search = '';
      _posteFilter = 'Tous';
      _statutFilter = 'Tous';
      _typeContratFilter = 'Tous';
      _ancienneteFilter = 'Tous';
      _servicesFilter.clear();
      _page = 0;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final mecs = ref.watch(mecaniciensProvider);
    final filteredSorted = _applyFiltersAndSort(mecs);
    final pageCount = (filteredSorted.length / _pageSize).ceil();
    final pageItems = _paginate(filteredSorted);

    return Scaffold(
      backgroundColor: MecColors.surface,
      appBar: _buildModernAppBar(filteredSorted.length),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: MecColors.primary,
          child: Column(
            children: [
              _buildHeaderSection(filteredSorted.length),
              _buildFiltersSection(),
              Expanded(child: _buildContentSection(pageItems, filteredSorted)),
              _buildPaginationSection(pageCount),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAnimatedFab(),
    );
  }

  PreferredSizeWidget _buildModernAppBar(int totalCount) {
    return AppBar(
      elevation: 0,
      backgroundColor: MecColors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.engineering, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Équipe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('$totalCount mécanicien${totalCount > 1 ? 's' : ''}',
                   style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: Icon(_isFilterExpanded ? Icons.filter_list_off : Icons.filter_list),
          onPressed: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
          tooltip: 'Filtres',
        ),
      ],
    );
  }

  Widget _buildHeaderSection(int count) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people, color: Colors.white, size: 24),
          ),
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
          if (_hasActiveFilters())
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all, color: Colors.white, size: 16),
              label: const Text('Reset', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isFilterExpanded ? null : 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MecColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: MecColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Recherche et filtres', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            SearchAndSortRow(
              onSearchChanged: (v) => setState(() { _search = v; _page = 0; }),
              onSortChanged: (v) => setState(() { _sortBy = v; }),
              onSortDirectionChanged: (v) => setState(() { _sortAsc = v; }),
              sortBy: _sortBy,
              sortAsc: _sortAsc,
            ),
            const SizedBox(height: 12),
            FilterRow(
              onPosteChanged: (v) => setState(() { _posteFilter = v; _page = 0; }),
              onStatutChanged: (v) => setState(() { _statutFilter = v; _page = 0; }),
              onContratChanged: (v) => setState(() { _typeContratFilter = v; _page = 0; }),
              onAncienneteChanged: (v) => setState(() { _ancienneteFilter = v; _page = 0; }),
              posteFilter: _posteFilter,
              statutFilter: _statutFilter,
              typeContratFilter: _typeContratFilter,
              ancienneteFilter: _ancienneteFilter,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.psychology, color: MecColors.primary, size: 16),
                const SizedBox(width: 4),
                const Text('Compétences :', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            CompetenceChips(
              onCompetenceSelected: (c, on) => setState(() {
                if (on) _servicesFilter.add(c);
                else _servicesFilter.remove(c);
                _page = 0;
              }),
              competencesFilter: _servicesFilter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(List<Mecanicien> pageItems, List<Mecanicien> allFiltered) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: MecColors.primary),
      );
    }

    if (pageItems.isEmpty) {
      return _buildEmptyState(allFiltered.isEmpty);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: pageItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final m = pageItems[index];
          return Container(
            decoration: BoxDecoration(
              color: MecColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: MecListItem(
              mec: m,
              onDelete: (id) => ref.read(mecaniciensProvider.notifier).removeMec(id),
              expanded: _expanded,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MecColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noResults 
              ? 'Essayez de modifier vos critères de recherche'
              : 'Naviguez vers une autre page',
            style: TextStyle(
              fontSize: 14,
              color: MecColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (noResults && _hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser les filtres'),
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

  Widget _buildPaginationSection(int pageCount) {
    if (pageCount <= 1) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MecColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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

  Widget _buildAnimatedFab() {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
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
      },
    );
  }

  bool _hasActiveFilters() {
    return _search.isNotEmpty ||
           _posteFilter != 'Tous' ||
           _statutFilter != 'Tous' ||
           _typeContratFilter != 'Tous' ||
           _ancienneteFilter != 'Tous' ||
           _servicesFilter.isNotEmpty;
  }
}