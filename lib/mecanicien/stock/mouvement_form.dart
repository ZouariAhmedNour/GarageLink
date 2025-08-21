import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/mouvement.dart';
import 'package:garagelink/providers/mouvement_provider.dart';
import 'package:garagelink/providers/piece_provider.dart';
import 'package:get/get.dart';



class MouvementFormScreen extends ConsumerStatefulWidget {
final Mouvement? mouvement;
final int? index;
const MouvementFormScreen({super.key, this.mouvement, this.index});


@override
ConsumerState<MouvementFormScreen> createState() => _MouvementFormScreenState();
}


class _MouvementFormScreenState extends ConsumerState<MouvementFormScreen> {
final _formKey = GlobalKey<FormState>();
TypeMouvement selectedType = TypeMouvement.entree;
String? selectedPieceId;
late TextEditingController quantiteCtrl;
late TextEditingController notesCtrl;
late TextEditingController refDocCtrl;

@override
void initState() {
super.initState();
final m = widget.mouvement;
selectedType = m?.type ?? TypeMouvement.entree;
selectedPieceId = m?.pieceId;
quantiteCtrl = TextEditingController(text: m?.quantite.toString() ?? '');
notesCtrl = TextEditingController(text: m?.notes ?? '');
refDocCtrl = TextEditingController(text: m?.refDoc ?? '');
}

@override
Widget build(BuildContext context) {
final pieces = ref.watch(pieceProvider);


return Scaffold(
appBar: AppBar(title: Text(widget.mouvement == null ? 'Nouveau mouvement' : 'Modifier mouvement')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Form(
key: _formKey,
child: Column(
children: [
DropdownButtonFormField<TypeMouvement>(
value: selectedType,
decoration: const InputDecoration(labelText: 'Type de mouvement'),
items: TypeMouvement.values
.map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
.toList(),
onChanged: (val) => setState(() => selectedType = val!),
),

const SizedBox(height: 8),
DropdownButtonFormField<String>(
value: selectedPieceId,
decoration: const InputDecoration(labelText: 'Pièce'),
items: [
for (final p in pieces)
DropdownMenuItem(value: p.id, child: Text('${p.sku} • ${p.nom} (Qt: ${p.quantite})')),
],
validator: (v) => v == null ? 'Choisir une pièce' : null,
onChanged: (val) => setState(() => selectedPieceId = val),
),
const SizedBox(height: 8),
TextFormField(
controller: quantiteCtrl,
keyboardType: TextInputType.number,
decoration: const InputDecoration(labelText: 'Quantité'),
validator: (v) {
final n = int.tryParse(v ?? '');
if (n == null || n <= 0) return 'Quantité invalide';
return null;
},
),

const SizedBox(height: 8),
TextFormField(
controller: refDocCtrl,
decoration: const InputDecoration(labelText: 'Référence doc (optionnel)'),
),
const SizedBox(height: 8),
TextFormField(
controller: notesCtrl,
decoration: const InputDecoration(labelText: 'Notes'),
),
const SizedBox(height: 16),
FilledButton(
onPressed: () {
if (!_formKey.currentState!.validate()) return;
final mvt = Mouvement(
id: widget.mouvement?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
pieceId: selectedPieceId!,
type: selectedType,
quantite: int.parse(quantiteCtrl.text),
date: DateTime.now(),
notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
refDoc: refDocCtrl.text.isEmpty ? null : refDocCtrl.text,
);
if (widget.index == null) {
ref.read(mouvementProvider.notifier).addMouvement(mvt);
} else {
ref.read(mouvementProvider.notifier).updateMouvement(widget.index!, mvt);
}
Get.back();
},
child: const Text('Sauvegarder'),
)
],
),
),
),
);
}
}