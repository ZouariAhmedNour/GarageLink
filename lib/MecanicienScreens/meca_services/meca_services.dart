import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/meca_services/add_edit_service_screen.dart';
import 'package:garagelink/MecanicienScreens/meca_services/service_card.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/service_provider.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:get/get.dart';

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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

   

    // Load services on init
     WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(serviceProvider.notifier).loadAll();
  });
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
          s.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
          s.description.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesActive = !showActiveOnly || s.statut == ServiceStatut.actif;
      return matchesSearch && matchesActive;
    }).toList();

    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
  }

  Map<String, int> _getServiceStats(List<Service> services) {
    return {
      'total': services.length,
      'actifs': services.where((s) => s.statut == ServiceStatut.actif).length,
    };
  }

  @override
  Widget build(BuildContext context) {
     // Écoute des erreurs pour afficher un snackbar automatiquement
    ref.listen<ServicesState>(serviceProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${next.error}'),
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    });
    final serviceState = ref.watch(serviceProvider);
    final filteredServices = _getFilteredServices(serviceState.services);
    final stats = _getServiceStats(serviceState.services);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: CustomAppBar(
        title: 'Gestion des services',
        backgroundColor: primaryBlue,
      ),
      body: serviceState.loading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : serviceState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
                      const SizedBox(height: 12),
                      Text(
                        'Erreur: ${serviceState.error}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildStatCard('Total', '${stats['total']}', Icons.build, primaryBlue),
                                  const SizedBox(width: 12),
                                  _buildStatCard('Actifs', '${stats['actifs']}', Icons.check_circle, successGreen),
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
  onPressed: () async {
    // Ouvre l'écran en plein écran avec Get et attend le résultat
    final result = await Get.to<bool>(() => const AddEditServiceScreen());
    if (result == true) {
      // Si l'écran enfant a renvoyé true => recharger la liste
      await ref.read(serviceProvider.notifier).loadAll();
    }
  },
  backgroundColor: primaryBlue,
  icon: const Icon(Icons.add, color: Colors.white),
  label: const Text(
    'Nouveau service',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: darkBlue,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: searchTerm.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      searchTerm = '';
                    }),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Trier par: Nom',
                  style: TextStyle(fontSize: 14, color: darkBlue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: showActiveOnly,
                    onChanged: (value) => setState(() => showActiveOnly = value ?? false),
                    activeColor: primaryBlue,
                  ),
                  const Text('Actifs uniquement', style: TextStyle(fontSize: 14, color: darkBlue)),
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
      return Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.build_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucun service trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Services disponibles (${services.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
         Column(
  children: services.map((service) => 
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ServiceCard(
        service: service,
        onEdit: () => _navigateToEdit(service),
        onDelete: () => _showDeleteDialog(service),
      ),
    ),
  ).toList(),
),
        ],
      ),
    );
  }

 Future<void> _navigateToEdit(Service service) async {
  final result = await Get.to<bool>(
    () => AddEditServiceScreen(service: service),
  );

  if (result == true) {
    await ref.read(serviceProvider.notifier).loadAll();
  }
}


  void _showDeleteDialog(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       title: Row(
  children: const [
    Icon(Icons.warning, color: errorRed),
    SizedBox(width: 12),
    Expanded(
      child: Text(
        'Supprimer le service',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkBlue,
        ),
        overflow: TextOverflow.ellipsis, // évite tout débordement
      ),
    ),
  ],
),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${service.name}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (service.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Erreur: ID du service manquant'),
                    backgroundColor: errorRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }
              try {
                await ref.read(serviceProvider.notifier).deleteService(service.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Service "${service.name}" supprimé'),
                    backgroundColor: successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: errorRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
