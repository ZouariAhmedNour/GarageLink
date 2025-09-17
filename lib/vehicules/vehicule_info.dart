
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:garagelink/vehicules/car%20widgets/edit_vehicle_sheet.dart';
import 'package:garagelink/vehicules/car%20widgets/history_and_carnet_section.dart';
import 'package:garagelink/vehicules/car%20widgets/info_row.dart';
import 'package:garagelink/vehicules/car%20widgets/photo_section.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:garagelink/vehicules/car%20widgets/vehicle_header.dart';
import 'package:get/get.dart';

class VehiculeInfoScreen extends ConsumerStatefulWidget {
  final String vehiculeId;
  const VehiculeInfoScreen({required this.vehiculeId, Key? key}) : super(key: key);

  @override
  ConsumerState<VehiculeInfoScreen> createState() => _VehiculeInfoScreenState();
}

class _VehiculeInfoScreenState extends ConsumerState<VehiculeInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Vehicule veh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: errorRed),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le véhicule ${veh.marque} ${veh.modele} (${veh.immatriculation}) ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(ctx).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              if (veh.id == null) return;

              ref.read(vehiculesProvider.notifier).removeVehicule(veh.id!);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppression en cours...')),
              );

              try {
                await ref.read(vehiculesProvider.notifier).removeVehicule(veh.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Véhicule supprimé avec succès'), backgroundColor: successGreen),
                );
                Get.back();
              } catch (e) {
                if (veh.proprietaireId.isNotEmpty) {
                  await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId);
                } else {
                  await ref.read(vehiculesProvider.notifier).loadAll();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: errorRed),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehState = ref.watch(vehiculesProvider);

    Vehicule? veh;
    try {
      veh = vehState.vehicules.firstWhere((v) => v.id == widget.vehiculeId);
    } catch (e) {
      veh = null;
    }

    if (veh == null) {
      return Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
          ),
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

    return Scaffold(
      backgroundColor: surfaceColor,
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
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                toolbarTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
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
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await openEditVehicleSheet(context, ref, veh!);
                    },
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _confirmDelete(context, ref, veh!);
                    },
                    tooltip: 'Supprimer',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${veh.marque} ${veh.modele}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryBlue, darkBlue],
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
                      VehicleHeader(veh: veh),
                      const SizedBox(height: 20),
                      Card(
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
                                  Icon(Icons.info, color: primaryBlue, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Informations détaillées',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkBlue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              InfoRow(label: 'Immatriculation', value: veh.immatriculation, icon: Icons.confirmation_number),
                              InfoRow(label: 'Marque', value: veh.marque, icon: Icons.business),
                              InfoRow(label: 'Modèle', value: veh.modele, icon: Icons.directions_car),
                              InfoRow(label: 'Carburant', value: fuelTypeLabel(veh.typeCarburant), icon: fuelTypeIcon(veh.typeCarburant)),
                              InfoRow(label: 'Année de fabrication', value: veh.annee?.toString() ?? '-', icon: Icons.calendar_today),
                              InfoRow(
                                label: 'Kilométrage',
                                value: veh.kilometrage != null ? '${veh.kilometrage!.toString()} km' : '-',
                                icon: Icons.speed,
                                valueColor: accentOrange,
                              ),
                              InfoRow(label: 'Créé le', value: formatDate(veh.createdAt), icon: Icons.event),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PhotoSection(veh: veh),
                      const SizedBox(height: 20),
                      HistoryCarnetSection(veh: veh),
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
}
