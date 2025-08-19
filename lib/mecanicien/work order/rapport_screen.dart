import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/order.dart';
import 'package:garagelink/models/rapport.dart';
import 'package:garagelink/providers/rapport_providers.dart';


class RapportScreen extends ConsumerStatefulWidget {
  final WorkOrder order;

  const RapportScreen({super.key, required this.order});

  @override
  ConsumerState<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends ConsumerState<RapportScreen> {
  final TextEditingController panneCtrl = TextEditingController();
  final TextEditingController piecesCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rapport = ref.read(rapportProvider.notifier).getByOrderId(widget.order.id);
    panneCtrl.text = rapport?.panne ?? '';
    piecesCtrl.text = rapport?.pieces ?? '';
    notesCtrl.text = rapport?.notes ?? '';
  }

  @override
  void dispose() {
    panneCtrl.dispose();
    piecesCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rapport de ${widget.order.client}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: panneCtrl,
              decoration: const InputDecoration(labelText: 'Panne', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: piecesCtrl,
              decoration: const InputDecoration(labelText: 'Pièces remplacées', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final rapport = Rapport(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  orderId: widget.order.id,
                  panne: panneCtrl.text,
                  pieces: piecesCtrl.text,
                  notes: notesCtrl.text,
                );

                ref.read(rapportProvider.notifier).addRapport(rapport);

                Navigator.pop(context, true); // retourne true au WorkOrderPage
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }
}
