import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_preview_page.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/add_piece_button.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/main_oeuvre_inputs.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/piece_inputs.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/piece_row.dart';
import 'package:garagelink/MecanicienScreens/devis/historique_devis.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/tva_and_totals.dart';
import 'package:garagelink/models/pieces.dart';
import 'package:garagelink/providers/ficheClient_provider.dart';
import 'package:garagelink/providers/devis_provider.dart';
import 'package:garagelink/providers/pieces_provider.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/providers/vehicule_provider.dart';
import 'package:get/get.dart';
import 'package:garagelink/models/ficheClient.dart';
import 'package:garagelink/models/vehicule.dart';
import 'package:garagelink/services/devis_api.dart';
import 'package:garagelink/global.dart'; // pour UrlApi
import 'package:url_launcher/url_launcher.dart';

class CreationDevisPage extends ConsumerStatefulWidget {
  const CreationDevisPage({super.key});

  @override
  ConsumerState<CreationDevisPage> createState() => _CreationDevisPageState();
}

class _CreationDevisPageState extends ConsumerState<CreationDevisPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl =
      TextEditingController(); // kept for compatibility (optional)
  final _vinCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  // local selection state for clients / vehicules
  Client? _selectedClient;
  Vehicule? _selectedVehicule;
  bool _loadingVehiculesForClient = false;

  // Entrée pièce - maintenant PieceRechange (catalog)
  PieceRechange? _selectedItem;
  final _pieceNomCtrl = TextEditingController();
  final _qteCtrl = TextEditingController(text: '1');
  final _puCtrl = TextEditingController();

  // Entrée TVA & Remise
  final _tvaCtrl = TextEditingController(text: '19');
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

  Future<void> _onClientSelected(Client? client) async {
    setState(() {
      _selectedClient = client;
      _selectedVehicule = null;
      _loadingVehiculesForClient = true;
      _numLocalCtrl.clear();
      _vinCtrl.clear();
    });

    if (client != null && client.id != null && client.id!.isNotEmpty) {
      await ref.read(vehiculesProvider.notifier).loadByProprietaire(client.id!);
      ref
          .read(devisProvider.notifier)
          .setClient(client.id ?? '', client.nomComplet);
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
        print('Vehicule sélectionné: ${veh.id} ${veh.marque} ${veh.modele}');
        _numLocalCtrl.text = veh.immatriculation;
        _vinCtrl.text = veh.immatriculation;
        ref.read(devisProvider.notifier).setNumeroSerie(veh.immatriculation);

        // NEW: set vehiculeId and vehicleInfo in provider
        final info =
            '${veh.marque} ${veh.modele} — ${veh.immatriculation ?? 'N/A'}';
        ref.read(devisProvider.notifier).setVehicule(veh.id, info);

        if (_selectedClient != null) {
          ref
              .read(devisProvider.notifier)
              .setClient(
                _selectedClient!.id ?? '',
                _selectedClient!.nomComplet,
              );
        }
      } else {
        _numLocalCtrl.clear();
        _vinCtrl.clear();
        // clear vehicule fields
        ref.read(devisProvider.notifier).setNumeroSerie('');
        ref.read(devisProvider.notifier).setVehicule('', '');
      }
    });
  }

  // === New: create payload from current devisProvider + selections
  Map<String, dynamic> _buildPayload({
    required Devis devisModel,
    required String status,
  }) {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      devisModel.toJson(),
    );

    // Client
    if (_selectedClient != null) {
      payload['clientId'] = _selectedClient!.id ?? '';
      payload['clientName'] = _selectedClient!.nomComplet;
      payload['clientEmail'] = _selectedClient!.mail ?? 'inconnu@example.com';
    }

    // Véhicule
    if (_selectedVehicule != null &&
        _selectedVehicule!.id?.isNotEmpty == true) {
      payload['vehiculeId'] = _selectedVehicule!.id;
      payload['vehicleInfo'] =
          '${_selectedVehicule!.marque} ${_selectedVehicule!.modele} — ${_selectedVehicule!.immatriculation ?? 'N/A'}';
    } else {
      print('Erreur: véhicule sélectionné mais id est null ou vide');
      payload['vehiculeId'] = '';
      payload['vehicleInfo'] = 'Véhicule non défini';
    }

    // Date inspection
    payload['inspectionDate'] =
        devisModel.inspectionDate?.toIso8601String() ??
        DateTime.now().toIso8601String();

    // Statut
    payload['status'] = status;

    return payload;
  }

  Future<void> _saveDraftToServer() async {
    // Validate client & vehicle selected
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedVehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un véhicule.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final devisModel = ref.read(devisProvider.notifier).toDevisModel();
      final payload = _buildPayload(
        devisModel: devisModel,
        status: 'brouillon',
      );
      final api = DevisApi(baseUrl: UrlApi);
      final token = await const FlutterSecureStorage().read(key: 'token');
      final res = await api.createDevis(payload, token: token);
      if (res['success'] == true && res['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brouillon enregistré avec succès'),
            backgroundColor: Color(0xFF50C878),
          ),
        );
        // navigate to historique
        Get.to(() => const HistoriqueDevisPage());
      } else {
        final msg = res['message'] ?? 'Erreur création brouillon';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $msg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _generateAndSendDevis() async {
    // Validate form and selections
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs requis.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedVehicule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un véhicule.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final devisModel = ref.read(devisProvider.notifier).toDevisModel();
      final payload = _buildPayload(devisModel: devisModel, status: 'envoye');
      final api = DevisApi(baseUrl: UrlApi);
      final res = await api.createDevis(payload);
      if (res['success'] == true && res['data'] != null) {
        final created = res['data'] as Devis;

        // Récupérer token (secure storage)
        String? authToken;
        try {
          authToken = await FlutterSecureStorage().read(key: 'token');
        } catch (_) {
          authToken = null;
        }

        // Demander au serveur d'envoyer l'email (contenant les vrais liens)
        final sendRes = await api.sendDevisByEmail(
          created.id ?? '',
          token: authToken,
        );
        if (sendRes['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Devis envoyé par email via le serveur'),
              backgroundColor: Color(0xFF50C878),
            ),
          );
        } else {
          final msg = sendRes['message'] ?? 'Impossible d\'envoyer via serveur';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur envoi serveur: $msg'),
              backgroundColor: Colors.orange,
            ),
          );

          // Fallback : ouvrir le mail local si on a l'email client
          final clientEmail = _selectedClient!.mail;
          if (clientEmail.isNotEmpty) {
            final subject = Uri.encodeComponent(
              'Devis pour ${_selectedClient!.nomComplet}',
            );
            final bodyLines = <String>[];
            bodyLines.add('Bonjour ${_selectedClient!.nomComplet},');
            bodyLines.add('');
            bodyLines.add(
              'Veuillez trouver ci-joint le devis pour votre véhicule ${_selectedVehicule!.marque} ${_selectedVehicule!.modele} (${_selectedVehicule!.immatriculation}).',
            );
            bodyLines.add('');
            bodyLines.add(
              'Total TTC: ${devisModel.totalTTC.toStringAsFixed(2)}',
            );
            bodyLines.add('');
            bodyLines.add('Cordialement,');
            bodyLines.add('Votre garage');
            final body = Uri.encodeComponent(bodyLines.join('\n'));

            final uri = Uri.parse(
              'mailto:$clientEmail?subject=$subject&body=$body',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Boîte mail ouverte'),
                  backgroundColor: Color(0xFF50C878),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impossible d\'ouvrir l\'application mail'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Client sans email: le devis a été créé, mais pas d\'email ouvert',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // navigate to preview or historique (tu peux choisir)
        Get.to(() => const DevisPreviewPage());
      } else {
        final msg = res['message'] ?? 'Erreur création devis';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $msg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(devisProvider);
    final catalogAsync = ref.watch(pieceRechangeProvider);

    // clients async from provider
    final clientsAsync = ref.watch(clientsProvider);
    // vehicules state
    final vehState = ref.watch(vehiculesProvider);

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
                      // ===== Client & Véhicule (REFAC) =====
                      ModernCard(
                        title: 'Client & Véhicule',
                        icon: Icons.person_outline,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Clients dropdown (from clientsProvider)
                            clientsAsync.when(
                              data: (clients) {
                                // 1) dédupliquer par id (évite les doublons qui provoquent '2 items found')
                                final uniqueMap = <String, Client>{};
                                for (final c in clients) {
                                  final id = c.id ?? '';
                                  if (id.isNotEmpty) uniqueMap[id] = c;
                                }
                                final uniqueClients = uniqueMap.values.toList();

                                // 2) retrouver l'instance correspondante dans la liste unique
                                Client? selectedFromList;
                                if (_selectedClient != null &&
                                    _selectedClient!.id != null) {
                                  try {
                                    selectedFromList = uniqueClients.firstWhere(
                                      (c) => c.id == _selectedClient!.id,
                                    );
                                  } catch (_) {
                                    selectedFromList = null;
                                  }
                                }

                                return DropdownButtonFormField<Client>(
                                  value: selectedFromList,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Sélectionner un client',
                                    prefixIcon: const Icon(
                                      Icons.person,
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
                                  items: uniqueClients.map((c) {
                                    return DropdownMenuItem<Client>(
                                      value: c,
                                      child: Text(c.nomComplet),
                                    );
                                  }).toList(),
                                  onChanged: (c) async {
                                    // onChanged doit utiliser l'instance provenant de la liste
                                    setState(() {
                                      _selectedClient = c;
                                      _selectedVehicule =
                                          null; // réinitialise si besoin
                                    });
                                    await _onClientSelected(c);
                                  },
                                  validator: (v) => v == null
                                      ? 'Veuillez sélectionner un client'
                                      : null,
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
                                  const Text(
                                    'Erreur chargement clients',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => ref
                                        .read(clientsProvider.notifier)
                                        .refresh(),
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Vehicules dropdown (filtered by selected client)
                            if (_selectedClient == null)
                              Text(
                                'Sélectionnez un client pour afficher ses véhicules',
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            else if (_loadingVehiculesForClient ||
                                vehState.loading)
                              const SizedBox(
                                height: 56,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              Builder(
                                builder: (context) {
                                  final clientId = _selectedClient!.id ?? '';
                                  final clientVehs = vehState.vehicules
                                      .where(
                                        (v) =>
                                            (v.proprietaireId ?? '') ==
                                            clientId,
                                      )
                                      .toList();

                                  if (clientVehs.isEmpty) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Aucun véhicule pour ce client',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(
                                              () => _loadingVehiculesForClient =
                                                  true,
                                            );
                                            if (clientId.isNotEmpty) {
                                              await ref
                                                  .read(
                                                    vehiculesProvider.notifier,
                                                  )
                                                  .loadByProprietaire(clientId);
                                            }
                                            setState(
                                              () => _loadingVehiculesForClient =
                                                  false,
                                            );
                                          },
                                          child: const Text(
                                            'Rafraîchir véhicules',
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return DropdownButtonFormField<Vehicule>(
                                    value:
                                        clientVehs.contains(_selectedVehicule)
                                        ? _selectedVehicule
                                        : null,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Sélectionner un véhicule',
                                      prefixIcon: const Icon(
                                        Icons.directions_car,
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
                                    items: clientVehs.map((v) {
                                      return DropdownMenuItem<Vehicule>(
                                        value:
                                            v, // ✅ mettre la valeur correcte ici
                                        child: Text(
                                          '${v.marque} ${v.modele} — ${v.immatriculation}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) => _onVehiculeSelected(v),
                                    validator: (v) => v == null
                                        ? 'Veuillez sélectionner un véhicule'
                                        : null,
                                  );
                                },
                              ),

                            const SizedBox(height: 16),

                            // Optional: show the selected immatriculation in a read-only field
                            TextFormField(
                              controller: _numLocalCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText:
                                    'Immatriculation / N° série (sélectionné)',
                                prefixIcon: const Icon(
                                  Icons.confirmation_number,
                                  color: Color(0xFF4A90E2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) {
                                if (_selectedVehicule == null)
                                  return 'Veuillez choisir un véhicule';
                                return null;
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

                      // ... (reste inchangé : Pièces de rechange, Main oeuvre, Boutons etc.)

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
                                    'Erreur chargement catalogue : ${err.toString()}',
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
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
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
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      await _saveDraftToServer();
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
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
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      setState(() => _isSubmitting = true);
                                      try {
                                        final devisModel = ref
                                            .read(devisProvider.notifier)
                                            .toDevisModel();
                                        final payload = _buildPayload(
                                          devisModel: devisModel,
                                          status: 'envoye',
                                        );
                                        print('Payload envoyé: $payload');
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
