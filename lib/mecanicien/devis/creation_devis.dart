import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/add_piece_button.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/catalog_dropdown.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/generate_button.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/main_oeuvre_inputs.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/num_serie_input.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/piece_inputs.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/piece_row.dart';
import 'package:garagelink/mecanicien/devis/devis_widgets/tva_and_totals.dart';
import 'package:garagelink/mecanicien/devis/historique_devis.dart';
import 'package:garagelink/mecanicien/devis/models/catalogItem.dart';
import 'package:garagelink/mecanicien/devis/utils/on_add_piece.dart';
import 'package:garagelink/mecanicien/devis/utils/on_generate.dart';
import 'package:garagelink/providers/devis_provider.dart';

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

  // Entrée pièce
  CatalogItem? _selectedItem;
  final _pieceNomCtrl = TextEditingController();
  final _qteCtrl = TextEditingController(text: '1');
  final _puCtrl = TextEditingController();

  // Entrée numéro de série
  final _numLocalCtrl = TextEditingController();

  // Main d'œuvre & TVA & durée
  final _mainOeuvreCtrl = TextEditingController(text: '0');
  final _tvaCtrl = TextEditingController(text: '19');
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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(devisProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header avec gradient bleu
          SliverAppBar(
  expandedHeight: 120,
  floating: false,
  pinned: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.history, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HistoriqueDevisPage(),
          ),
        );
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

          // Contenu principal
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
                      // Section Client & Véhicule
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

                      // Section Pièces de rechange
                      ModernCard(
                        title: 'Pièces de rechange',
                        icon: Icons.build_outlined,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            CatalogDropdown(
                              selectedItem: _selectedItem,
                              onChanged: (val) {
                                if (val != null) {
                                  _pieceNomCtrl.text = val.nom;
                                  _puCtrl.text = val.prixUnitaire
                                      .toStringAsFixed(2);
                                  _qteCtrl.text = '1';

                                  onAddPiece(
                                    context: context,
                                    ref: ref,
                                    selectedItem: val,
                                    pieceNomCtrl: _pieceNomCtrl,
                                    qteCtrl: _qteCtrl,
                                    puCtrl: _puCtrl,
                                    onSuccess: () {
                                      setState(() {
                                        _selectedItem = null;
                                        _pieceNomCtrl.clear();
                                        _qteCtrl.text = '1';
                                        _puCtrl.clear();
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            PieceInputs(
                              isTablet: isTablet,
                              pieceNomCtrl: _pieceNomCtrl,
                              qteCtrl: _qteCtrl,
                              puCtrl: _puCtrl,
                              validator: (v) {
                                if (ref.read(devisProvider).pieces.isNotEmpty)
                                  return null;
                                if (v == null || v.isEmpty)
                                  return 'Champ requis';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AddPieceButton(
                              onPressed: () => onAddPiece(
                                context: context,
                                ref: ref,
                                selectedItem: _selectedItem,
                                pieceNomCtrl: _pieceNomCtrl,
                                qteCtrl: _qteCtrl,
                                puCtrl: _puCtrl,
                                onSuccess: () {
                                  setState(() {
                                    _selectedItem = null;
                                    _pieceNomCtrl.clear();
                                    _qteCtrl.text = '1';
                                    _puCtrl.clear();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...q.pieces.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PieceRow(
                                  piece: e.value,
                                  onDelete: () => ref
                                      .read(devisProvider.notifier)
                                      .removePieceAt(e.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Main d'œuvre & Durée
                      ModernCard(
                        title:
                            'Main d'
                            'œuvre & Durée',
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
                            TvaAndTotals(isTablet: isTablet, tvaCtrl: _tvaCtrl),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Bouton de génération
                      GenerateButton(
                        onPressed: () => onGenerate(
                          context: context,
                          formKey: _formKey,
                          pieces: ref.read(devisProvider).pieces,
                        ),
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
