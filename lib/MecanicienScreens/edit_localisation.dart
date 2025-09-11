import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/city.dart';
import 'package:garagelink/models/governorate.dart';
import 'package:garagelink/providers/localisation_provider.dart';
import 'package:garagelink/services/cite_api.dart';
import 'package:garagelink/services/gouvernorat_api.dart';
import 'package:garagelink/services/user_service_api.dart';
import 'package:garagelink/services/api_client.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class EditLocalisation extends ConsumerStatefulWidget {
  const EditLocalisation({super.key});

  @override
  ConsumerState<EditLocalisation> createState() => _EditLocalisationState();
}

class _EditLocalisationState extends ConsumerState<EditLocalisation>
    with TickerProviderStateMixin {
  final MapController mapController = MapController();
  late TextEditingController nomController;
  late TextEditingController emailController;
  late TextEditingController telController;
  late TextEditingController adresseController;
  late TextEditingController matriculeController;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  // data passed from signup page
  late final Map<String, dynamic> _registrationData;

  // governorates / cities lists (list of maps with keys: _id,name,nameAr,...)
  List<Map<String, dynamic>> _governorates = [];
  List<Map<String, dynamic>> _cities = [];
  String? _selectedGovernorateId;
  String? _selectedCityId;

  final ApiClient _apiClient = ApiClient();

@override
void initState() {
  super.initState();

  final localisation = ref.read(localisationProvider);

  final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
  _registrationData = args;

  // Priorité : données passées via arguments (signup) -> sinon valeurs du provider
  final initialName = (args['username'] ?? localisation.nomGarage ?? '').toString();
  final initialEmail = (args['email'] ?? localisation.email ?? '').toString();
  final initialPhone = (args['phone'] ?? localisation.telephone ?? '').toString();
  final initialAddress = (localisation.adresse).toString();
  final initialMatricule = (args['matriculefiscal'] ?? localisation.matriculefiscal ?? '').toString();

  nomController = TextEditingController(text: initialName);
  emailController = TextEditingController(text: initialEmail);
  telController = TextEditingController(text: initialPhone);
  adresseController = TextEditingController(text: initialAddress);
  matriculeController = TextEditingController(text: initialMatricule);

  // Pré-remplir les ids si fournis par args / provider
  _selectedGovernorateId = (args['governorateId']?.toString().isNotEmpty == true)
      ? args['governorateId'].toString()
      : (localisation.governorateId);

  _selectedCityId = (args['cityId']?.toString().isNotEmpty == true)
      ? args['cityId'].toString()
      : (localisation.cityId);

  // Si provider contient une position, recentrer la carte dessus
  if (localisation.position != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        mapController.move(localisation.position!, 14);
      } catch (_) {}
    });
  }

  _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
  _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  _animationController.forward();

  // Charge gouvernorats -> si un gouvernorat était déjà sélectionné,
  // _loadGovernorates le détectera et chargera les villes automatiquement.
  _loadGovernorates();
}

  @override
  void dispose() {
    _animationController.dispose();
    nomController.dispose();
    emailController.dispose();
    telController.dispose();
    adresseController.dispose();
    matriculeController.dispose();
    super.dispose();
  }

Future<void> _loadGovernorates() async {
  setState(() => _isLoading = true);
  try {
    final res = await GouvernoratApi().getGovernorates();
    if (res['success'] == true && res['data'] is List) {
      final List data = res['data'];
      final parsed = <Map<String, dynamic>>[];
      for (final e in data) {
        String id = '';
        String name = '';
        String? nameAr;
        double? lat;
        double? lng;

        if (e is Governorate) {
          id = e.id;
          name = e.name;
          nameAr = e.nameAr;
        } else if (e is Map) {
          id = (e['_id'] ?? e['id'] ?? '').toString();
          name = (e['name'] ?? e['title'] ?? '').toString();
          nameAr = e['nameAr']?.toString();

          final loc = e['location'];
          if (loc is Map &&
              loc['coordinates'] is List &&
              (loc['coordinates'] as List).length >= 2) {
            final coords = (loc['coordinates'] as List);
            lng = double.tryParse(coords[0].toString());
            lat = double.tryParse(coords[1].toString());
          }

          lat ??= double.tryParse((e['lat'] ?? e['latitude'] ?? e['y'] ?? '').toString());
          lng ??= double.tryParse((e['lng'] ?? e['longitude'] ?? e['lon'] ?? e['x'] ?? '').toString());
        } else {
          id = e.toString();
          name = e.toString();
        }

        parsed.add({
          "_id": id,
          "name": name,
          "nameAr": nameAr,
          "lat": lat,
          "lng": lng,
        });
      }

      setState(() => _governorates = parsed);

      // Si un gouvernorat était déjà sélectionné (args ou provider), on cherche son nom et on met à jour le provider
      if (_selectedGovernorateId != null && _selectedGovernorateId!.isNotEmpty) {
        final sel = _governorates.firstWhere(
          (g) => (g['_id'] ?? '') == _selectedGovernorateId,
          orElse: () => <String, dynamic>{},
        );
        final selName = (sel['name'] ?? '').toString();
        if (selName.isNotEmpty) {
          // mettre à jour le provider pour garder l'état cohérent
          ref.read(localisationProvider.notifier).setGovernorate(id: _selectedGovernorateId!, name: selName);
        }
        // charger les villes pour ce gouvernorat (ne pas effacer _selectedCityId si il était passé en args)
        await _loadCitiesForGovernorate(_selectedGovernorateId!, clearSelectedCity: false);
      }
    } else {
      debugPrint('Erreur chargement gouvernorats: ${res['message']}');
    }
  } catch (e) {
    debugPrint('Exception _loadGovernorates: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

 Future<void> _loadCitiesForGovernorate(String governorateId, {bool clearSelectedCity = true}) async {
  setState(() {
    _cities = [];
    if (clearSelectedCity) _selectedCityId = null;
    _isLoading = true;
  });

  try {
    final res = await CiteApi().getCities(governorateId);
    if (res['success'] == true && res['data'] is List) {
      final List data = res['data'];
      final parsed = <Map<String, dynamic>>[];
      for (final e in data) {
        String id = '';
        String name = '';
        String? nameAr;
        String? postalCode;
        double? lat;
        double? lng;

        if (e is City) {
          id = e.id;
          name = e.name;
          nameAr = e.nameAr;
          postalCode = e.postalCode;
          if (e.coordinates != null && e.coordinates!.length >= 2) {
            lng = e.coordinates![0];
            lat = e.coordinates![1];
          }
        } else if (e is Map) {
          id = (e['_id'] ?? e['id'] ?? '').toString();
          name = (e['name'] ?? '').toString();
          nameAr = e['nameAr']?.toString();
          postalCode = e['postalCode']?.toString();

          final loc = e['location'];
          if (loc is Map && loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
            final coords = (loc['coordinates'] as List);
            lng = double.tryParse(coords[0].toString());
            lat = double.tryParse(coords[1].toString());
          }

          lat ??= double.tryParse((e['lat'] ?? e['latitude'] ?? e['y'] ?? '').toString());
          lng ??= double.tryParse((e['lng'] ?? e['longitude'] ?? e['lon'] ?? e['x'] ?? '').toString());
        } else {
          id = e.toString();
          name = e.toString();
        }

        parsed.add({
          "_id": id,
          "name": name,
          "nameAr": nameAr,
          "postalCode": postalCode,
          "lat": lat,
          "lng": lng,
        });
      }
      setState(() => _cities = parsed);

      // si on conserve la selection et qu'il y avait une cityId passée en args/provider, on met à jour le provider
      if (!clearSelectedCity && _selectedCityId != null && _selectedCityId!.isNotEmpty) {
        final sel = _cities.firstWhere(
          (c) => (c['_id'] ?? '') == _selectedCityId,
          orElse: () => <String, dynamic>{},
        );
        final selName = (sel['name'] ?? '').toString();
        if (selName.isNotEmpty) {
          ref.read(localisationProvider.notifier).setCity(id: _selectedCityId!, name: selName);
        }
      }
    } else {
      debugPrint('Erreur chargement villes: ${res['message']}');
    }
  } catch (e) {
    debugPrint('Exception _loadCitiesForGovernorate: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(
          DialogType.warning,
          'Service désactivé',
          'Veuillez activer la localisation sur votre appareil.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog(
            DialogType.error,
            'Permission refusée',
            'Les permissions de localisation sont refusées.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog(
          DialogType.error,
          'Permission refusée définitivement',
          'Veuillez autoriser la localisation dans les paramètres.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latlng = LatLng(position.latitude, position.longitude);

      ref.read(localisationProvider.notifier).setPosition(latlng);
      try {
        mapController.move(latlng, 16);
      } catch (e) {
        // mapController peut ne pas être prêt selon timing
        if (kDebugMode) debugPrint('mapController.move error: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position actuelle détectée avec succès ✓'),
          backgroundColor: Color(0xFF357ABD),
        ),
      );
    } catch (e) {
      _showLocationDialog(
        DialogType.error,
        'Erreur',
        'Impossible d\'obtenir votre position.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationDialog(DialogType type, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
    ).show();
  }

Future<void> _saveLocation() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // Valeurs prioritaires : controllers > args > provider
    final username = nomController.text.trim().isNotEmpty
        ? nomController.text.trim()
        : (_registrationData['username']?.toString() ?? '');
    final email = emailController.text.trim().isNotEmpty
        ? emailController.text.trim()
        : (_registrationData['email']?.toString() ?? '');
    final phone = telController.text.trim().isNotEmpty
        ? telController.text.trim()
        : (_registrationData['phone']?.toString() ?? '');
    final password = (_registrationData['password'] ?? '').toString();

    // Validation minimale côté client
    if (username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showLocationDialog(
        DialogType.error,
        'Champs manquants',
        'Veuillez vérifier : nom, email, téléphone et mot de passe sont requis.',
      );
      setState(() => _isLoading = false);
      return;
    }

    // Récupère l'état du provider
    final localisationState = ref.read(localisationProvider);
    final LatLng? pos = localisationState.position;

    Map<String, dynamic>? location;
    if (pos != null) {
      location = {
        "type": "Point",
        "coordinates": [pos.longitude, pos.latitude], // lng, lat
      };
    }

    // Fallback pour gouvernorat / ville (provider si écran n'a pas été modifié)
    final governorateIdToSend = _selectedGovernorateId ?? localisationState.governorateId;
    final cityIdToSend = _selectedCityId ?? localisationState.cityId;

    // Récupérer aussi les noms : d'abord args > provider > essayer lookup dans listes chargées
    String? governorateNameToSend = _registrationData['governorateName']?.toString();
    governorateNameToSend ??= localisationState.governorateName;
    if ((governorateNameToSend == null || governorateNameToSend.isEmpty) && governorateIdToSend != null) {
      final sel = _governorates.firstWhere(
        (g) => (g['_id'] ?? '') == governorateIdToSend,
        orElse: () => <String, dynamic>{},
      );
      governorateNameToSend = (sel['name'] ?? '').toString();
    }

    String? cityNameToSend = _registrationData['cityName']?.toString();
    cityNameToSend ??= localisationState.cityName;
    if ((cityNameToSend == null || cityNameToSend.isEmpty) && cityIdToSend != null) {
      final sel = _cities.firstWhere(
        (c) => (c['_id'] ?? '') == cityIdToSend,
        orElse: () => <String, dynamic>{},
      );
      cityNameToSend = (sel['name'] ?? '').toString();
    }

    // fallback pour streetAddress : controller > provider > ''
    final street = adresseController.text.trim().isNotEmpty
        ? adresseController.text.trim()
        : (localisationState.adresse ?? '');

    // Prépare le payload sans inclure de null explicite, inclut les names
    final payload = <String, dynamic>{
      "username": username,
      "garagenom": (_registrationData['garagenom']?.toString().isNotEmpty == true)
          ? _registrationData['garagenom'].toString()
          : "Mon Garage",
      "matriculefiscal": matriculeController.text.trim(),
      "email": email,
      "password": password,
      "phone": phone,
      if (street.isNotEmpty) "streetAddress": street,
      if (governorateIdToSend != null && governorateIdToSend.isNotEmpty) "governorateId": governorateIdToSend,
      if (governorateNameToSend != null && governorateNameToSend.isNotEmpty) "governorateName": governorateNameToSend,
      if (cityIdToSend != null && cityIdToSend.isNotEmpty) "cityId": cityIdToSend,
      if (cityNameToSend != null && cityNameToSend.isNotEmpty) "cityName": cityNameToSend,
      if (location != null) "location": location,
    };

    if (kDebugMode) {
      debugPrint('[REGISTER PAYLOAD] ${jsonEncode(payload)}');
    }

    // Appel au service
    final userService = UserService();
    final res = await userService.register(
      username: payload['username'],
      garagenom: payload['garagenom'],
      matriculefiscal: payload['matriculefiscal'],
      email: payload['email'],
      password: payload['password'],
      phone: payload['phone'],
      streetAddress: payload.containsKey('streetAddress') ? payload['streetAddress'] as String : null,
      location: payload.containsKey('location') ? payload['location'] as Map<String, dynamic> : null,
      governorateId: payload.containsKey('governorateId') ? payload['governorateId'] as String : null,
      cityId: payload.containsKey('cityId') ? payload['cityId'] as String : null,
    );

    if (kDebugMode) debugPrint('[REGISTER RESPONSE] $res');

    if (res['success'] == true) {
      // extraction du token possible selon différentes structures
      String? token;
      if (res.containsKey('token') && res['token'] is String) {
        token = res['token'] as String;
      } else if (res.containsKey('accessToken') && res['accessToken'] is String) {
        token = res['accessToken'] as String;
      } else if (res.containsKey('data') && res['data'] is Map && (res['data']['token'] != null)) {
        token = res['data']['token'] as String?;
      }

      if (token != null && token.isNotEmpty) {
        try {
          await _apiClient.saveToken(token);
          if (kDebugMode) debugPrint('Token saved after register.');
        } catch (e) {
          if (kDebugMode) debugPrint('Saving token failed: $e');
        }
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        title: "Compte créé",
        desc: "Votre compte a été créé avec succès.",
        btnOkText: "Continuer",
        btnOkColor: const Color(0xFF357ABD),
        btnOkOnPress: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(
              AppRoutes.mecaHome,
              arguments: {
                'justLoggedIn': true,
                'message': token != null ? 'Compte créé et connecté.' : 'Compte créé. Connectez-vous.',
              },
            );
          });
        },
      ).show();
    } else {
      _showLocationDialog(
        DialogType.error,
        'Erreur',
        res['message'] ?? 'Impossible de créer le compte',
      );
    }
  } catch (e) {
    _showLocationDialog(
      DialogType.error,
      'Erreur',
      'Erreur lors de la communication : $e',
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  // ---------- Helper: open selection sheet ----------
  Future<void> _showSelectionSheet({
    required String title,
    required List<Map<String, dynamic>> options,
    required String? selectedId,
    required void Function(String id) onSelect,
  }) async {
    if (options.isEmpty) {
      // nothing to select
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune option disponible'),
          backgroundColor: Color(0xFFe74c3c),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final opt = options[i];
                    final id = (opt['_id'] ?? opt['id'] ?? '').toString();
                    final name = (opt['name'] ?? opt['title'] ?? id).toString();
                    final isSelected = id == selectedId;
                    return ListTile(
                      title: Text(name),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF357ABD))
                          : null,
                      onTap: () {
                        onSelect(id);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // helper : déplace la carte et met à jour le provider
  // helper : déplace la carte et met à jour le provider
  void _moveToCoordinates(double lat, double lng, {double zoom = 14}) {
    final latlng = LatLng(lat, lng);

    // Mettre à jour le provider en premier (met le marker)
    ref.read(localisationProvider.notifier).setPosition(latlng);

    // Exécuter le move après la frame pour être sûr que la carte est prête
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (kDebugMode) debugPrint('[MAP] moving to $lat,$lng (zoom $zoom)');
        mapController.move(latlng, zoom);
      } catch (e) {
        if (kDebugMode)
          debugPrint('[MAP] mapController.move failed: $e — retrying in 150ms');
        // retry court délai si la carte n'était pas prête
        Future.delayed(const Duration(milliseconds: 150), () {
          try {
            if (kDebugMode) debugPrint('[MAP] retry move to $lat,$lng');
            mapController.move(latlng, zoom);
          } catch (e2) {
            if (kDebugMode) debugPrint('[MAP] retry failed: $e2');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localisation = ref.watch(localisationProvider);
    final notifier = ref.read(localisationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF357ABD),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Éditer Localisation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF357ABD), Color(0xFF2A5A8A)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMapCard(localisation, notifier),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildFormCard(notifier),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveLocation,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Sauvegarder et créer le compte'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF357ABD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
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

  Widget _buildMapCard(dynamic localisation, dynamic notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF357ABD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map,
                    color: Color(0xFF357ABD),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Localisation sur la carte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 280,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter:
                      localisation.position ?? LatLng(36.8065, 10.1815),
                  initialZoom: 13,
                  onTap: (tapPosition, latlng) {
                    notifier.setPosition(latlng);
                    try {
                      mapController.move(latlng, 16);
                    } catch (e) {
                      if (kDebugMode) debugPrint('map move error on tap: $e');
                    }
                    HapticFeedback.lightImpact();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.garagelink.app',
                  ),
                  if (localisation.position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: localisation.position!,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF357ABD),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.garage,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (localisation.position != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF357ABD).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF357ABD).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF357ABD),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "📍 ${localisation.position!.latitude.toStringAsFixed(6)}, ${localisation.position!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF357ABD),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _useCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF357ABD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location, size: 22),
                label: Text(
                  _isLoading
                      ? "Localisation..."
                      : "Utiliser ma position actuelle",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF357ABD), Color(0xFF4A90E2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tapez sur la carte ou utilisez votre position actuelle pour définir l\'emplacement de votre garage.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(dynamic notifier) {
    final selectedGovernorateName =
        _governorates.firstWhere(
              (g) => (g['_id'] ?? '') == (_selectedGovernorateId ?? ''),
              orElse: () => {},
            )['name']
            as String? ??
        '';
    final selectedCityName =
        _cities.firstWhere(
              (c) => (c['_id'] ?? '') == (_selectedCityId ?? ''),
              orElse: () => {},
            )['name']
            as String? ??
        '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF357ABD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF357ABD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Informations du garage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            nomController,
            'Nom du garage',
            Icons.garage,
            (v) => notifier.setNomGarage(v),
            'Veuillez saisir le nom du garage',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            matriculeController,
            'Matricule fiscal',
            Icons.badge,
            (v) {},
            'Veuillez saisir le matricule fiscal',
            TextInputType.text,
          ),
          const SizedBox(height: 16),

          // Debug badges to see counts
          Row(
            children: [
              Chip(label: Text('Gouvernorats: ${_governorates.length}')),
              const SizedBox(width: 8),
              Chip(label: Text('Villes: ${_cities.length}')),
            ],
          ),
          const SizedBox(height: 8),

          // Custom select for Gouvernorat (modal sheet)
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Gouvernorat',
              prefixIcon: const Icon(Icons.map),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: InkWell(
              onTap: () async {
                await _showSelectionSheet(
                  title: 'Choisir un gouvernorat',
                  options: _governorates,
                  selectedId: _selectedGovernorateId,
                  onSelect: (id) {
                    setState(() {
                      _selectedGovernorateId = id;
                      _selectedCityId = null;
                      _cities = [];
                    });
                    _loadCitiesForGovernorate(id);

                    final sel = _governorates.firstWhere(
                      (g) => (g['_id'] ?? '') == id,
                      orElse: () => <String, dynamic>{},
                    );

                    final selName = (sel['name'] ?? '').toString();
                    // mettre à jour le provider (utile pour garder l'état cohérent)
                    ref
                        .read(localisationProvider.notifier)
                        .setGovernorate(id: id, name: selName);

                    // parser lat/lng de façon sûre
                    double? lat;
                    double? lng;
                    final rawLat = sel['lat'];
                    final rawLng = sel['lng'];
                    if (rawLat != null) {
                      if (rawLat is num)
                        lat = rawLat.toDouble();
                      else
                        lat = double.tryParse(rawLat.toString());
                    }
                    if (rawLng != null) {
                      if (rawLng is num)
                        lng = rawLng.toDouble();
                      else
                        lng = double.tryParse(rawLng.toString());
                    }

                    if (lat != null && lng != null) {
                      if (kDebugMode)
                        debugPrint(
                          '[MAP] gouvernorat selected -> lat:$lat lng:$lng',
                        );
                      _moveToCoordinates(lat, lng, zoom: 10);
                    } else {
                      if (kDebugMode)
                        debugPrint(
                          '[MAP] gouvernorat selected but no coords found for id=$id',
                        );
                    }
                  },
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedGovernorateName.isEmpty
                          ? 'Sélectionner un gouvernorat'
                          : selectedGovernorateName,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Custom select for City (modal sheet)
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Ville / Délégation',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: InkWell(
              onTap: () async {
                if (_selectedGovernorateId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Veuillez d\'abord sélectionner un gouvernorat',
                      ),
                    ),
                  );
                  return;
                }
                await _showSelectionSheet(
                  title: 'Choisir une ville / délégation',
                  options: _cities,
                  selectedId: _selectedCityId,
                  onSelect: (id) {
                    setState(() {
                      _selectedCityId = id;
                    });

                    final sel = _cities.firstWhere(
                      (c) => (c['_id'] ?? '') == id,
                      orElse: () => <String, dynamic>{},
                    );

                    final selName = (sel['name'] ?? '').toString();
                    ref
                        .read(localisationProvider.notifier)
                        .setCity(id: id, name: selName);

                    double? lat;
                    double? lng;
                    final rawLat = sel['lat'];
                    final rawLng = sel['lng'];
                    if (rawLat != null) {
                      if (rawLat is num)
                        lat = rawLat.toDouble();
                      else
                        lat = double.tryParse(rawLat.toString());
                    }
                    if (rawLng != null) {
                      if (rawLng is num)
                        lng = rawLng.toDouble();
                      else
                        lng = double.tryParse(rawLng.toString());
                    }

                    if (lat != null && lng != null) {
                      if (kDebugMode)
                        debugPrint('[MAP] city selected -> lat:$lat lng:$lng');
                      _moveToCoordinates(lat, lng, zoom: 14);
                    } else {
                      if (kDebugMode)
                        debugPrint(
                          '[MAP] city selected but no coords found for id=$id',
                        );
                    }
                  },
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCityName.isEmpty
                          ? 'Sélectionner une ville'
                          : selectedCityName,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildTextField(
            adresseController,
            'Rue / Adresse complète',
            Icons.location_on,
            (v) => notifier.setAdresse(v),
            'Veuillez saisir l\'adresse',
            TextInputType.streetAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    Function(String) onChanged,
    String validation, [
    TextInputType? keyboardType,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: (value) => value?.isEmpty == true ? validation : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF357ABD)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF357ABD), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF357ABD).withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
