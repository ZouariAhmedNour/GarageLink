import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/piece_provider.dart';
import 'piece_form.dart';
import 'package:get/get.dart';


class CatalogueScreen extends ConsumerStatefulWidget {
const CatalogueScreen({super.key});
@override
ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}


class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
String query = '';
@override
Widget build(BuildContext context) {
final pieces = ref.watch(pieceProvider);
final filtered = pieces.where((p) =>
p.nom.toLowerCase().contains(query.toLowerCase()) ||
p.sku.toLowerCase().contains(query.toLowerCase())
).toList();

return Scaffold(
appBar: AppBar(title: const Text('Catalogue des pièces')),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(8.0),
child: TextField(
decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher par nom ou SKU'),
onChanged: (v) => setState(() => query = v),
),
),
Expanded(
child: ListView.separated(
itemCount: filtered.length,
separatorBuilder: (_, __) => const Divider(height: 1),
itemBuilder: (context, index) {
final p = filtered[index];
return ListTile(
title: Text('${p.sku} • ${p.nom}'),
subtitle: Text('Stock: ${p.quantite} ${p.uom} | PU Achat: ${p.prixAchat.toStringAsFixed(3)}'),
trailing: Text('${p.valeurStock.toStringAsFixed(3)} TND'),
onTap: () => Get.to(() => PieceFormScreen(index: ref.read(pieceProvider).indexOf(p), piece: p)),
);
},
),
)
],
),
floatingActionButton: FloatingActionButton(
onPressed: () => Get.to(() => const PieceFormScreen()),
child: const Icon(Icons.add),
),
);
}
}