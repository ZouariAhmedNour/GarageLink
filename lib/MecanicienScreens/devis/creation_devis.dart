import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/add_piece_button.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/main_oeuvre_inputs.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/piece_inputs.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/piece_row.dart';
import 'package:garagelink/MecanicienScreens/devis/historique_devis.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/tva_and_totals.dart';
import 'package:garagelink/models/pieceRechange.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/pieceRechange_provider.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/utils/devis_actions.dart';
import 'package:get/get.dart';

class CreationDevisPage extends ConsumerStatefulWidget {
  const CreationDevisPage({super.key});

  @override
  ConsumerState<CreationDevisPage> createState() => _CreationDevisPageState();
}

class _CreationDevisPageState extends ConsumerState<CreationDevisPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  // Entrée pièce - maintenant PieceRechange (catalog)
  PieceRechange? _selectedItem;
  final _pieceNomCtrl = TextEditingController();
  final _qteCtrl = TextEditingController(text: '1');
  final _puCtrl = TextEditingController();

  // Entrée TVA & Remise
  final _tvaCtrl = TextEditingController(text: '19');
  final _remiseCtrl = TextEditingController(text: '0');

  // Entrée numéro de série
  final _numLocalCtrl = TextEditingController();

  // Main d'œuvre  & durée
  final _mainOeuvreCtrl = TextEditingController(text: '0');
  Duration _duree = const Duration(hours: 1);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _clientCtrl.dispose();
    _vinCtrl.dispose();
    _pieceNomCtrl.dispose();
    _qteCtrl.dispose();
    _puCtrl.dispose();
    _mainOeuvreCtrl.dispose();
    _tvaCtrl.dispose();
    _numLocalCtrl.dispose();
    _remiseCtrl.dispose();
    super.dispose();
  }

  // Helpers de parsing
  double? _parseDouble(String s) {
    final stripped = s.replaceAll(',', '.').trim();
    if (stripped.isEmpty) return null;
    return double.tryParse(stripped);
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  // Ajout depuis catalogue (PieceRechange)
  void _addFromCatalog(PieceRechange p) {
    final unitPrice = p.prix;
    final name = p.name;
    final qty = 1;
    final service = DevisService(
      pieceId: p.id?.toString(),
      piece: name,
      quantity: qty,
      unitPrice: unitPrice,
      total: unitPrice * qty,
    );
    ref.read(devisProvider.notifier).addService(service);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pièce ajoutée depuis le catalogue'),
        backgroundColor: Color(0xFF50C878),
      ),
    );
  }

  // Ajout manuel depuis champs
  void _addFromInputs() {
    final name = _pieceNomCtrl.text.trim();
    final qte = _parseInt(_qteCtrl.text) ?? 0;
    final pu = _parseDouble(_puCtrl.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir le nom de la pièce.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (qte <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La quantité doit être supérieure à 0.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (pu == null || pu < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prix unitaire invalide.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final service = DevisService(
      pieceId: null,
      piece: name,
      quantity: qte,
      unitPrice: pu,
      total: qte * pu,
    );

    ref.read(devisProvider.notifier).addService(service);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pièce ajoutée avec succès !'),
        backgroundColor: Color(0xFF50C878),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(devisProvider);
    ref.watch(pieceRechangeProvider); // liste PieceRechange
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
final catalogAsync = ref.watch(pieceRechangeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Get.to(() => const HistoriqueDevisPage());
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Nouveau devis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF4A90E2),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client & Véhicule
                      ModernCard(
                        title: 'Client & Véhicule',
                        icon: Icons.person_outline,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            ModernTextField(
                              controller: _clientCtrl,
                              label: 'Nom du client',
                              icon: Icons.person,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Obligatoire'
                                  : null,
                              onChanged: (v) =>
                                  ref.read(devisProvider.notifier).setClient(v),
                            ),
                            const SizedBox(height: 16),
                            NumeroSerieInput(
                              vinCtrl: _vinCtrl,
                              numLocalCtrl: _numLocalCtrl,
                              onChanged: (value) {
                                ref
                                    .read(devisProvider.notifier)
                                    .setNumeroSerie(value);
                              },
                            ),
                            const SizedBox(height: 16),
                            DatePicker(
                              date: _date,
                              isTablet: isTablet,
                              onDateChanged: (d) {
                                setState(() => _date = d);
                                ref.read(devisProvider.notifier).setDate(d);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pièces de rechange
                      ModernCard(
                        title: 'Pièces de rechange',
                        icon: Icons.build_outlined,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            // Dropdown catalogue
                            catalogAsync.when(
                              data: (catalog) {
                                return DropdownButtonFormField<PieceRechange?>(
                                  isExpanded: true,
                                  value: _selectedItem,
                                  decoration: InputDecoration(
                                    labelText: 'Depuis le catalogue',
                                    prefixIcon: const Icon(
                                      Icons.inventory,
                                      color: Color(0xFF4A90E2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  items: catalog.isEmpty
                                      ? [
                                          const DropdownMenuItem<
                                            PieceRechange?
                                          >(
                                            value: null,
                                            child: Text(
                                              'Aucun article dans le catalogue',
                                            ),
                                          ),
                                        ]
                                      : catalog
                                            .map(
                                              (
                                                p,
                                              ) => DropdownMenuItem<PieceRechange?>(
                                                value: p,
                                                child: Text(
                                                  '${p.name} — ${p.prix.toStringAsFixed(2)}',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() => _selectedItem = val);

                                    // Ajout après fermeture du menu (microtask) pour éviter que le rebuild ferme le menu
                                    Future.microtask(() {
                                      _pieceNomCtrl.text = val.name;
                                      _puCtrl.text = val.prix.toStringAsFixed(
                                        2,
                                      );
                                      _qteCtrl.text = '1';
                                      _addFromCatalog(val);
                                      if (mounted)
                                        setState(() => _selectedItem = null);
                                    });
                                  },
                                );
                              },
                              loading: () => const SizedBox(
                                height: 56,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, st) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Erreur chargement catalogue',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => ref
                                        .read(pieceRechangeProvider.notifier)
                                        .refresh(),
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Inputs manuels
                            PieceInputs(
                              isTablet: isTablet,
                              pieceNomCtrl: _pieceNomCtrl,
                              qteCtrl: _qteCtrl,
                              puCtrl: _puCtrl,
                              validator: (v) {
                                if (ref.read(devisProvider).services.isNotEmpty)
                                  return null;
                                if (v == null || v.isEmpty)
                                  return 'Champ requis';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            AddPieceButton(
                              onPressed: () {
                                _addFromInputs();
                                // cleanup UI
                                setState(() {
                                  _selectedItem = null;
                                  _pieceNomCtrl.clear();
                                  _qteCtrl.text = '1';
                                  _puCtrl.clear();
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Liste des services/pièces (utilise services du provider)
                            ...q.services.asMap().entries.map((e) {
                              final DevisService srv = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PieceRow(
                                  entry: srv,
                                  onDelete: () => ref
                                      .read(devisProvider.notifier)
                                      .removeServiceAt(e.key),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main d'oeuvre & durée
                      ModernCard(
                        title: 'Main d\'œuvre & Durée',
                        icon: Icons.timer_outlined,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            MainOeuvreInputs(
                              isTablet: isTablet,
                              mainOeuvreCtrl: _mainOeuvreCtrl,
                              duree: _duree,
                              onDureeChanged: (d) {
                                setState(() => _duree = d);
                                ref.read(devisProvider.notifier).setDuree(d);
                              },
                            ),
                            const SizedBox(height: 16),
                            TvaAndTotals(
                              isTablet: isTablet,
                              tvaCtrl: _tvaCtrl,
                              remiseCtrl: _remiseCtrl,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Enregistrer brouillon',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState == null) return;
                                await saveDraft(ref);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Brouillon enregistré'),
                                  ),
                                );
                                Get.to(() => const HistoriqueDevisPage());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: const Text(
                                'Générer & Envoyer',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                await generateAndSendDevis(ref, context);
                                Get.to(() => const DevisPreviewPage());
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
