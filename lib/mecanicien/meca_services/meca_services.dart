// mecanicien/meca_services/meca_services.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/service_provider.dart';
import 'package:garagelink/mecanicien/meca_services/service_card.dart';
import 'package:garagelink/mecanicien/meca_services/add_edit_service_screen.dart';

class MecaServicesPage extends ConsumerStatefulWidget {
  const MecaServicesPage({super.key});

  @override
  ConsumerState<MecaServicesPage> createState() => _MecaServicesPageState();
}

class _MecaServicesPageState extends ConsumerState<MecaServicesPage>
    with TickerProviderStateMixin {
  String searchTerm = '';
  bool showActiveOnly = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Service> _getFilteredServices(List<Service> services) {
    final filtered = services.where((s) {
      final matchesSearch = searchTerm.isEmpty ||
          s.nomService.toLowerCase().contains(searchTerm.toLowerCase()) ||
          s.description.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesActive = !showActiveOnly || s.status == ServiceStatus.actif;
      return matchesSearch && matchesActive;
    }).toList();

    filtered.sort((a, b) => a.nomService.compareTo(b.nomService));
    return filtered;
  }

  Map<String, int> _getServiceStats(List<Service> services) {
    return {
      'total': services.length,
      'actifs': services.where((s) => s.status == ServiceStatus.actif).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceProvider);
    final filteredServices = _getFilteredServices(services);
    final stats = _getServiceStats(services);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
  title: 'Gestion des services',
  backgroundColor: const Color(0xFF357ABD), // ou la couleur que tu veux
),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard('Total', '${stats['total']}', Icons.build,
                            const Color(0xFF357ABD)),
                        const SizedBox(width: 12),
                        _buildStatCard('Actifs', '${stats['actifs']}', Icons.check_circle,
                            const Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSearchAndFilters(),
                    const SizedBox(height: 20),
                    _buildServicesList(filteredServices, screenWidth),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (c) => const AddEditServiceScreen())),
        backgroundColor: const Color(0xFF357ABD),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau service',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchTerm = value),
          decoration: InputDecoration(
            hintText: 'Rechercher un service...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            suffixIcon: searchTerm.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      searchTerm = '';
                    }),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('Trier par: Nom'),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: showActiveOnly,
                    onChanged: (value) => setState(() => showActiveOnly = value ?? false),
                    activeColor: const Color(0xFF357ABD),
                  ),
                  const Text('Actifs uniquement', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesList(List<Service> services, double screenWidth) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun service trouvé', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Essayez de modifier vos critères de recherche', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF357ABD).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.build, color: Color(0xFF357ABD), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text('Services disponibles (${services.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 768 ? 2 : 1,
              childAspectRatio: screenWidth > 768 ? 2.8 : 2.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceCard(
                service: service,
                onEdit: () => _showEditBottomSheet(service),
                onDelete: () => _showDeleteDialog(service),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditBottomSheet(Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => AddEditServiceScreen(service: service),
      ),
    );
  }

  void _showDeleteDialog(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le service'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${service.nomService}" ?\nCette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(serviceProvider.notifier).deleteService(service.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Service "${service.nomService}" supprimé'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
