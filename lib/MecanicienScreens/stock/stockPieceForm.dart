import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/stock_piece.dart';
import 'package:garagelink/providers/stockpiece_provider.dart';

class StockPieceFormScreen extends ConsumerStatefulWidget {
  final int? index;
  final StockPiece? stockPiece;

  const StockPieceFormScreen({super.key, this.index, this.stockPiece});

  @override
  ConsumerState<StockPieceFormScreen> createState() => _StockPieceFormScreenState();
}

class _StockPieceFormScreenState extends ConsumerState<StockPieceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final skuCtrl = TextEditingController();
  final nomCtrl = TextEditingController();
  final uomCtrl = TextEditingController(text: 'pièce');
  final prixAchatCtrl = TextEditingController(text: '0');
  final quantiteCtrl = TextEditingController(text: '0');
  final prixVenteCtrl = TextEditingController(text: '0');
  final seuilMinCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final sp = widget.stockPiece;
    if (sp != null) {
      skuCtrl.text = sp.sku;
      nomCtrl.text = sp.nom;
      uomCtrl.text = sp.uom;
      prixAchatCtrl.text = sp.prixAchat.toString();
      quantiteCtrl.text = sp.quantite.toString();
      prixVenteCtrl.text = sp.prixVente.toString();
      seuilMinCtrl.text = sp.seuilMin.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockPiece == null ? 'Nouvelle pièce' : 'Modifier la pièce'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU / Référence'),
                  validator: _req,
                ),
                TextFormField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: _req,
                ),
                TextFormField(
                  controller: uomCtrl,
                  decoration: const InputDecoration(labelText: 'Unité'),
                ),
                TextFormField(
                  controller: prixAchatCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix d\'achat'),
                ),
                TextFormField(
                  controller: quantiteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantité initiale'),
                ),
                TextFormField(
                  controller: prixVenteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix de vente'),
                ),
                TextFormField(
                  controller: seuilMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seuil min'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final sp = StockPiece(
                      id: widget.stockPiece?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      sku: skuCtrl.text.trim(),
                      nom: nomCtrl.text.trim(),
                      uom: uomCtrl.text.trim(),
                      prixAchat: double.tryParse(prixAchatCtrl.text) ?? 0,
                      prixVente: double.tryParse(prixVenteCtrl.text) ?? 0,
                      quantite: int.tryParse(quantiteCtrl.text) ?? 0,
                      seuilMin: int.tryParse(seuilMinCtrl.text) ?? 0,
                      updatedAt: DateTime.now(),
                      prixUnitaire: double.tryParse(prixAchatCtrl.text) ?? 0,
                    );

                   if (widget.index == null) {
  await ref.read(stockPieceProvider.notifier).addPiece(sp);
} else {
  await ref.read(stockPieceProvider.notifier).updatePiece(sp);
}

                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requis' : null;
}
