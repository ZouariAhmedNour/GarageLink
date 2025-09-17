import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/create_order_screen.dart';
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/providers/ordres_provider.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkOrderPage extends ConsumerStatefulWidget {
  const WorkOrderPage({super.key});

  @override
  ConsumerState<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends ConsumerState<WorkOrderPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _ordreStatusLabel(OrdreTravail o) {
    switch (o.status) {
      case OrdreStatus.enAttente:
        return 'En attente';
      case OrdreStatus.enCours:
        return 'En cours';
      case OrdreStatus.termine:
        return 'Terminé';
      case OrdreStatus.suspendu:
        return 'Suspendu';
      case OrdreStatus.supprime:
        return 'Supprimé';
    }
  }

  String _labelToApiStatus(String label) {
    switch (label) {
      case 'En attente':
        return 'en_attente';
      case 'En cours':
        return 'en_cours';
      case 'Terminé':
        return 'termine';
      case 'Suspendu':
        return 'suspendu';
      case 'Supprimé':
        return 'supprime';
      default:
        return 'en_attente';
    }
  }

  List<OrdreTravail> _getFilteredOrders(List<OrdreTravail> ordres) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = ordres.where((ordre) {
      final statusLabel = _ordreStatusLabel(ordre);
      final matchesFilter = _selectedFilter == 'Tous' || statusLabel == _selectedFilter;
      final matchesSearch = q.isEmpty ||
          ordre.id?.toLowerCase().contains(q) == true ||
          ordre.clientInfo.nom.toLowerCase().contains(q) ||
          ordre.numeroOrdre.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();

    filtered.sort((a, b) => b.dateCommence.compareTo(a.dateCommence));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final ordresState = ref.watch(ordresProvider);
    final ordres = ordresState.ordres;
    final filteredOrdres = _getFilteredOrders(ordres);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  children: [
                    _buildStatsCards(ordres),
                    const SizedBox(height: 20),
                    _buildSearchAndFilters(),
                    const SizedBox(height: 20),
                    _buildOrdersList(filteredOrdres),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateOrderScreen()),
        backgroundColor: const Color(0xFF357ABD),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvel ordre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Ordres de travail',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF357ABD), Color(0xFF357ABD)],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF357ABD),
      elevation: 0,
    );
  }

  Widget _buildStatsCards(List<OrdreTravail> ordres) {
    final enAttente = ordres.where((o) => o.status == OrdreStatus.enAttente).length;
    final enCours = ordres.where((o) => o.status == OrdreStatus.enCours).length;
    final termines = ordres.where((o) => o.status == OrdreStatus.termine).length;

    final stats = {
      'En attente': enAttente,
      'En cours': enCours,
      'Terminé': termines,
    };

    return Row(
      children: stats.entries
          .map((entry) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text('${entry.value}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      Text(entry.key, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un ordre...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              items: ['Tous', 'En attente', 'En cours', 'Terminé', 'Suspendu']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedFilter = value ?? 'Tous'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<OrdreTravail> ordres) {
    if (ordres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun ordre trouvé', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Essayez de modifier vos critères de recherche', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ModernCard(
      title: 'Liste des ordres (${ordres.length})',
      icon: Icons.assignment,
      borderColor: const Color(0xFF357ABD),
      child: Column(
        children: ordres.map((ordre) {
          final statusLabel = _ordreStatusLabel(ordre);
          final clientName = ordre.clientInfo.nom;
          final mecanicien = ordre.taches.isNotEmpty ? ordre.taches.first.mecanicienNom : '—';
          final atelier = ordre.atelierNom;
          final dateStr = ordre.dateCommence.toLocal().toString().substring(0, 16);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(child: Text('${ordre.numeroOrdre} • $clientName', style: const TextStyle(fontWeight: FontWeight.w600))),
                  _buildStatusChip(statusLabel),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('🔧 $mecanicien', style: TextStyle(color: Colors.grey[600])),
                  Text('🏭 $atelier • 📅 $dateStr', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleOrderAction(context, ref, ordre, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Modifier')])),
                  const PopupMenuItem(value: 'call', child: Row(children: [Icon(Icons.phone), SizedBox(width: 8), Text('Appeler')])),
                  const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.description), SizedBox(width: 8), Text('Rapport')])),
                ],
              ),
              onTap: () => _editOrderStatus(context, ref, ordre),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'En attente': {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFF92400E)},
      'En cours': {'bg': const Color(0xFFDCFDF7), 'text': const Color(0xFF115E59)},
      'Terminé': {'bg': const Color(0xFFD1FAE5), 'text': const Color(0xFF047857)},
      'Suspendu': {'bg': const Color(0xFFF3F4F6), 'text': const Color(0xFF374151)},
    };

    final c = colors[status] ?? colors['En attente']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c['bg'] as Color, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: c['text'] as Color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  void _handleOrderAction(BuildContext context, WidgetRef ref, OrdreTravail ordre, String action) async {
    switch (action) {
      case 'edit':
        _editOrderStatus(context, ref, ordre);
        break;
      case 'call':
        try {
          final uri = Uri.parse('tel:${ordre.clientInfo.telephone ?? ''}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lancer l\'appel')));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro introuvable')));
        }
        break;
    }
  }

  void _editOrderStatus(BuildContext context, WidgetRef ref, OrdreTravail ordre) {
    String statusLabel = _ordreStatusLabel(ordre);
    final clientName = ordre.clientInfo.nom.isNotEmpty ? ordre.clientInfo.nom : 'Client';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier $clientName'),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButton<String>(
            value: statusLabel,
            isExpanded: true,
            items: ['En attente', 'En cours', 'Terminé', 'Suspendu']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => statusLabel = v ?? statusLabel),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            onPressed: () async {
              final apiStatus = _labelToApiStatus(statusLabel);
              if (ordre.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordre sans identifiant')));
                Navigator.pop(context);
                return;
              }
              await ref.read(ordresProvider.notifier).updateStatus(ordre.id!, apiStatus);
              Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }
}
