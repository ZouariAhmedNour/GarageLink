// lib/screens/vehicule_info.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/global.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:garagelink/services/vehicule_api.dart';
import 'package:garagelink/vehicules/car%20widgets/edit_vehicle_sheet.dart';
import 'package:garagelink/vehicules/car%20widgets/history_and_carnet_section.dart';
import 'package:garagelink/vehicules/car%20widgets/info_row.dart';
import 'package:garagelink/vehicules/car%20widgets/photo_section.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:garagelink/vehicules/car%20widgets/vehicle_header.dart';
import 'package:get/get.dart';

import '../models/vehicule.dart';

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

  /// Dialog + logique de suppression dynamique (optimistic + rollback)
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

              // Optimistic local remove
              ref.read(vehiculesProvider.notifier).removeVehicule(veh.id);

              Navigator.of(ctx).pop(); // ferme le dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppression en cours...')),
              );

              try {
                final api = VehiculeApi(baseUrl: UrlApi);
                final res = await api.deleteVehicule(veh.id);

                if (res['success'] == true) {
                  // Rafraîchir la liste du propriétaire (si existant) pour garder l'état cohérent
                  if ((veh.proprietaireId ?? '').isNotEmpty) {
                    await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId!);
                  } else {
                    // fallback : reload all
                    await ref.read(vehiculesProvider.notifier).loadAll();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Véhicule supprimé avec succès'), backgroundColor: successGreen),
                  );
                  // revenir à l'écran précédent
                  Get.back();
                } else {
                  // rollback en rechargeant depuis le serveur
                  if ((veh.proprietaireId ?? '').isNotEmpty) {
                    await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId!);
                  } else {
                    await ref.read(vehiculesProvider.notifier).loadAll();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur suppression: ${res['message'] ?? 'inconnue'}'), backgroundColor: errorRed),
                  );
                }
              } catch (e) {
                // rollback: reload
                if ((veh.proprietaireId ?? '').isNotEmpty) {
                  await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId!);
                } else {
                  await ref.read(vehiculesProvider.notifier).loadAll();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur réseau: ${e.toString()}'), backgroundColor: errorRed),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // utilitaire locale pour formater une date en dd/mm/yyyy
  String formatDate(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  // petits helpers locaux pour carburant
  String carburantLabel(Carburant? c) {
    if (c == null) return '-';
    switch (c) {
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

  IconData carburantIcon(Carburant? c) {
    if (c == null) return Icons.local_gas_station;
    switch (c) {
      case Carburant.essence:
        return Icons.local_gas_station;
      case Carburant.diesel:
        return Icons.oil_barrel;
      case Carburant.gpl:
        return Icons.propane_tank;
      case Carburant.electrique:
        return Icons.electric_bolt;
      case Carburant.hybride:
        return Icons.battery_charging_full;
    }
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

    // si on est ici, veh est non-null
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
                  // Edition dynamique (compatible with openEditVehicleSheet returning void OR Vehicule)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      HapticFeedback.lightImpact();

                      // 1) open sheet (may return void). We don't assign its return value to avoid 'void' assignment error.
                      await openEditVehicleSheet(context, ref, veh!);

                      // 2) after the sheet closes, try to fetch the (possibly) updated vehicle from the provider
                      final updatedVeh = ref.read(vehiculesProvider.notifier).getById(veh.id) ?? veh;

                      // If nothing changed, we can skip server update.
                      final bool changedLocally = updatedVeh.marque != veh.marque ||
                          updatedVeh.modele != veh.modele ||
                          updatedVeh.immatriculation != veh.immatriculation ||
                          updatedVeh.annee != veh.annee ||
                          updatedVeh.kilometrage != veh.kilometrage ||
                          (updatedVeh.carburant?.name ?? '') != (veh.carburant?.name ?? '') ||
                          updatedVeh.image != veh.image ||
                          (updatedVeh.proprietaireId ?? '') != (veh.proprietaireId ?? '');

                      if (!changedLocally) {
                        // nothing to do
                        return;
                      }

                      // Optional optimistic: we assume the sheet already updated the provider.
                      // Send updated data to API and handle rollback on error.
                      try {
                        final api = VehiculeApi(baseUrl: UrlApi);
                        final apiRes = await api.updateVehicule(updatedVeh.id, {
                          'marque': updatedVeh.marque,
                          'modele': updatedVeh.modele,
                          'immatriculation': updatedVeh.immatriculation,
                          if (updatedVeh.annee != null) 'annee': updatedVeh.annee,
                          if (updatedVeh.kilometrage != null) 'kilometrage': updatedVeh.kilometrage,
                          if ((updatedVeh.carburant?.name ?? '').isNotEmpty) 'typeCarburant': updatedVeh.carburant!.name,
                          if (updatedVeh.image != null) 'image': updatedVeh.image,
                          if (updatedVeh.proprietaireId != null) 'proprietaireId': updatedVeh.proprietaireId,
                        });

                        if (apiRes['success'] == true && apiRes['data'] != null) {
                          final serverVeh = apiRes['data'] is Vehicule
                              ? apiRes['data'] as Vehicule
                              : Vehicule.fromMap(Map<String, dynamic>.from(apiRes['data']));
                          // Update cache with authoritative server version
                          ref.read(vehiculesProvider.notifier).updateVehicule(serverVeh.id, serverVeh);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Véhicule mis à jour'), backgroundColor: successGreen),
                          );

                          // If owner changed, refresh lists for both owners
                          if ((serverVeh.proprietaireId ?? '') != (veh.proprietaireId ?? '')) {
                            if ((veh.proprietaireId ?? '').isNotEmpty) {
                              await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId!);
                            }
                            if ((serverVeh.proprietaireId ?? '').isNotEmpty) {
                              await ref.read(vehiculesProvider.notifier).loadByProprietaire(serverVeh.proprietaireId!);
                            }
                          }
                        } else {
                          // API failed: rollback by reloading
                          if ((veh.proprietaireId ?? '').isNotEmpty) {
                            await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId!);
                          } else {
                            await ref.read(vehiculesProvider.notifier).loadAll();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur mise à jour: ${apiRes['message'] ?? 'inconnue'}'), backgroundColor: errorRed),
                          );
                        }
                      } catch (e) {
                        // network error -> rollback
                        if ((veh.proprietaireId ?? '').isNotEmpty) {
                          await ref.read(vehiculesProvider.notifier).loadByProprietaire(veh.proprietaireId!);
                        } else {
                          await ref.read(vehiculesProvider.notifier).loadAll();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur réseau: ${e.toString()}'), backgroundColor: errorRed),
                        );
                      }
                    },
                    tooltip: 'Modifier',
                  ),

                  // Suppression dynamique
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
                      // Header
                      VehicleHeader(veh: veh),
                      const SizedBox(height: 20),

                      // Informations détaillées
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
                              InfoRow(label: 'Carburant', value: carburantLabel(veh.carburant), icon: carburantIcon(veh.carburant)),
                              InfoRow(label: 'Année de fabrication', value: veh.annee?.toString() ?? '-', icon: Icons.calendar_today),
                              InfoRow(
                                label: 'Kilométrage',
                                value: veh.kilometrage != null ? '${veh.kilometrage!.toString()} km' : '-',
                                icon: Icons.speed,
                                valueColor: accentOrange,
                              ),
                              InfoRow(label: 'Date de première circulation', value: formatDate(veh.dateCirculation), icon: Icons.event),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Photo
                      PhotoSection(veh: veh),
                      const SizedBox(height: 20),

                      // Historique / Carnet
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
