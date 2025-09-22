import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/date_picker.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/generate_button.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_card.dart';
import 'package:garagelink/MecanicienScreens/devis/devis_widgets/modern_text_field.dart';
import 'package:garagelink/MecanicienScreens/ordreTravail/work_ordre_page.dart';
import 'package:garagelink/models/devis.dart';
import 'package:garagelink/models/ordre.dart';
import 'package:garagelink/providers/ordres_provider.dart';
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/global.dart';
import 'package:get/get.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  // on garde le Devis passé (obligatoire)
  final Devis devis;
  const CreateOrderScreen({super.key, required this.devis});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final clientCtrl = TextEditingController();
  final vinCtrl = TextEditingController();
  final numLocalCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  late Devis devis;
  String? vehiculeId;
  String? vehicleInfo;

  // listes chargées depuis l'API
  List<Map<String, String>> services = [];
  List<Map<String, String>> mecaniciens = [];
  List<Map<String, String>> ateliers = [];

  // sélection (ids)
  String? selectedServiceId;
  String? selectedMecanicienId;
  String? selectedAtelierId;

  String? selectedServiceName;
  String? selectedMecanicienName;
  String? selectedAtelierName;

  DateTime date = DateTime.now();

  bool _submitting = false;
  bool _loadingMeta = true;
  String? _metaError;

 @override
void initState() {
  super.initState();

  // Si tu as passé le Devis via le constructeur (recommandé), l'utiliser directement :
  devis = widget.devis;

  // Récupérer vehiculeId / vehicleInfo depuis Get.arguments si présent, sinon depuis le Devis
  final args = Get.arguments;
  if (args != null && args is Map<String, dynamic>) {
    vehiculeId = args['vehiculeId'] as String? ?? widget.devis.vehiculeId;
    vehicleInfo = args['vehicleInfo'] as String? ?? widget.devis.vehicleInfo;
  } else {
    vehiculeId = widget.devis.vehiculeId;
    vehicleInfo = widget.devis.vehicleInfo;
  }

  _animationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  _fadeAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  );
  _animationController.forward();

  // Pré-remplir certains champs depuis le devis passé
  clientCtrl.text = devis.clientName.isNotEmpty ? devis.clientName : '';

  final idToShow = devis.devisId.isNotEmpty ? devis.devisId : (devis.id ?? '');
  descriptionCtrl.text = 'Travail lié au devis $idToShow';

  // Charger les listes (services, ateliers) immédiatement
  _loadMeta();
}


  @override
  void dispose() {
    _animationController.dispose();
    clientCtrl.dispose();
    vinCtrl.dispose();
    numLocalCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });

    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      setState(() {
        _metaError = 'Token manquant';
        _loadingMeta = false;
      });
      return;
    }

    try {
      final futures = await Future.wait([
        _fetchServices(token),
        _fetchAteliers(token),
      ]);
      services = futures[0] as List<Map<String, String>>;
      ateliers = futures[1] as List<Map<String, String>>;

      // si le devis contient un atelierId / serviceId nous pouvons pré-sélectionner (optionnel)
      // ex: if (widget.devis.preferredAtelierId != null) selectedAtelierId = widget.devis.preferredAtelierId;

      setState(() {
        _loadingMeta = false;
      });
    } catch (e) {
      setState(() {
        _metaError = e.toString();
        _loadingMeta = false;
      });
    }
  }

  Future<List<Map<String, String>>> _fetchServices(String token) async {
    final uri = Uri.parse('$UrlApi/getAllServices');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      List<dynamic> list;
      if (body is Map &&
          body.containsKey('success') &&
          body['success'] == true) {
        list = body['services'] ?? body['data'] ?? [];
      } else if (body is List) {
        list = body;
      } else {
        throw Exception('Format services inattendu');
      }
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        final name = (m['name'] ?? m['nom'] ?? m['serviceNom'] ?? '')
            .toString();
        return {'id': id, 'name': name};
      }).toList();
    } else {
      throw Exception('Erreur chargement services (${resp.statusCode})');
    }
  }

  Future<List<Map<String, String>>> _fetchAteliers(String token) async {
    final uri = Uri.parse('$UrlApi/getAllAteliers');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      List<dynamic> list;
      if (body is Map &&
          body.containsKey('success') &&
          body['success'] == true) {
        list = body['ateliers'] ?? body['data'] ?? [];
      } else if (body is List) {
        list = body;
      } else {
        throw Exception('Format ateliers inattendu');
      }
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        final name = (m['name'] ?? m['nom'] ?? '').toString();
        return {'id': id, 'name': name};
      }).toList();
    } else {
      throw Exception('Erreur chargement ateliers (${resp.statusCode})');
    }
  }

  Future<void> _fetchMecaniciensForService(String serviceId) async {
    mecaniciens = [];
    selectedMecanicienId = null;
    selectedMecanicienName = null;
    setState(() {});

    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) return;

    final uri = Uri.parse('$UrlApi/mecaniciens/by-service/$serviceId');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      List<dynamic> list;
      if (body is Map &&
          body.containsKey('success') &&
          body['success'] == true) {
        list = body['mecaniciens'] ?? body['data'] ?? [];
      } else if (body is List) {
        list = body;
      } else if (body is Map && body.containsKey('mecaniciens')) {
        list = body['mecaniciens'];
      } else {
        list = [];
      }

      mecaniciens = list.map((item) {
        final m = item as Map<String, dynamic>;
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        final name = (m['nom'] ?? m['name'] ?? '').toString();
        return {'id': id, 'name': name};
      }).toList();
      setState(() {});
    } else {
      // silencieux : pas de mécaniciens trouvés / erreur
      setState(() {});
    }
  }

  void _onCreatePressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedServiceId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sélectionner un service')));
      return;
    }
    if (selectedMecanicienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionner un mécanicien')),
      );
      return;
    }
    if (selectedAtelierId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sélectionner un atelier')));
      return;
    }

    setState(() => _submitting = true);

    final tache = Tache(
      description: descriptionCtrl.text.trim().isEmpty
          ? 'Travail'
          : descriptionCtrl.text.trim(),
      serviceId: selectedServiceId!,
      serviceNom: selectedServiceName ?? '',
      mecanicienId: selectedMecanicienId!,
      mecanicienNom: selectedMecanicienName ?? '',
      estimationHeures: 1.0,
    );

    try {

      // Utiliser l'ID du devis réel (devisId si présent sinon id)
      final String linkedDevisId = devis.devisId.isNotEmpty ? devis.devisId : (devis.id ?? '');

      if (linkedDevisId.isEmpty) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible : identifiant du devis introuvable')),
    );
  }
  setState(() => _submitting = false);
  return;
}


  await ref.read(ordresProvider.notifier).createOrdre(
    devisId: linkedDevisId,
    dateCommence: date,
    atelierId: selectedAtelierId!,
    priorite: 'normale',
    description: descriptionCtrl.text.trim(),
    taches: [tache],
  );

  // Vérifier si le provider a enregistré une erreur
  final currentState = ref.read(ordresProvider);
  if (currentState.error != null) {
    // erreur : afficher et rester sur la page
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur création ordre : ${currentState.error}')),
      );
    }
    return;
  }

  // tout va bien -> naviguer
  if (mounted) Get.off(() => const WorkOrderPage());
} catch (e) {
  // sécurité : normalement createOrdre attrape déjà, mais on gère au cas où
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur création ordre inattendue : $e')),
    );
  }
} finally {
  if (mounted) setState(() => _submitting = false);
}

  }

  @override
  Widget build(BuildContext context) {
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Créer un ordre',
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
              ),
            ),
            backgroundColor: const Color(0xFF4A90E2),
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 16,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModernCard(
                        title: 'Informations Client',
                        icon: Icons.person,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            ModernTextField(
                              controller: clientCtrl,
                              label: 'Client',
                              icon: Icons.person,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Obligatoire'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ModernCard(
                        title: 'Véhicule',
                        icon: Icons.directions_car,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: vehicleInfo,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "Véhicule du client",
                                prefixIcon: Icon(Icons.directions_car),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ModernCard(
                        title: 'Détails de l\'ordre',
                        icon: Icons.settings,
                        borderColor: const Color(0xFF4A90E2),
                        child: Column(
                          children: [
                            // Service (chargé depuis API)
                            _loadingMeta
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: LinearProgressIndicator(),
                                  )
                                : DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Service',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: selectedServiceId,
                                    items: services
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s['id'],
                                            child: Text(s['name'] ?? ''),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) async {
                                      setState(() {
                                        selectedServiceId = val;
                                        selectedServiceName = services
                                            .firstWhere(
                                              (s) => s['id'] == val,
                                            )['name'];
                                      });
                                      if (val != null) {
                                        await _fetchMecaniciensForService(val);
                                      }
                                    },
                                    validator: (v) => v == null
                                        ? "Sélectionner un service"
                                        : null,
                                  ),
                            const SizedBox(height: 16),

                            // Mécanicien (rempli après sélection service)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Mécanicien',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedMecanicienId,
                              items: mecaniciens.isNotEmpty
                                  ? mecaniciens
                                        .map(
                                          (m) => DropdownMenuItem(
                                            value: m['id'],
                                            child: Text(m['name'] ?? ''),
                                          ),
                                        )
                                        .toList()
                                  : [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          'Sélectionner le service d\'abord',
                                        ),
                                      ),
                                    ],
                              onChanged: (val) => setState(() {
                                selectedMecanicienId = val;
                                selectedMecanicienName =
                                    mecaniciens.isNotEmpty && val != null
                                    ? mecaniciens.firstWhere(
                                        (m) => m['id'] == val,
                                      )['name']
                                    : null;
                              }),
                              validator: (v) => v == null
                                  ? "Sélectionner un mécanicien"
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Atelier (chargé depuis API)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Atelier',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedAtelierId,
                              items: ateliers
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a['id'],
                                      child: Text(a['name'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                selectedAtelierId = v;
                                selectedAtelierName = ateliers.firstWhere(
                                  (a) => a['id'] == v,
                                )['name'];
                              }),
                              validator: (v) =>
                                  v == null ? "Sélectionner un atelier" : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: descriptionCtrl,
                              decoration: const InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Description obligatoire"
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DatePicker(
                              date: date,
                              isTablet: isTablet,
                              onDateChanged: (d) => setState(() => date = d),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: GenerateButton(
                          onPressed: _submitting ? null : _onCreatePressed,
                          text: _submitting
                              ? 'Création...'
                              : 'Créer et retourner',
                        ),
                      ),
                      if (_metaError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Erreur chargement données: $_metaError',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
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
