import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/components/devis_widgets/piece_row.dart';
import 'package:garagelink/components/devis_widgets/totals_card.dart';
import 'package:garagelink/mecanicien/devis/devis_preview_page.dart';
import 'package:garagelink/models/catalogItem.dart';
import 'package:garagelink/models/piece.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/utils/format.dart';

class CreationDevisPage extends ConsumerStatefulWidget {
  const CreationDevisPage({super.key});

  @override
  ConsumerState<CreationDevisPage> createState() => _CreationDevisPageState();
}

class _CreationDevisPageState extends ConsumerState<CreationDevisPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  // Entrée pièce
  CatalogItem? _selectedItem;
  final _pieceNomCtrl = TextEditingController();
  final _qteCtrl = TextEditingController(text: '1');
  final _puCtrl = TextEditingController();

  // Main d'œuvre & TVA & durée
  final _mainOeuvreCtrl = TextEditingController(text: '0');
  final _tvaCtrl = TextEditingController(text: '19');
  Duration _duree = const Duration(hours: 1);

  @override
  void dispose() {
    _clientCtrl.dispose();
    _vinCtrl.dispose();
    _pieceNomCtrl.dispose();
    _qteCtrl.dispose();
    _puCtrl.dispose();
    _mainOeuvreCtrl.dispose();
    _tvaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(devisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau devis')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client & Véhicule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du client',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obligatoire' : null,
                onChanged: (v) => ref.read(devisProvider.notifier).setClient(v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vinCtrl,
                decoration: const InputDecoration(
                  labelText: 'N° de série (VIN)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obligatoire' : null,
                onChanged: (v) =>
                    ref.read(devisProvider.notifier).setNumeroSerie(v),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Date: ${Fmt.date(_date)}')),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: _date,
                        locale: const Locale('fr'),
                      );
                      if (d != null) {
                        setState(() => _date = d);
                        ref.read(devisProvider.notifier).setDate(d);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: const Text('Choisir date'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                'Pièces de rechange',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CatalogItem>(
                decoration: const InputDecoration(
                  labelText: 'Depuis le catalogue',
                  border: OutlineInputBorder(),
                ),
                items: kCatalog
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text('${e.nom} — ${Fmt.money(e.prixUnitaire)}'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedItem = val);
                  if (val != null) {
                    _pieceNomCtrl.text = val.nom;
                    _puCtrl.text = val.prixUnitaire.toStringAsFixed(2);
                    _qteCtrl.text = '1';
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _pieceNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Désignation (saisie libre)',
                        border: OutlineInputBorder(),
                      ),
                      // Désignation
                     validator: (v) {
  // Si la liste de pièces contient déjà des entrées, on n'exige pas ce champ
  if (ref.read(devisProvider).pieces.isNotEmpty) return null;
  if (v == null || v.isEmpty) return 'Nom requis';
  return null;
}
                    ),
                  ),

                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _qteCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qté',
                        border: OutlineInputBorder(),
                      ),
                      // Quantité
                     validator: (v) {
  // Si la liste de pièces contient déjà des entrées, on n'exige pas ce champ
  if (ref.read(devisProvider).pieces.isNotEmpty) return null;
  if (v == null || v.isEmpty) return 'Qté';
  return null;
}
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _puCtrl,
                      decoration: const InputDecoration(
                        labelText: 'PU',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // Prix unitaire
                      validator: (v) {
  // Si la liste de pièces contient déjà des entrées, on n'exige pas ce champ
  if (ref.read(devisProvider).pieces.isNotEmpty) return null;
  if (v == null || v.isEmpty) return 'PU';
  return null;
}
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _onAddPiece,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter la pièce'),
                ),
              ),
              const SizedBox(height: 8),
              ...q.pieces.asMap().entries.map(
                (e) => PieceRow(
                  piece: e.value,
                  onDelete: () =>
                      ref.read(devisProvider.notifier).removePieceAt(e.key),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Main d’œuvre & Durée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mainOeuvreCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Montant main d’œuvre',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => ref
                          .read(devisProvider.notifier)
                          .setMainOeuvre(double.tryParse(v.replaceAll(',', '.')) ?? 0
),
                    ),
                  ),

                  const SizedBox(width: 8),
                  Expanded(
                    child: _DureePicker(
                      value: _duree,
                      onChanged: (d) {
                        setState(() => _duree = d);
                        ref.read(devisProvider.notifier).setDuree(d);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tvaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'TVA %',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final t = (double.tryParse(v) ?? 0) / 100.0;
                        ref.read(devisProvider.notifier).setTva(t);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: TotalsCard()),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _onGenerate,
                      icon: const Icon(Icons.description),
                      label: const Text('Générer le devis'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAddPiece() {
    // Si une pièce vient du catalogue
    if (_selectedItem != null) {
      final p = Piece(
        nom: _pieceNomCtrl.text.trim(),
        prixUnitaire: double.tryParse(_puCtrl.text.trim()) ?? 0,
        quantite: int.tryParse(_qteCtrl.text.trim()) ?? 1,
      );
      ref.read(devisProvider.notifier).addPiece(p);

      // Reset
      setState(() {
        _selectedItem = null;
        _pieceNomCtrl.clear();
        _qteCtrl.text = '1';
        _puCtrl.clear();
      });
      return;
    }

    // Sinon, validation manuelle
    if ((_pieceNomCtrl.text).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le nom de la pièce.')),
      );
      return;
    }

    final qte = int.tryParse(_qteCtrl.text.trim());
    final pu = double.tryParse(_puCtrl.text.trim());
    if (qte == null || qte <= 0 || pu == null || pu < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vérifiez quantité et prix unitaire.')),
      );
      return;
    }

    final p = Piece(
      nom: _pieceNomCtrl.text.trim(),
      prixUnitaire: pu,
      quantite: qte,
    );
    ref.read(devisProvider.notifier).addPiece(p);

    // Reset
    setState(() {
      _selectedItem = null;
      _pieceNomCtrl.text = ''; // vide
      _qteCtrl.text = '1'; // valeur par défaut
      _puCtrl.text = '0'; // éviter "PU requis"
    });
  }

  void _onGenerate() {
    if (!_formKey.currentState!.validate()) return;
    if (ref.read(devisProvider).pieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une pièce.')),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DevisPreviewPage()));
  }
}

class _DureePicker extends StatelessWidget {
  final Duration value;
  final ValueChanged<Duration> onChanged;
  const _DureePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Durée estimée',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: hours,
              items: List.generate(
                24,
                (i) => DropdownMenuItem(value: i, child: Text('$i h')),
              ),
              onChanged: (h) =>
                  onChanged(Duration(hours: h ?? 0, minutes: minutes)),
              underline: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: minutes,
              items: const [0, 15, 30, 45]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                  .toList(),
              onChanged: (m) =>
                  onChanged(Duration(hours: hours, minutes: m ?? 0)),
              underline: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
