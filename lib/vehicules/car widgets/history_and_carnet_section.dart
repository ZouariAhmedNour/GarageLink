import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/carnetEntretien/entretien_screen.dart';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/carnetEntretien_provider.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:get/get.dart';

class HistoryCarnetSection extends ConsumerStatefulWidget {
  final Vehicule veh;
  const HistoryCarnetSection({required this.veh, Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryCarnetSection> createState() => _HistoryCarnetSectionState();
}

class _HistoryCarnetSectionState extends ConsumerState<HistoryCarnetSection> {
  bool _showCarnet = false;

  @override
  void initState() {
    super.initState();
    final vid = widget.veh.id;
    if (vid != null && vid.isNotEmpty) {
      // Charger l'historique après que le widget soit monté
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(carnetProvider.notifier).loadForVehicule(vid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final veh = widget.veh;
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
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: ToggleButtons(
                        isSelected: [!_showCarnet, _showCarnet],
                        onPressed: (index) => setState(() => _showCarnet = index == 1),
                        borderRadius: BorderRadius.circular(12),
                        borderWidth: 1,
                        borderColor: Colors.grey.shade300,
                        selectedBorderColor: primaryBlue,
                        fillColor: lightBlue,
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Historique', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Carnet d\'entretien', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showCarnet) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                      onPressed: () {
                        final vid = veh.id;
                        if (vid == null || vid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Identifiant véhicule manquant')),
                          );
                          return;
                        }
                        Get.to(() => EntretienScreen(vehiculeId: vid, initial: null));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: const BorderSide(color: primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (!_showCarnet)
              _buildHistoryList()
            else
              _buildCarnetList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // exemple statique — tu peux remplacer par un fetch si besoin
    final List<Map<String, dynamic>> visites = [
      {
        'date': DateTime(2024, 1, 12),
        'desc': 'Vidange moteur',
        'atelier': 'Atelier Central',
        'type': 'maintenance',
      },
      {
        'date': DateTime(2024, 5, 23),
        'desc': 'Révision complète',
        'atelier': 'Garage Pro',
        'type': 'revision',
      },
      {
        'date': DateTime(2024, 8, 15),
        'desc': 'Changement plaquettes',
        'atelier': 'Atelier Central',
        'type': 'reparation',
      },
    ];

    if (visites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique disponible',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: visites.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visite = visites[index];
        final String desc = (visite['desc'] as String?) ?? '—';
        final String atelier = (visite['atelier'] as String?) ?? '';
        final DateTime? date = visite['date'] as DateTime?;
        final String type = (visite['type'] as String?) ?? '';

        final bool isMaintenance = type == 'maintenance';
        final bool isRevision = type == 'revision';
        final IconData icon = isRevision
            ? Icons.build_circle
            : isMaintenance
                ? Icons.oil_barrel
                : Icons.build;
        final Color iconColor = isRevision
            ? accentOrange
            : isMaintenance
                ? successGreen
                : primaryBlue;
        final Color bgColor = isRevision
            ? accentOrange.withOpacity(0.2)
            : isMaintenance
                ? successGreen.withOpacity(0.2)
                : lightBlue;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      atelier,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                formatDate(date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCarnetList() {
    final carnetState = ref.watch(carnetProvider);
    final vehId = widget.veh.id ?? '';
    final List<CarnetEntretien> entries = carnetState.historique[vehId] ?? [];

    // Loading
    if (carnetState.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    // Erreur
    if (carnetState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              'Erreur: ${carnetState.error}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune intervention enregistrée',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // tri décroissant par dateCommencement
    final sorted = [...entries];
    sorted.sort((a, b) {
      final da = a.dateCommencement;
      final db = b.dateCommencement;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = sorted[index];

        final service = (entry.services.isNotEmpty ? (entry.services.first.description ?? '') : '');
        final tache = (entry.services.isNotEmpty
            ? (entry.services.first.nom ?? entry.notes ?? '')
            : (entry.notes ?? ''));
        final dateStr = formatDate(entry.dateCommencement);
        final double montant = entry.totalTTC;
        final int? km = entry.kilometrageEntretien;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(fuelTypeIcon(widget.veh.typeCarburant), color: primaryBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tache,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • ${service.isNotEmpty ? service : '—'}${km != null ? ' • ${km} km' : ''}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${montant.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: primaryBlue),
                        onPressed: () {
                          final vid = widget.veh.id;
                          if (vid == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ID véhicule manquant')),
                            );
                            return;
                          }
                          Get.to(() => EntretienScreen(vehiculeId: vid, initial: entry));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: errorRed),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: const [
                                  Icon(Icons.warning, color: errorRed),
                                  SizedBox(width: 12),
                                  Text('Supprimer l\'intervention'),
                                ],
                              ),
                              content: const Text('Confirmez la suppression de cette intervention. Cette action est irréversible.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: errorRed,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (ok == true) {
                            final carnetId = entry.id;
                            if (carnetId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Identifiant de l\'intervention manquant')),
                              );
                              return;
                            }

                            try {
                              await ref.read(carnetProvider.notifier).supprimerEntree(widget.veh.id ?? '', carnetId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Intervention supprimée avec succès'),
                                  backgroundColor: successGreen,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: errorRed,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
