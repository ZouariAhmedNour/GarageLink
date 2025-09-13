import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/carnetEntretien/entretien_screen.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/carnet_provider.dart';
import 'ui_constants.dart';
import 'package:intl/intl.dart';
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
  Widget build(BuildContext context) {
    final veh = widget.veh;
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ToggleButtons(
                    isSelected: [_showCarnet == false, _showCarnet == true],
                    onPressed: (index) => setState(() => _showCarnet = index == 1),
                    borderRadius: BorderRadius.circular(8),
                    borderWidth: 1,
                    constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Historique')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Carnet d\'entretien')),
                    ],
                  ),
                ),
              ),
            ),
            if (_showCarnet) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                  onPressed: () {
                    Get.to(() => EntretienScreen(vehiculeId: veh.id));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          if (!_showCarnet)
            _buildFakeHistory()
          else
            _buildCarnetList(),
        ]),
      ),
    );
  }

  Widget _buildFakeHistory() {
    final visites = [
      {'date': '12/01/2024', 'desc': 'Vidange moteur', 'atelier': 'Atelier Central', 'type': 'maintenance'},
      {'date': '23/05/2024', 'desc': 'Révision complète', 'atelier': 'Garage Pro', 'type': 'revision'},
      {'date': '15/08/2024', 'desc': 'Changement plaquettes', 'atelier': 'Atelier Central', 'type': 'reparation'},
    ];

    return ListView.separated(
      itemCount: visites.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final visite = visites[index];
        final isMaintenence = visite['type'] == 'maintenance';
        final isRevision = visite['type'] == 'revision';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRevision ? accentOrange.withOpacity(0.3) : isMaintenence ? successGreen.withOpacity(0.3) : primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRevision ? accentOrange.withOpacity(0.2) : isMaintenence ? successGreen.withOpacity(0.2) : lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(isRevision ? Icons.build_circle : isMaintenence ? Icons.oil_barrel : Icons.build,
                  color: isRevision ? accentOrange : isMaintenence ? successGreen : primaryBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(visite['desc']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkBlue)),
              const SizedBox(height: 4),
              Text(visite['atelier']!, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ])),
            Text(visite['date']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue)),
          ]),
        );
      },
    );
  }

  Widget _buildCarnetList() {
  final map = ref.watch(carnetProvider);
  final entries = map[widget.veh.id] ?? [];
  const primaryBlue = Color(0xFF357ABD);
  
  if (entries.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
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
        Text('Aucune intervention enregistrée', 
             style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      ]),
    );
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: entries.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, i) {
      final e = entries[i];
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
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded( 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.tache, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${DateFormat.yMd().format(e.dateOperation)} • ${e.service}', 
                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${e.coutTotal.toStringAsFixed(2)} DT', 
                 style: const TextStyle(fontWeight: FontWeight.w700, color: primaryBlue, fontSize: 16)),
            const SizedBox(height: 8),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: primaryBlue),
                onPressed: () => Get.to(() => EntretienScreen(vehiculeId: widget.veh.id, initial: e)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Row(children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer ?')
                      ]),
                      content: const Text('Confirmez la suppression de cette intervention.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), 
                                 child: const Text('Annuler')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    ref.read(carnetProvider.notifier).removeEntry(widget.veh.id, e.idOperation);
                  }
                },
              ),
            ])
          ])
        ]),
      );
    },
  );
}
}
