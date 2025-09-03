import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/default_app_bar.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/mecanicien/Gestion%20Clients/add_client.dart';
import 'package:garagelink/vehicules/add_veh.dart';
import 'package:garagelink/vehicules/vehicule_info.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/models/client.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/client_provider.dart';
import 'package:garagelink/providers/orders_provider.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ClientDash extends ConsumerStatefulWidget {
  const ClientDash({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientDash> createState() => _ClientDashState();
}

enum TypeFiltre { nom, immatriculation, periode }

class _ClientDashState extends ConsumerState<ClientDash> 
    with SingleTickerProviderStateMixin {
  static const primaryColor = Color(0xFF357ABD);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardColor = Colors.white;
  static const successColor = Color(0xFF38A169);
  static const errorColor = Color(0xFFE53E3E);

  late AnimationController _animationController;
Animation<double>? _fadeAnimation;
Animation<Offset>? _slideAnimation;

  int selectedIndex = 0;
  String nomFilter = '';
  String immatFilter = '';
  DateTimeRange? dateRangeFilter;
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    vinCtrl.dispose();
    numLocalCtrl.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : primaryColor),
        label: Text(label, style: TextStyle(
          color: selected ? Colors.white : primaryColor,
          fontWeight: FontWeight.w600,
        )),
        selected: selected,
        selectedColor: primaryColor,
        backgroundColor: cardColor,
        side: BorderSide(color: selected ? primaryColor : Colors.grey[300]!),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }

  Widget _buildSearchCard(Widget child) {
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildTextField(String label, IconData icon, ValueChanged<String> onChanged) {
    return TextField(
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) {
        HapticFeedback.selectionClick();
        onChanged(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientsProvider);
    final vehState = ref.watch(vehiculesProvider);
    final ordersState = ref.watch(ordersProvider);

    final filtered = clientsState.clients.where((c) {
      bool matches = true;
      if (selectedIndex == 0) {
        matches = nomFilter.isEmpty || c.nomComplet.toLowerCase().contains(nomFilter.toLowerCase());
      } else if (selectedIndex == 1) {
        matches = immatFilter.isEmpty || c.vehiculeIds.any((vid) => vid.toLowerCase().contains(immatFilter.toLowerCase()));
      } else if (selectedIndex == 2) {
        final clientOrders = ordersState.where((o) => o.clientId == c.id).toList();
        matches = dateRangeFilter == null || clientOrders.any((o) =>
          o.date.isAfter(dateRangeFilter!.start.subtract(const Duration(days: 1))) &&
          o.date.isBefore(dateRangeFilter!.end.add(const Duration(days: 1))));
      }
      return matches;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
    appBar: CustomAppBar(
  title: 'Clients',
  backgroundColor: primaryColor,
),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () {
          HapticFeedback.lightImpact();
          Get.to(() => const AddClientScreen());
        },
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
     body: _fadeAnimation == null || _slideAnimation == null
  ? const SizedBox.shrink()
  : FadeTransition(
      opacity: _fadeAnimation!,
      child: SlideTransition(
        position: _slideAnimation!,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text('Filtres', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Nom', Icons.person, selectedIndex == 0, 
                              () => setState(() => selectedIndex = 0)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Immatriculation', Icons.directions_car, selectedIndex == 1, 
                              () => setState(() => selectedIndex = 1)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Période', Icons.date_range, selectedIndex == 2, 
                              () => setState(() => selectedIndex = 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchInterface(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (dateRangeFilter != null) 
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text('${DateFormat('dd/MM/yyyy').format(dateRangeFilter!.start)} → ${DateFormat('dd/MM/yyyy').format(dateRangeFilter!.end)}',
                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: primaryColor, size: 18),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => dateRangeFilter = null);
                          },
                        ),
                      ],
                    ),
                  ),
                if (dateRangeFilter != null) const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Aucun client trouvé', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final c = filtered[idx];
                          final clientVeh = vehState.vehicules.where((v) => v.clientId == c.id).toList();
                          return ClientCard(client: c, vehicules: clientVeh, index: idx);
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInterface() {
    switch (selectedIndex) {
      case 0:
        return _buildTextField('Rechercher par nom', Icons.person_search, (v) => setState(() => nomFilter = v));
      case 1:
        return NumeroSerieInput(
          vinCtrl: vinCtrl,
          numLocalCtrl: numLocalCtrl,
          onChanged: (val) => setState(() => immatFilter = val),
        );
      case 2:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          icon: const Icon(Icons.date_range),
          label: Text(dateRangeFilter == null ? 'Sélectionner période' :
            '${DateFormat('dd/MM/yyyy').format(dateRangeFilter!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRangeFilter!.end)}'),
          onPressed: () => _pickDateRange(),
        );
      default:
        return Container();
    }
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: dateRangeFilter,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => dateRangeFilter = picked);
  }
}

class ClientCard extends ConsumerStatefulWidget {
  final Client client;
  final List<Vehicule> vehicules;
  final int index;
  const ClientCard({required this.client, required this.vehicules, required this.index, Key? key}) : super(key: key);

  @override
  ConsumerState<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends ConsumerState<ClientCard> with SingleTickerProviderStateMixin {
  bool expanded = false;
  static const primaryColor = Color(0xFF357ABD);
  static const successColor = Color(0xFF38A169);
  static const errorColor = Color(0xFFE53E3E);
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  // Bouton d'action compact et contraint
  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed, {String? tooltip}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36, maxWidth: 44),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          padding: const EdgeInsets.all(6),
          iconSize: 18,
          icon: Icon(icon, color: color, size: 18),
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          tooltip: tooltip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      child: Card(
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.client.categorie == Categorie.particulier 
                      ? [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.2)]
                      : [successColor.withOpacity(0.1), successColor.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.client.categorie == Categorie.particulier ? Icons.person : Icons.business,
                  color: widget.client.categorie == Categorie.particulier ? primaryColor : successColor,
                  size: 24,
                ),
              ),
              // Title: ellipsis si trop long
              title: Text(
                widget.client.nomComplet,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Subtitle : téléphone + nb véhicules (texte flexible)
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.client.telephone,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.vehicules.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${widget.vehicules.length} véhicule${widget.vehicules.length > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              // Trailing : FittedBox pour éviter overflow horizontal
              trailing: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.edit, primaryColor,
                      () => Get.toNamed(AppRoutes.editClientScreen, arguments: widget.client),
                      tooltip: 'Modifier',
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      Icons.delete, errorColor,
                      _showDeleteDialog,
                      tooltip: 'Supprimer',
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      Colors.grey[600]!,
                      () {
                        setState(() => expanded = !expanded);
                        if (expanded) _expandController.forward();
                        else _expandController.reverse();
                      },
                      tooltip: expanded ? 'Réduire' : 'Développer',
                    ),
                  ],
                ),
              ),
            ),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Container(),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    _buildInfoRow(Icons.email, 'Email', widget.client.mail),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, 'Adresse', widget.client.adresse),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Véhicules',
                          style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 16),
                        ),
                        _buildActionButton(
                          Icons.add, primaryColor,
                          () => Get.to(() => AddVehScreen(clientId: widget.client.id)),
                          tooltip: 'Ajouter véhicule',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    widget.vehicules.isEmpty 
                      ? Text('Aucun véhicule', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.vehicules.map((v) => 
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Get.to(() => VehiculeInfoScreen(vehiculeId: v.id));
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  '${v.marque} ${v.modele}\n${v.immatriculation}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

 void _showDeleteDialog() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      // TITRE avec icône stylée + texte flexible pour éviter overflow
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF56500).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF56500), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Confirmer la suppression',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      // CONTENU scrollable (préserve l'affichage sur petits écrans)
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Voulez-vous vraiment supprimer le client ',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              TextSpan(
                text: '"${widget.client.nomComplet}"',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const TextSpan(
                text: ' ?',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
      // ACTIONS : deux boutons larges et adaptatifs
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _deleteClient(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  void _deleteClient(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    HapticFeedback.mediumImpact();
    try {
      ref.read(clientsProvider.notifier).removeClient(widget.client.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [Icon(Icons.check, color: Colors.white), SizedBox(width: 8), Text("Client supprimé avec succès")],
          ),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [Icon(Icons.error, color: Colors.white), SizedBox(width: 8), Text("Erreur lors de la suppression")],
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
