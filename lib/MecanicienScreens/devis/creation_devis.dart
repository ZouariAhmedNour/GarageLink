import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/add_piece_button.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/main_oeuvre_inputs.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/piece_inputs.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/piece_row.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/tva_and_totals.dart';
import 'package:garagelink/MecanicienScreens/devis/historique_devis.dart';
import 'package:garagelink/models/devis.dart' show Service, EstimatedTime;
import 'package:garagelink/models/ficheClient.dart' show FicheClient;
import 'package:garagelink/models/pieces.dart' show Piece;
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/ficheClient_provider.dart';
import 'package:garagelink/providers/pieces_provider.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
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

  // local selection state for clients / vehicules
  FicheClient? _selectedClient;
  Vehicule? _selectedVehicule;
  bool _loadingVehiculesForClient = false;

  // Entrée pièce - catalogue
  Piece? _selectedItem;
  final _pieceNomCtrl = TextEditingController();
  final _qteCtrl = TextEditingController(text: '1');
  final _puCtrl = TextEditingController();

  // Entrée TVA & Remise (remise UI stays but provider may not store remise)
  final _tvaCtrl = TextEditingController(text: '20');
  final _remiseCtrl = TextEditingController(text: '0');

  // Entrée numéro de série (sera rempli depuis la sélection de véhicule)
  final _numLocalCtrl = TextEditingController();

  // Main d'œuvre  & durée
  final _mainOeuvreCtrl = TextEditingController(text: '0');
  Duration _duree = const Duration(hours: 1);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // submission state
  bool _isSubmitting = false;

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

  // Ajout depuis catalogue (Piece)
  void _addFromCatalog(Piece p) {
    final unitPrice = p.prix;
    final name = p.name;
    final qty = 1;
    final service = Service(
      pieceId: p.id?.toString() ?? '',
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

    final service = Service(
      pieceId: '',
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

  Future<void> _onClientSelected(FicheClient? client) async {
    setState(() {
      _selectedClient = client;
      _selectedVehicule = null;
      _loadingVehiculesForClient = true;
      _numLocalCtrl.clear();
      _vinCtrl.clear();
    });

    if (client != null && client.id != null && client.id!.isNotEmpty) {
      await ref.read(vehiculesProvider.notifier).loadByProprietaire(client.id!);
      // provider expects (id, name)
      ref.read(devisProvider.notifier).setClient(client.id ?? '', client.nom);
    } else {
      ref.read(devisProvider.notifier).setClient('', '');
    }

    setState(() {
      _loadingVehiculesForClient = false;
    });
  }

  void _onVehiculeSelected(Vehicule? veh) {
    setState(() {
      _selectedVehicule = veh;
      if (veh != null) {
        _numLocalCtrl.text = veh.immatriculation;
        _vinCtrl.text = veh.immatriculation;
        ref.read(devisProvider.notifier).setNumeroSerie(veh.immatriculation);

        // set vehiculeId and vehicleInfo in provider
        final info = '${veh.marque} ${veh.modele} — ${veh.immatriculation}';
        ref.read(devisProvider.notifier).setVehicule(veh.id, info);

        if (_selectedClient != null) {
          ref.read(devisProvider.notifier).setClient(
                _selectedClient!.id ?? '',
                _selectedClient!.nom,
              );
        }
      } else {
        _numLocalCtrl.clear();
        _vinCtrl.clear();
        ref.read(devisProvider.notifier).setNumeroSerie('');
        ref.read(devisProvider.notifier).setVehicule('', '');
      }
    });
  }

  // helper: Duration -> EstimatedTime
  EstimatedTime _durationToEstimatedTime(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    return EstimatedTime(days: days, hours: hours, minutes: minutes);
  }

  Future<void> _saveDraftToServer() async {
    // Validate client & vehicle selected
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedVehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un véhicule.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // update provider values (TVA, main d'oeuvre, durée, date)
      final tva = double.tryParse(_tvaCtrl.text.replaceAll(',', '.')) ?? 20.0;
      final main = double.tryParse(_mainOeuvreCtrl.text.replaceAll(',', '.')) ?? 0.0;
      ref.read(devisProvider.notifier).setTvaRate(tva);
      ref.read(devisProvider.notifier).setMaindoeuvre(main);
      ref.read(devisProvider.notifier).setEstimatedTime(_durationToEstimatedTime(_duree));
      ref.read(devisProvider.notifier).setInspectionDate(_date);

      // ask provider to create a brouillon (provider handles API & token)
      await ref.read(devisProvider.notifier).ajouterDevis();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brouillon enregistré avec succès'), backgroundColor: Color(0xFF50C878)),
      );

      Get.to(() => const HistoriqueDevisPage());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _generateAndSendDevis() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs requis.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedVehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un véhicule.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // update provider values
      final tva = double.tryParse(_tvaCtrl.text.replaceAll(',', '.')) ?? 20.0;
      final main = double.tryParse(_mainOeuvreCtrl.text.replaceAll(',', '.')) ?? 0.0;
      ref.read(devisProvider.notifier).setTvaRate(tva);
      ref.read(devisProvider.notifier).setMaindoeuvre(main);
      ref.read(devisProvider.notifier).setEstimatedTime(_durationToEstimatedTime(_duree));
      ref.read(devisProvider.notifier).setInspectionDate(_date);

      // create and send (provider will create the devis via API)
      await ref.read(devisProvider.notifier).ajouterDevis();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis créé'), backgroundColor: Color(0xFF50C878)),
      );

      // open preview
      Get.to(() => const DevisPreviewPage());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(devisProvider); // DevisFilterState
    final piecesState = ref.watch(piecesProvider); // PiecesState
    final clientsState = ref.watch(ficheClientsProvider); // FicheClientsState
    final vehState = ref.watch(vehiculesProvider); // VehiculesState

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.1)]),
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
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client & Véhicule
                      ModernCard(
                        title: 'Client & Véhicule',
                        icon: Icons.person_outline,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Clients dropdown
                            if (clientsState.loading)
                              const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                            else if (clientsState.error != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Erreur chargement clients', style: TextStyle(color: Colors.red)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(onPressed: () => ref.read(ficheClientsProvider.notifier).loadNoms(), child: const Text('Réessayer')),
                                ],
                              )
                            else
                              DropdownButtonFormField<FicheClient>(
                                value: _selectedClient != null
                                    ? clientsState.clients.firstWhere(
                                        (c) => c.id == _selectedClient!.id,
                                        orElse: () => _selectedClient!,
                                      )
                                    : null,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Sélectionner un client',
                                  prefixIcon: const Icon(Icons.person, color: Color(0xFF4A90E2)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                ),
                                items: clientsState.clients.map((c) {
                                  return DropdownMenuItem<FicheClient>(
                                    value: c,
                                    child: Text(c.nom),
                                  );
                                }).toList(),
                                onChanged: (c) async {
                                  setState(() {
                                    _selectedClient = c;
                                    _selectedVehicule = null;
                                  });
                                  await _onClientSelected(c);
                                },
                                validator: (v) => v == null ? 'Veuillez sélectionner un client' : null,
                              ),

                            const SizedBox(height: 16),

                            // Vehicules dropdown (filtered by selected client)
                            if (_selectedClient == null)
                              Text('Sélectionnez un client pour afficher ses véhicules', style: TextStyle(color: Colors.grey[600]))
                            else if (_loadingVehiculesForClient || vehState.loading)
                              const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                            else
                              Builder(builder: (context) {
                                final clientId = _selectedClient!.id ?? '';
                                final clientVehs = vehState.vehicules.where((v) => v.proprietaireId == clientId).toList();

                                if (clientVehs.isEmpty) {
                                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Aucun véhicule pour ce client', style: TextStyle(color: Colors.grey[600])),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setState(() => _loadingVehiculesForClient = true);
                                        if (clientId.isNotEmpty) {
                                          await ref.read(vehiculesProvider.notifier).loadByProprietaire(clientId);
                                        }
                                        setState(() => _loadingVehiculesForClient = false);
                                      },
                                      child: const Text('Rafraîchir véhicules'),
                                    ),
                                  ]);
                                }

                                return DropdownButtonFormField<Vehicule>(
                                  value: clientVehs.contains(_selectedVehicule) ? _selectedVehicule : null,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Sélectionner un véhicule',
                                    prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF4A90E2)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                  ),
                                  items: clientVehs.map((v) {
                                    return DropdownMenuItem<Vehicule>(value: v, child: Text('${v.marque} ${v.modele} — ${v.immatriculation}'));
                                  }).toList(),
                                  onChanged: (v) => _onVehiculeSelected(v),
                                  validator: (v) => v == null ? 'Veuillez sélectionner un véhicule' : null,
                                );
                              }),

                            const SizedBox(height: 16),

                            // Immatriculation read-only
                            TextFormField(
                              controller: _numLocalCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Immatriculation / N° série (sélectionné)',
                                prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFF4A90E2)),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) {
                                if (_selectedVehicule == null) return 'Veuillez choisir un véhicule';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            DatePicker(
                              date: _date,
                              isTablet: isTablet,
                              onDateChanged: (d) {
                                setState(() => _date = d);
                                ref.read(devisProvider.notifier).setInspectionDate(d);
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
                            // Dropdown catalogue (piecesProvider is a StateNotifier)
                            if (piecesState.loading)
                              const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                            else if (piecesState.error != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Erreur chargement catalogue : ${piecesState.error}', style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(onPressed: () => ref.read(piecesProvider.notifier).loadAll(), child: const Text('Réessayer')),
                                ],
                              )
                            else
                              DropdownButtonFormField<Piece?>(
                                isExpanded: true,
                                value: _selectedItem,
                                decoration: InputDecoration(
                                  labelText: 'Depuis le catalogue',
                                  prefixIcon: const Icon(Icons.inventory, color: Color(0xFF4A90E2)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                ),
                                items: piecesState.pieces.isEmpty
                                    ? [
                                        const DropdownMenuItem<Piece?>(value: null, child: Text('Aucun article dans le catalogue')),
                                      ]
                                    : piecesState.pieces.map((p) {
                                        return DropdownMenuItem<Piece?>(value: p, child: Text('${p.name} — ${p.prix.toStringAsFixed(2)}'));
                                      }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setState(() => _selectedItem = val);
                                  Future.microtask(() {
                                    _pieceNomCtrl.text = val.name;
                                    _puCtrl.text = val.prix.toStringAsFixed(2);
                                    _qteCtrl.text = '1';
                                    _addFromCatalog(val);
                                    if (mounted) setState(() => _selectedItem = null);
                                  });
                                },
                              ),

                            const SizedBox(height: 16),

                            // Inputs manuels
                            PieceInputs(
                              isTablet: isTablet,
                              pieceNomCtrl: _pieceNomCtrl,
                              qteCtrl: _qteCtrl,
                              puCtrl: _puCtrl,
                              validator: (v) {
                                if (ref.read(devisProvider).services.isNotEmpty) return null;
                                if (v == null || v.isEmpty) return 'Champ requis';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            AddPieceButton(
                              onPressed: () {
                                _addFromInputs();
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
                              final Service srv = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PieceRow(
                                  entry: srv,
                                  onDelete: () => ref.read(devisProvider.notifier).removeServiceAt(e.key),
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
                                ref.read(devisProvider.notifier).setEstimatedTime(_durationToEstimatedTime(d));
                              },
                            ),
                            const SizedBox(height: 16),
                            TvaAndTotals(
  isTablet: isTablet,
  tvaCtrl: _tvaCtrl,
  remiseCtrl: _remiseCtrl,
  maindoeuvreCtrl: _mainOeuvreCtrl,
),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: _isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_outlined, color: Colors.white),
                              label: const Text('Enregistrer brouillon', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: _isSubmitting ? null : () async => await _saveDraftToServer(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: _isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send, color: Colors.white),
                              label: const Text('Générer & Envoyer', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      setState(() => _isSubmitting = true);
                                      try {
                                        await _generateAndSendDevis();
                                      } finally {
                                        setState(() => _isSubmitting = false);
                                      }
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
