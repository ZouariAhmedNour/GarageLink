import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/carnetEntretien/entretien_screen.dart';
import 'package:garagelink/models/carnetEntretien.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/carnetEntretien_provider.dart';
import 'package:garagelink/providers/ordres_provider.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(carnetProvider.notifier).loadForVehicule(vid);
        ref.read(carnetProvider.notifier).loadStats(vid);
        ref.read(ordresProvider.notifier).loadByVehicule(vid);
      });
    }
  }

   Future<void> _onRefresh() async {
    final vid = widget.veh.id;
    if (vid != null && vid.isNotEmpty) {
      await Future.wait([
        ref.read(carnetProvider.notifier).loadForVehicule(vid),
        ref.read(carnetProvider.notifier).loadStats(vid),
        ref.read(ordresProvider.notifier).loadByVehicule(vid),
      ]);
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
            if (!_showCarnet) _buildHistoryList() else _buildCarnetList(),
          ],
        ),
      ),
    );
  }

   Widget _buildHistoryList() {
    final vid = widget.veh.id ?? '';
    final ordresState = ref.watch(ordresProvider);
    final carnetState = ref.watch(carnetProvider); // pour l'état loading/error partagé si souhaité

    // Préférence : utiliser ordresState pour afficher l'historique d'ordres.
    if (ordresState.loading || carnetState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    if (ordresState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              'Erreur: ${ordresState.error}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(ordresProvider.notifier).loadByVehicule(vid),
              child: const Text('Réessayer'),
            )
          ],
        ),
      );
    }

    final visites = ordresState.ordres.where((o) => (o.vehiculedetails.vehiculeId ?? '') == vid).toList();

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
              'Aucun ordre lié à ce véhicule',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(ordresProvider.notifier).loadByVehicule(vid),
              child: const Text('Rafraîchir'),
            )
          ],
        ),
      );
    }

    // Tri décroissant par dateCommence
    final sorted = [...visites];
    sorted.sort((a, b) => b.dateCommence.compareTo(a.dateCommence));

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        itemCount: sorted.length,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = sorted[index];
          final dateStr = formatDate(e.dateCommence);
          final service = e.taches.isNotEmpty ? e.taches.first.serviceNom : e.description ?? '—';
          final atelier = e.atelierNom;
          final progression = '${e.progressionPourcentage}%';
          final status = e.status.toString().split('.').last;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.precision_manufacturing, color: primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ordre: ${e.numeroOrdre.isNotEmpty ? e.numeroOrdre : e.devisId}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(service, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text(atelier, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, color: primaryBlue)),
                    const SizedBox(height: 6),
                    Text('$progression', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(status, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildCarnetList() {
    final carnetState = ref.watch(carnetProvider);
    final vehId = widget.veh.id ?? '';
    final List<CarnetEntretien> entries = carnetState.historique[vehId] ?? [];

    if (carnetState.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

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

    final sorted = [...entries];
    sorted.sort((a, b) => b.dateCommencement.compareTo(a.dateCommencement));

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
    backgroundColor: Colors.white, // 👈 force le fond en blanc
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Row(
      children: [
        const Icon(Icons.warning, color: errorRed),
        const SizedBox(width: 12),
        Expanded( // 👈 évite l’overflow en coupant le texte
          child: Text(
            "Supprimer l'intervention",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: darkBlue,
            ),
            overflow: TextOverflow.ellipsis, // coupe si trop long
          ),
        ),
      ],
    ),
    content: const Text(
      'Confirmez la suppression de cette intervention. '
      'Cette action est irréversible.',
      style: TextStyle(fontSize: 15, color: Colors.black87),
    ),
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
