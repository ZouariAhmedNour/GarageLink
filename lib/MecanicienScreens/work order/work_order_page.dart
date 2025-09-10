import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/work%20order/rapport_screen.dart';
import 'package:garagelink/models/order.dart';
import 'package:garagelink/providers/notif_providers.dart';
import 'package:garagelink/providers/orders_provider.dart';
import 'package:garagelink/services/notif_service.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:garagelink/MecanicienScreens/work%20order/create_order_screen.dart';

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

  List<WorkOrder> _getFilteredOrders(List<WorkOrder> orders) {
    var filtered = orders.where((order) {
      final matchesFilter = _selectedFilter == 'Tous' || order.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty || 
          order.clientId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
    
    // Tri par date (plus récent en premier)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final filteredOrders = _getFilteredOrders(orders);
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
                    _buildStatsCards(orders),
                    const SizedBox(height: 20),
                    _buildSearchAndFilters(),
                    const SizedBox(height: 20),
                    _buildOrdersList(filteredOrders),
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

  Widget _buildStatsCards(List<WorkOrder> orders) {
    final stats = {
      'En attente': orders.where((o) => o.status == 'En attente').length,
      'En cours': orders.where((o) => o.status == 'En cours').length,
      'Terminé': orders.where((o) => o.status == 'Terminé').length,
    };

    return Row(
      children: stats.entries.map((entry) => Expanded(
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
      )).toList(),
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
              items: ['Tous', 'En attente', 'En cours', 'Terminé']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<WorkOrder> orders) {
    if (orders.isEmpty) {
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
      title: 'Liste des ordres (${orders.length})',
      icon: Icons.assignment,
      borderColor: const Color(0xFF357ABD),
      child: Column(
        children: orders.map((order) => Container(
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
                Expanded(child: Text('${order.id} - ${order.clientId}', style: const TextStyle(fontWeight: FontWeight.w600))),
                _buildStatusChip(order.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('🔧 ${order.mecanicien}', style: TextStyle(color: Colors.grey[600])),
Text('🏭 ${order.atelier} • 📅 ${order.date.toString().substring(0, 16)}', style: TextStyle(color: Colors.grey[600])),

              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleOrderAction(context, ref, order, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Modifier')])),
                const PopupMenuItem(value: 'call', child: Row(children: [Icon(Icons.phone), SizedBox(width: 8), Text('Appeler')])),
                const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.description), SizedBox(width: 8), Text('Rapport')])),
              ],
            ),
            onTap: () => _editOrderStatus(context, ref, order),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'En attente': {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFF92400E)},
      'En cours': {'bg': const Color(0xFFDCFDF7), 'text': const Color.fromARGB(255, 95, 42, 6)},
      'Terminé': {'bg': const Color(0xFFD1FAE5), 'text': const Color(0xFF047857)},
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: colors[status]!['bg'], borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: colors[status]!['text'], fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  void _handleOrderAction(BuildContext context, WidgetRef ref, WorkOrder order, String action) {
    switch (action) {
      case 'edit': _editOrderStatus(context, ref, order); break;
      case 'call':
  final client = ref.read(notifProvider).firstWhere((c) => c.id == order.clientId);
  launchUrl(Uri.parse('tel:${client.telephone}'));
  break;
      case 'report': Get.to(() => RapportScreen(order: order)); break;
    }
  }

  void _editOrderStatus(BuildContext context, WidgetRef ref, WorkOrder order) {
    String status = order.status;
    final client = ref.read(notifProvider).firstWhere((c) => c.id == order.clientId);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier ${client.nomComplet}'),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButton<String>(
            value: status,
            isExpanded: true,
            items: ['En attente', 'En cours', 'Terminé'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => status = v!),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            onPressed: () async {
              ref.read(ordersProvider.notifier).updateStatus(order.id, status);
              Navigator.pop(context);
              if (status == 'Terminé') _showNotificationDialog(context, order);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, WorkOrder order) {
    final client = ref.read(notifProvider).firstWhere((c) => c.id == order.clientId);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      title: 'Notifier le client',
      desc: 'Voulez-vous envoyer un email ou un SMS au client ?',
      btnCancelText: "SMS",
btnCancelOnPress: () => ShareNotifService.openSmsClient(
  phone: client.telephone,
  message: "Bonjour ${client.nomComplet}, votre véhicule est prêt."
),
btnOkText: "Email",
btnOkOnPress: () async {
  final emailUri = Uri(
    scheme: 'mailto',
    path: client.mail, // ✅ adresse email du client
    queryParameters: {
      'subject': "Votre véhicule est prêt",
      'body': "Bonjour ${client.nomComplet},\n\nVotre véhicule est prêt. Vous pouvez venir le récupérer.",
    },
  );
  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }
},
    ).show();
  }
}