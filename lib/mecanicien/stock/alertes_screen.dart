import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mouvement.dart';
import 'package:garagelink/providers/mouvement_provider.dart';
import 'package:garagelink/providers/stock_provider.dart';



class AlertesScreen extends ConsumerWidget {
const AlertesScreen({super.key});


@override
Widget build(BuildContext context, WidgetRef ref) {
final alertes = ref.watch(stockProvider);


return Scaffold(
appBar: AppBar(title: const Text('Alertes stock')),
body: ListView.separated(
itemCount: alertes.length,
separatorBuilder: (_, __) => const Divider(height: 1),
itemBuilder: (context, index) {
final a = alertes[index];
return ListTile(
leading: const Icon(Icons.warning, color: Colors.red),
title: Text('${a.piece.nom} (Qt: ${a.piece.quantite})'),
subtitle: Text('Min: ${a.seuilMin}${a.seuilMax != null ? ' | Max: ${a.seuilMax}' : ''}'),
trailing: Wrap(
spacing: 8,
children: [
TextButton(
onPressed: () {
// Quick réapprovisionnement (ex: +10)
final m = Mouvement(
id: DateTime.now().millisecondsSinceEpoch.toString(),
pieceId: a.piece.id,
type: TypeMouvement.entree,
quantite: 10,
date: DateTime.now(),
notes: 'Réapprovisionnement rapide',
);
ref.read(mouvementProvider.notifier).addMouvement(m);
},
child: const Text('Réappro'),
),
TextButton(
onPressed: () {
// TODO: brancher avec un provider de notifications
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification envoyée (mock)')));
},
child: const Text('Notifier'),
),
],
),
);
},
),
);
}
}