import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/models/piece.dart';
import 'package:garagelink/providers/piece_provider.dart';


class PieceFormScreen extends ConsumerStatefulWidget {
final int? index;
final Piece? piece;
const PieceFormScreen({super.key, this.index, this.piece});


@override
ConsumerState<PieceFormScreen> createState() => _PieceFormScreenState();
}

class _PieceFormScreenState extends ConsumerState<PieceFormScreen> {
final _formKey = GlobalKey<FormState>();
final skuCtrl = TextEditingController();
final nomCtrl = TextEditingController();
final barcodeCtrl = TextEditingController();
final uomCtrl = TextEditingController(text: 'pièce');
final prixAchatCtrl = TextEditingController(text: '0');
final prixVenteCtrl = TextEditingController(text: '0');
final quantiteCtrl = TextEditingController(text: '0');
final seuilMinCtrl = TextEditingController(text: '0');
final seuilMaxCtrl = TextEditingController();
final emplacementCtrl = TextEditingController();


@override
void initState() {
super.initState();
final p = widget.piece;
if (p != null) {
skuCtrl.text = p.sku;
nomCtrl.text = p.nom;
barcodeCtrl.text = p.barcode ?? '';
uomCtrl.text = p.uom;
prixAchatCtrl.text = p.prixAchat.toString();
prixVenteCtrl.text = p.prixVente.toString();
quantiteCtrl.text = p.quantite.toString();
seuilMinCtrl.text = p.seuilMin.toString();
seuilMaxCtrl.text = p.seuilMax?.toString() ?? '';
emplacementCtrl.text = p.emplacement ?? '';
}
}
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text(widget.piece == null ? 'Nouvelle pièce' : 'Modifier la pièce')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Form(
key: _formKey,
child: SingleChildScrollView(
child: Column(
children: [
TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU / Référence'), validator: _req),
TextFormField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom'), validator: _req),
TextFormField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Code barre (optionnel)')),
TextFormField(controller: uomCtrl, decoration: const InputDecoration(labelText: 'Unité')),
Row(children: [
Expanded(child: TextFormField(controller: prixAchatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix d\'achat'))),
const SizedBox(width: 8),
Expanded(child: TextFormField(controller: prixVenteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix de vente'))),
]),
Row(children: [
Expanded(child: TextFormField(controller: quantiteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité initiale'))),
const SizedBox(width: 8),
Expanded(child: TextFormField(controller: seuilMinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seuil min'))),
]),
TextFormField(controller: seuilMaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seuil max (optionnel)')),
TextFormField(controller: emplacementCtrl, decoration: const InputDecoration(labelText: 'Emplacement (rayon/étagère)')),
const SizedBox(height: 16),

FilledButton(
onPressed: () {
if (!_formKey.currentState!.validate()) return;
final piece = Piece(
id: widget.piece?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
sku: skuCtrl.text.trim(),
nom: nomCtrl.text.trim(),
barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
uom: uomCtrl.text.trim(),
prixAchat: double.tryParse(prixAchatCtrl.text) ?? 0,
prixVente: double.tryParse(prixVenteCtrl.text) ?? 0,
quantite: int.tryParse(quantiteCtrl.text) ?? 0,
seuilMin: int.tryParse(seuilMinCtrl.text) ?? 0,
seuilMax: int.tryParse(seuilMaxCtrl.text),
emplacement: emplacementCtrl.text.trim().isEmpty ? null : emplacementCtrl.text.trim(),
updatedAt: DateTime.now(),
prixUnitaire: double.tryParse(prixAchatCtrl.text) ?? 0,
);


if (widget.index == null) {
ref.read(pieceProvider.notifier).addPiece(piece);
} else {
ref.read(pieceProvider.notifier).updatePiece(widget.index!, piece);
}
Navigator.pop(context);
},
child: const Text('Enregistrer'),


)
],
),
),
),
),
);
}


String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requis' : null;
}