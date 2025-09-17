import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/models/cite.dart'; // City, City.location (Geo)
import 'package:garagelink/models/governorate.dart';
import 'package:garagelink/models/user.dart'
    as user_model; // alias pour éviter l'ambiguïté Location
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/providers/client_map_provider.dart';
import 'package:garagelink/providers/localisation_provider.dart';
import 'package:garagelink/services/cite_api.dart';
import 'package:garagelink/services/gouvernorat_api.dart';
import 'package:garagelink/services/user_api.dart';
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
  static const primaryColor = Color(0xFF357ABD);
  static const backgroundColor = Color(0xFFF8FAFC);

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

  // Data passed from signup page
  late final Map<String, dynamic> _registrationData;

  // Governorates and cities lists
  List<Governorate> _governorates = [];
  List<City> _cities = [];
  String? _selectedGovernorateId;
  String? _selectedCityId;

  bool _didInitDependencies = false; // <-- guard

  @override
  void initState() {
    super.initState();

    // Animation (ne dépend pas du context)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // NE PAS initialiser ici tout ce qui dépend du BuildContext / providers / Get.arguments.
  }

 @override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_didInitDependencies) return;
  _didInitDependencies = true;

  final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
  _registrationData = args;

  // initial local snapshot (sera écrasé par _initFromArgsAndUser si on a un user)
  final localisation = ref.read(localisationProvider);

  // Initialisation des controllers (valeurs par défaut)
  nomController = TextEditingController(
    text: args['username']?.toString() ?? localisation.nomGarage,
  );
  emailController = TextEditingController(
    text: args['email']?.toString() ?? localisation.email,
  );
  telController = TextEditingController(
    text: args['phone']?.toString() ?? localisation.telephone,
  );
  adresseController = TextEditingController(text: localisation.adresse);
  matriculeController = TextEditingController(
    text: args['matriculefiscal']?.toString() ?? localisation.matriculefiscal,
  );

  _selectedGovernorateId =
      (args['governorateId']?.toString().isNotEmpty == true)
          ? args['governorateId'].toString()
          : localisation.governorateId;
  _selectedCityId = (args['cityId']?.toString().isNotEmpty == true)
      ? args['cityId'].toString()
      : localisation.cityId;

  // déplacer la carte après le premier frame (sécurise l'accès au mapController/élément)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final initialPosition =
        ref.read(clientLocationProvider).position ??
        localisation.position ??
        LatLng(36.8065, 10.1815);
    try {
      mapController.move(initialPosition, 14);
    } catch (_) {}
  });

  // lance l'initialisation asynchrone qui récupère l'utilisateur si besoin
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initFromArgsAndUser(args);
  });

  // Charger les gouvernorats (async)
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

  /// Initialise les controllers / provider depuis :
/// 1) Get.arguments (si fourni) sinon
/// 2) l'utilisateur présent dans auth provider
/// 3) si token présent mais pas d'user, appelle UserApi.getProfile(token) et met à jour auth provider
Future<void> _initFromArgsAndUser(Map<String, dynamic> args) async {
  try {
    // 1) si args contient déjà des valeurs, on les garde (déjà assignées)
    // 2) sinon, essayer d'utiliser l'user du provider
    var user = args['user'] as user_model.User?;
    var token = args['token'] as String?;

    final authState = ref.read(authNotifierProvider);
    token ??= authState.token;
    user ??= authState.user;

    // Si on a un token mais pas d'user : charger le profile depuis l'API et persister
    if (token != null && user == null) {
      try {
        final fetched = await UserApi.getProfile(token);
        await ref.read(authNotifierProvider.notifier).setUser(fetched);
        user = fetched;
      } catch (e) {
        // ignore : on continue sans user (la page fonctionnera mais champs vides)
        debugPrint('Could not fetch profile in _initFromArgsAndUser: $e');
      }
    }

    if (user != null) {
      // Remplir les controllers si vides / non fournis via args
      if ((args['username'] == null || args['username'].toString().isEmpty) && nomController.text.trim().isEmpty) {
        nomController.text = user.username;
        ref.read(localisationProvider.notifier).setNomGarage(user.username);
      }
      if ((args['email'] == null || args['email'].toString().isEmpty) && emailController.text.trim().isEmpty) {
        emailController.text = user.email;
        ref.read(localisationProvider.notifier).setEmail(user.email);
      }
      if ((args['phone'] == null || args['phone'].toString().isEmpty) && telController.text.trim().isEmpty) {
        if (user.phone != null) {
          telController.text = user.phone!;
          ref.read(localisationProvider.notifier).setTelephone(user.phone!);
        }
      }
      if ((args['matriculefiscal'] == null || args['matriculefiscal'].toString().isEmpty) && matriculeController.text.trim().isEmpty) {
        if (user.matriculefiscal != null) {
          matriculeController.text = user.matriculefiscal!;
          ref.read(localisationProvider.notifier).setMatriculeFiscal(user.matriculefiscal!);
        }
      }
      // governorate / city / streetAddress
      if ((user.governorateId?.isNotEmpty ?? false)) {
        _selectedGovernorateId ??= user.governorateId;
        ref.read(localisationProvider.notifier).setGovernorate(
          id: user.governorateId!,
          name: user.governorateName ?? '',
        );
      }
      if ((user.cityId?.isNotEmpty ?? false)) {
        _selectedCityId ??= user.cityId;
        ref.read(localisationProvider.notifier).setCity(
          id: user.cityId!,
          name: user.cityName ?? '',
        );
      }
      if ((user.streetAddress?.isNotEmpty ?? false) && adresseController.text.trim().isEmpty) {
        adresseController.text = user.streetAddress;
        ref.read(localisationProvider.notifier).setAdresse(user.streetAddress);
      }

      // Si l'utilisateur a une location GeoJSON, positionner la carte
      if (user.location?.coordinates != null && user.location!.coordinates.length >= 2) {
        final lng = user.location!.coordinates[0];
        final lat = user.location!.coordinates[1];
        final latlng = LatLng(lat, lng);
        ref.read(clientLocationProvider.notifier).setPosition(latlng);
        ref.read(localisationProvider.notifier).setPosition(latlng);
        // déplacer la carte après frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            mapController.move(latlng, 14);
          } catch (e) {
            debugPrint('mapController.move in initFromUser failed: $e');
          }
        });
      }
    }
  } catch (e, st) {
    debugPrint('_initFromArgsAndUser error: $e\n$st');
  }
}

  Future<void> _loadGovernorates() async {
    setState(() => _isLoading = true);
    try {
      final token = ref.read(authNotifierProvider).token;

      List<Governorate> governorates;
      if (token == null) {
        // Utiliser la route publique si pas de token
        governorates = await GovernorateApi.getAllGovernoratesPublic();
      } else {
        governorates = await GovernorateApi.getAllGovernorates(token);
      }

      setState(() => _governorates = governorates);

      if (_selectedGovernorateId != null &&
          _selectedGovernorateId!.isNotEmpty) {
        final sel = governorates.firstWhere(
          (g) => g.id == _selectedGovernorateId,
          orElse: () => Governorate(id: '', name: ''),
        );
        final selName = sel.name ?? '';
        if (selName.isNotEmpty) {
          ref
              .read(localisationProvider.notifier)
              .setGovernorate(id: _selectedGovernorateId!, name: selName);
        }
        await _loadCitiesForGovernorate(
          _selectedGovernorateId!,
          clearSelectedCity: false,
        );
      }
    } catch (e, st) {
      debugPrint('Exception _loadGovernorates: $e\n$st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog(
          DialogType.error,
          'Erreur',
          'Erreur lors du chargement des gouvernorats : $e',
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCitiesForGovernorate(
    String governorateId, {
    bool clearSelectedCity = true,
  }) async {
    setState(() {
      _cities = [];
      if (clearSelectedCity) _selectedCityId = null;
      _isLoading = true;
    });

    try {
      final token = ref.read(authNotifierProvider).token;
      List<City> cities;
      if (token == null) {
        cities = await CityApi.getCitiesByGovernoratePublic(governorateId);
      } else {
        cities = await CityApi.getCitiesByGovernorate(token, governorateId);
      }

      setState(() => _cities = cities);

      if (!clearSelectedCity &&
          _selectedCityId != null &&
          _selectedCityId!.isNotEmpty) {
        final sel = cities.firstWhere(
          (c) => c.id == _selectedCityId,
          orElse: () => City(id: '', name: ''),
        );
        final selName = sel.name ?? '';
        if (selName.isNotEmpty) {
          ref
              .read(localisationProvider.notifier)
              .setCity(id: _selectedCityId!, name: selName);
        }
      }
    } catch (e, st) {
      debugPrint('Exception _loadCitiesForGovernorate: $e\n$st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog(
          DialogType.error,
          'Erreur',
          'Erreur lors du chargement des villes : $e',
        );
      });
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

      ref.read(clientLocationProvider.notifier).setPosition(latlng);
      ref.read(localisationProvider.notifier).setPosition(latlng);
      try {
        mapController.move(latlng, 16);
      } catch (e) {
        debugPrint('mapController.move error: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position actuelle détectée avec succès ✓'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      _showLocationDialog(
        DialogType.error,
        'Erreur',
        'Impossible d\'obtenir votre position : $e',
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

  if (_selectedGovernorateId == null || _selectedCityId == null) {
    _showLocationDialog(
      DialogType.error,
      'Champs manquants',
      'Veuillez sélectionner un gouvernorat et une ville.',
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Récupérer token et user depuis Get.arguments si présents, sinon depuis le provider
    final args = (Get.arguments as Map<String, dynamic>?) ?? <String, dynamic>{};
    String? token = args['token'] as String?;
    user_model.User? user = args['user'] as user_model.User?;

    // fallback : prendre depuis auth provider si absent dans args
    final authState = ref.read(authNotifierProvider);
    if (token == null) token = authState.token;
    if (user == null) user = authState.user;

    if (token == null || user == null) {
      throw Exception('Token ou utilisateur manquant');
    }

    // Vérifier la position
    final localisation = ref.read(localisationProvider);
    if (localisation.position == null) {
      throw Exception('Localisation non définie');
    }
    final latitude = localisation.position!.latitude;
    final longitude = localisation.position!.longitude;

    // Appel API pour compléter le profil -> récupère l'utilisateur mis à jour
    final updatedUser = await UserApi.completeProfile(
      token: token,
      username: user.username,
      garagenom: user.garagenom ?? '',
      matriculefiscal: user.matriculefiscal ?? '',
      email: user.email,
      phone: user.phone ?? '',
      governorateId: _selectedGovernorateId!,
      cityId: _selectedCityId!,
      governorateName: localisation.governorateName,
      cityName: localisation.cityName,
      streetAddress: adresseController.text,
      location: user_model.Location(
        type: 'Point',
        coordinates: [longitude, latitude],
      ),
    );

    // Mettre à jour le auth provider avec le token + user mis à jour
    await ref.read(authNotifierProvider.notifier).setToken(token, userToSave: updatedUser);

    // Succès et redirection (dialog puis navigation)
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      title: 'Profil complété',
      desc: 'Votre profil a été mis à jour avec succès.',
      btnOkText: 'Continuer',
      btnOkColor: primaryColor,
      btnOkOnPress: () {
        // Remplacer la pile et aller à la home
        Get.offAllNamed(AppRoutes.mecaHome);
      },
    ).show();
  } catch (e, st) {
    debugPrint('_saveLocation error: $e\n$st');
    _showLocationDialog(
      DialogType.error,
      'Erreur',
      'Erreur lors de la mise à jour : $e',
    );
  } finally {
    setState(() => _isLoading = false);
  }
}



  Future<void> _showSelectionSheet({
    required String title,
    required List<dynamic> options,
    required String? selectedId,
    required FutureOr<void> Function(String id) onSelect, // <-- futureOr
  }) async {
    if (options.isEmpty) {
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
                    final id = opt.id?.toString() ?? '';
                    final name = opt.name?.toString() ?? id;
                    final isSelected = id == selectedId;
                    return ListTile(
                      title: Text(name),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: primaryColor)
                          : null,
                      onTap: () async {
                        try {
                          final res = onSelect(id);
                          if (res is Future) await res;
                        } catch (e) {
                          // Si onSelect échoue, log et laisser le sheet ouvert ou fermer selon ton choix
                          debugPrint('_showSelectionSheet onSelect error: $e');
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showLocationDialog(
                              DialogType.error,
                              'Erreur',
                              'Erreur interne : $e',
                            );
                          });
                        } finally {
                          Navigator.of(ctx).pop();
                        }
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

  void _moveToCoordinates(double lat, double lng, {double zoom = 14}) {
    final latlng = LatLng(lat, lng);
    ref.read(clientLocationProvider.notifier).setPosition(latlng);
    ref.read(localisationProvider.notifier).setPosition(latlng);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        mapController.move(latlng, zoom);
      } catch (e) {
        debugPrint('mapController.move failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localisation = ref.watch(localisationProvider);
    final clientLocation = ref.watch(clientLocationProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
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
                    colors: [primaryColor, Color(0xFF2A5A8A)],
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
                      _buildMapCard(clientLocation),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildFormCard(),
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
                          label: const Text(
                            'Sauvegarder et compléter le profil',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
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

  Widget _buildMapCard(ClientLocationState clientLocation) {
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
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map, color: primaryColor, size: 24),
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
                      clientLocation.position ?? LatLng(36.8065, 10.1815),
                  initialZoom: 13,
                  onTap: (tapPosition, latlng) {
                    ref
                        .read(clientLocationProvider.notifier)
                        .setPosition(latlng);
                    ref.read(localisationProvider.notifier).setPosition(latlng);
                    try {
                      mapController.move(latlng, 16);
                    } catch (e) {
                      debugPrint('map move error on tap: $e');
                    }
                    HapticFeedback.lightImpact();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.garagelink.app',
                  ),
                  if (clientLocation.position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: clientLocation.position!,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
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
          if (clientLocation.position != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📍 ${clientLocation.position!.latitude.toStringAsFixed(6)}, ${clientLocation.position!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
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
                  backgroundColor: primaryColor,
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
                      ? 'Localisation...'
                      : 'Utiliser ma position actuelle',
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
          colors: [primaryColor, Color(0xFF4A90E2)],
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

  Widget _buildFormCard() {
    final selectedGovernorateName =
        _governorates
            .firstWhere(
              (g) => g.id == _selectedGovernorateId,
              orElse: () => Governorate(id: '', name: ''),
            )
            .name ??
        '';
    final selectedCityName =
        _cities
            .firstWhere(
              (c) => c.id == _selectedCityId,
              orElse: () => City(id: '', name: ''),
            )
            .name ??
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
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: primaryColor, size: 24),
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
            (v) => ref.read(localisationProvider.notifier).setNomGarage(v),
            'Veuillez saisir le nom du garage',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            emailController,
            'Email',
            Icons.email,
            (v) => ref.read(localisationProvider.notifier).setEmail(v),
            'Veuillez saisir l\'email',
            TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            telController,
            'Téléphone',
            Icons.phone,
            (v) => ref.read(localisationProvider.notifier).setTelephone(v),
            'Veuillez saisir le numéro de téléphone',
            TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            matriculeController,
            'Matricule fiscal',
            Icons.badge,
            (v) =>
                ref.read(localisationProvider.notifier).setMatriculeFiscal(v),
            'Veuillez saisir le matricule fiscal',
            TextInputType.text,
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Gouvernorat',
              prefixIcon: const Icon(Icons.map, color: primaryColor),
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
                  onSelect: (id) async {
                    setState(() {
                      _selectedGovernorateId = id;
                      _selectedCityId = null;
                      _cities = [];
                    });

                    // Charger les villes pour ce gouvernorat (attendu par le sheet)
                    await _loadCitiesForGovernorate(id);

                    // mettre à jour le provider avec le nom
                    final sel = _governorates.firstWhere(
                      (g) => g.id == id,
                      orElse: () => Governorate(id: '', name: ''),
                    );
                    final selName = sel.name ?? '';
                    if (selName.isNotEmpty) {
                      ref
                          .read(localisationProvider.notifier)
                          .setGovernorate(id: id, name: selName);
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
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Ville / Délégation',
              prefixIcon: const Icon(Icons.location_city, color: primaryColor),
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
                      backgroundColor: Color(0xFFe74c3c),
                    ),
                  );
                  return;
                }
                await _showSelectionSheet(
                  title: 'Choisir une ville / délégation',
                  options: _cities,
                  selectedId: _selectedCityId,
                  onSelect: (id) {
                    setState(() => _selectedCityId = id);
                    final sel = _cities.firstWhere(
                      (c) => c.id == id,
                      orElse: () => City(id: '', name: ''),
                    );
                    final selName = sel.name ?? '';
                    ref
                        .read(localisationProvider.notifier)
                        .setCity(id: id, name: selName);
                    if (sel.location?.coordinates.isNotEmpty == true) {
                      final lng = sel.location!.coordinates[0];
                      final lat = sel.location!.coordinates[1];
                      _moveToCoordinates(lat, lng, zoom: 14);
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
            (v) => ref.read(localisationProvider.notifier).setAdresse(v),
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
      validator: (value) => value?.trim().isEmpty == true ? validation : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: primaryColor.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
