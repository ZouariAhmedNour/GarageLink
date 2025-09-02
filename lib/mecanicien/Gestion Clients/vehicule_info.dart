import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class VehiculeInfoScreen extends ConsumerStatefulWidget {
  final String vehiculeId;
  const VehiculeInfoScreen({required this.vehiculeId, Key? key})
    : super(key: key);

  @override
  ConsumerState<VehiculeInfoScreen> createState() => _VehiculeInfoScreenState();
}

class _VehiculeInfoScreenState extends ConsumerState<VehiculeInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Palette de couleurs unifiée
  static const Color _primaryBlue = Color(0xFF357ABD);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _darkBlue = Color(0xFF1976D2);
  static const Color _errorRed = Color(0xFFD32F2F);
  static const Color _successGreen = Color(0xFF388E3C);
  static const Color _surfaceColor = Color(0xFFF8F9FA);
  static const Color _accentOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _getCarburantLabel(Carburant carburant) {
    switch (carburant) {
      case Carburant.essence:
        return 'Essence';
      case Carburant.diesel:
        return 'Diesel';
      case Carburant.gpl:
        return 'GPL';
      case Carburant.electrique:
        return 'Électrique';
      case Carburant.hybride:
        return 'Hybride';
      }
  }

  IconData _getCarburantIcon(Carburant carburant) {
    switch (carburant) {
      case Carburant.essence:
        return Icons.local_gas_station;
      case Carburant.diesel:
        return Icons.oil_barrel;
      case Carburant.gpl:
        return Icons.propane_tank;
      case Carburant.electrique:
        return Icons.electric_bolt;
      case Carburant.hybride:
        return Icons.electric_car;
      }
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.isNotEmpty ? value : '-',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? _darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleHeader(Vehicule veh) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color.fromARGB(255, 234, 236, 238), _darkBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: veh.picKm != null && veh.picKm!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: veh.picKm!.startsWith('http')
                          ? Image.network(veh.picKm!, fit: BoxFit.cover)
                          : Image.file(File(veh.picKm!), fit: BoxFit.cover),
                    )
                  : Icon(Icons.directions_car, size: 50, color: _primaryBlue),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${veh.marque} ${veh.modele}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      veh.immatriculation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getCarburantIcon(veh.carburant),
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCarburantLabel(veh.carburant),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(Vehicule veh) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.camera_alt, color: _primaryBlue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Photo du compteur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: veh.picKm != null && veh.picKm!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Get.to(
                                () =>
                                    FullScreenImageView(imagePath: veh.picKm!),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              child: veh.picKm!.startsWith('http')
                                  ? Image.network(veh.picKm!, fit: BoxFit.cover)
                                  : Image.file(
                                      File(veh.picKm!),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Agrandir',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.no_photography,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune photo disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildHistorySection() {
    final visites = [
      {
        'date': '12/01/2024',
        'desc': 'Vidange moteur',
        'atelier': 'Atelier Central',
        'type': 'maintenance',
      },
      {
        'date': '23/05/2024',
        'desc': 'Révision complète',
        'atelier': 'Garage Pro',
        'type': 'revision',
      },
      {
        'date': '15/08/2024',
        'desc': 'Changement plaquettes',
        'atelier': 'Atelier Central',
        'type': 'reparation',
      },
    ];

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: _primaryBlue, size: 24),
                const SizedBox(width: 12),

                // Laisser le texte occuper l'espace disponible et tronquer si besoin
                Expanded(
                  child: Text(
                    'Historique des interventions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _darkBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Contrainte sur la largeur du badge pour éviter overflow
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accentOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${visites.length} visites',
                      style: const TextStyle(
                        color: _accentOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              itemCount: visites.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final visite = visites[index];
                final isMaintenence = visite['type'] == 'maintenance';
                final isRevision = visite['type'] == 'revision';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRevision
                          ? _accentOrange.withOpacity(0.3)
                          : isMaintenence
                          ? _successGreen.withOpacity(0.3)
                          : _primaryBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isRevision
                              ? _accentOrange.withOpacity(0.2)
                              : isMaintenence
                              ? _successGreen.withOpacity(0.2)
                              : _lightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isRevision
                              ? Icons.build_circle
                              : isMaintenence
                              ? Icons.oil_barrel
                              : Icons.build,
                          color: isRevision
                              ? _accentOrange
                              : isMaintenence
                              ? _successGreen
                              : _primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visite['desc']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _darkBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              visite['atelier']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        visite['date']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Ajouter une intervention'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: _primaryBlue),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fonction "Ajouter intervention" non implémentée',
                      ),
                      backgroundColor: _accentOrange,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehState = ref.watch(vehiculesProvider);
    final maybeVeh = vehState.vehicules.where((v) => v.id == widget.vehiculeId);

    if (maybeVeh.isEmpty) {
      return Scaffold(
        backgroundColor: _surfaceColor,
        appBar: AppBar(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Véhicule non trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final veh = maybeVeh.first;

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                iconTheme: const IconThemeData(color: Colors.white),
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,

                toolbarTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.back();
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _openEditSheet(context, ref, veh);
                    },
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _confirmDelete(context, ref, veh);
                    },
                    tooltip: 'Supprimer',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${veh.marque} ${veh.modele}',
                    style: const TextStyle(
                      color: Colors.white, // <-- force blanc
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryBlue, _darkBlue],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // En-tête du véhicule
                      _buildVehicleHeader(veh),
                      const SizedBox(height: 20),

                      // Informations détaillées
                      Card(
                        elevation: 3,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.info,
                                    color: _primaryBlue,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Informations détaillées',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _darkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                label: 'Immatriculation',
                                value: veh.immatriculation,
                                icon: Icons.confirmation_number,
                              ),
                              _buildInfoRow(
                                label: 'Marque',
                                value: veh.marque,
                                icon: Icons.business,
                              ),
                              _buildInfoRow(
                                label: 'Modèle',
                                value: veh.modele,
                                icon: Icons.directions_car,
                              ),
                              _buildInfoRow(
                                label: 'Carburant',
                                value: _getCarburantLabel(veh.carburant),
                                icon: _getCarburantIcon(veh.carburant),
                              ),
                              _buildInfoRow(
                                label: 'Année de fabrication',
                                value: veh.annee?.toString() ?? '-',
                                icon: Icons.calendar_today,
                              ),
                              _buildInfoRow(
                                label: 'Kilométrage',
                                value: veh.kilometrage != null
                                    ? '${veh.kilometrage!.toString()} km'
                                    : '-',
                                icon: Icons.speed,
                                valueColor: _accentOrange,
                              ),
                              _buildInfoRow(
                                label: 'Date de première circulation',
                                value: _formatDate(veh.dateCirculation),
                                icon: Icons.event,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section photo
                      _buildPhotoSection(veh),
                      const SizedBox(height: 20),

                      // Section historique
                      _buildHistorySection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Vehicule veh) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      // TITLE: icône + texte flexible pour éviter l'overflow
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _errorRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: _errorRed, size: 28),
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
      // CONTENT: scrollable si nécessaire
      content: SingleChildScrollView(
        child: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le véhicule '
          '${veh.marque} ${veh.modele} (${veh.immatriculation}) ?\n\n'
          'Cette action est irréversible.',
          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
        ),
      ),
      // ACTIONS: deux boutons larges dans une Row pour meilleur rendu sur petits écrans
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(ctx).pop();
                },
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
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ref.read(vehiculesProvider.notifier).removeVehicule(veh.id);
                  Navigator.of(ctx).pop();
                  Get.back();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Véhicule supprimé avec succès'),
                      backgroundColor: _successGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorRed,
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

  void _openEditSheet(BuildContext context, WidgetRef ref, Vehicule veh) {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final _marqueCtrl = TextEditingController(text: veh.marque);
        final _modeleCtrl = TextEditingController(text: veh.modele);
        final _anneeCtrl = TextEditingController(
          text: veh.annee?.toString() ?? '',
        );
        final _kmCtrl = TextEditingController(
          text: veh.kilometrage?.toString() ?? '',
        );
        DateTime? _pickedDate = veh.dateCirculation;
        String? _localPicPath = veh.picKm;
        Carburant _selectedCarb = veh.carburant;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Icon(Icons.edit, color: _primaryBlue),
                          SizedBox(width: 12),
                          Text(
                            'Modifier le véhicule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _darkBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Champs de saisie avec style amélioré
                      _buildEditTextField(
                        _marqueCtrl,
                        'Marque',
                        Icons.business,
                      ),
                      _buildEditTextField(
                        _modeleCtrl,
                        'Modèle',
                        Icons.directions_car,
                      ),
                      _buildEditTextField(
                        _anneeCtrl,
                        'Année',
                        Icons.calendar_today,
                        TextInputType.number,
                      ),
                      _buildEditTextField(
                        _kmCtrl,
                        'Kilométrage',
                        Icons.speed,
                        TextInputType.number,
                      ),

                      // Sélecteur de carburant
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.local_gas_station,
                                  color: _primaryBlue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Carburant',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: Carburant.values.map((c) {
                                final isSelected = _selectedCarb == c;
                                return FilterChip(
                                  label: Text(_getCarburantLabel(c)),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedCarb = c);
                                  },
                                  selectedColor: _lightBlue,
                                  checkmarkColor: _primaryBlue,
                                  backgroundColor: Colors.grey.shade100,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Boutons photo et date
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                try {
                                  final XFile? photo = await picker.pickImage(
                                    source: ImageSource.camera,
                                    maxWidth: 1600,
                                    imageQuality: 80,
                                  );
                                  if (photo != null) {
                                    setState(() => _localPicPath = photo.path);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erreur photo: $e')),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _pickedDate != null
                                    ? _formatDate(_pickedDate)
                                    : 'Date',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: _primaryBlue),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: _pickedDate ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(DateTime.now().year + 5),
                                );
                                if (picked != null) {
                                  setState(() => _pickedDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Aperçu photo
                      if (_localPicPath != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_localPicPath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                final updated = veh.copyWith(
                                  marque: _marqueCtrl.text.trim(),
                                  modele: _modeleCtrl.text.trim(),
                                  carburant: _selectedCarb,
                                  annee: int.tryParse(_anneeCtrl.text.trim()),
                                  kilometrage: int.tryParse(
                                    _kmCtrl.text.trim(),
                                  ),
                                  picKm: _localPicPath,
                                  dateCirculation: _pickedDate,
                                );
                                ref
                                    .read(vehiculesProvider.notifier)
                                    .updateVehicule(veh.id, updated);
                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Véhicule modifié avec succès',
                                    ),
                                    backgroundColor: _successGreen,
                                  ),
                                );
                              },
                              child: const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: _surfaceColor,
        ),
      ),
    );
  }
}

/// Écran de visualisation plein écran avec zoom
class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  const FullScreenImageView({required this.imagePath, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.back();
          },
        ),
        title: const Text('Photo du compteur'),
      ),
      body: Center(
        child: Hero(
          tag: imagePath,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: imagePath.startsWith('http')
                ? Image.network(imagePath, fit: BoxFit.contain)
                : Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
