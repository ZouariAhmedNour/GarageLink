import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/providers/localisation_provider.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class EditLocalisation extends ConsumerStatefulWidget {
  const EditLocalisation({super.key});

  @override
  ConsumerState<EditLocalisation> createState() => _EditLocalisationState();
}

class _EditLocalisationState extends ConsumerState<EditLocalisation> with TickerProviderStateMixin {
  final MapController mapController = MapController();
  late TextEditingController nomController;
  late TextEditingController emailController;
  late TextEditingController telController;
  late TextEditingController adresseController;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final localisation = ref.read(localisationProvider);
    nomController = TextEditingController(text: localisation.nomGarage);
    emailController = TextEditingController(text: localisation.email);
    telController = TextEditingController(text: localisation.telephone);
    adresseController = TextEditingController(text: localisation.adresse);
    
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nomController.dispose();
    emailController.dispose();
    telController.dispose();
    adresseController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(DialogType.warning, 'Service désactivé', 'Veuillez activer la localisation sur votre appareil.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog(DialogType.error, 'Permission refusée', 'Les permissions de localisation sont refusées.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog(DialogType.error, 'Permission refusée définitivement', 'Veuillez autoriser la localisation dans les paramètres.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latlng = LatLng(position.latitude, position.longitude);
      
      ref.read(localisationProvider.notifier).setPosition(latlng);
      mapController.move(latlng, 16);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position actuelle détectée avec succès ✓'), backgroundColor: Color(0xFF357ABD)),
      );
    } catch (e) {
      _showLocationDialog(DialogType.error, 'Erreur', 'Impossible d\'obtenir votre position.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationDialog(DialogType type, String title, String desc) {
    AwesomeDialog(context: context, dialogType: type, title: title, desc: desc, btnOkOnPress: () {}).show();
  }

  void _saveLocation() {
    if (_formKey.currentState!.validate()) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        title: "Succès",
        desc: "Votre localisation a été enregistrée avec succès",
        btnOkText: "Parfait !",
        btnOkColor: const Color(0xFF357ABD),
        btnOkOnPress: () => Get.back(result: true),
      ).show();
    }
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
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Éditer Localisation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              background: Container(
                decoration: const BoxDecoration(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveLocation,
        backgroundColor: const Color(0xFF357ABD),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text('Sauvegarder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMapCard(dynamic localisation, dynamic notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
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
                  child: const Icon(Icons.map, color: Color(0xFF357ABD), size: 24),
                ),
                const SizedBox(width: 16),
                const Text('Localisation sur la carte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          Container(
            height: 280,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: localisation.position ?? LatLng(36.8065, 10.1815),
                  initialZoom: 13,
                  onTap: (tapPosition, latlng) {
                    notifier.setPosition(latlng);
                    mapController.move(latlng, 16);
                    HapticFeedback.lightImpact();
                  },
                ),
                children: [
                  TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.garagelink.app'),
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
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.garage, color: Colors.white, size: 28),
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
                border: Border.all(color: const Color(0xFF357ABD).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF357ABD), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "📍 ${localisation.position!.latitude.toStringAsFixed(6)}, ${localisation.position!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF357ABD), fontSize: 14),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 22),
                label: Text(_isLoading ? "Localisation..." : "Utiliser ma position actuelle", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(dynamic notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
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
                child: const Icon(Icons.edit, color: Color(0xFF357ABD), size: 24),
              ),
              const SizedBox(width: 16),
              const Text('Informations du garage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(nomController, 'Nom du garage', Icons.garage, notifier.setNomGarage, 'Veuillez saisir le nom du garage'),
          const SizedBox(height: 16),
          _buildTextField(emailController, 'Adresse email', Icons.email, notifier.setEmail, 'Veuillez saisir une adresse email valide', TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(telController, 'Numéro de téléphone', Icons.phone, notifier.setTelephone, 'Veuillez saisir le numéro de téléphone', TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(adresseController, 'Adresse complète', Icons.location_city, notifier.setAdresse, 'Veuillez saisir l\'adresse', TextInputType.streetAddress),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, Function(String) onChanged, String validation, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: (value) => value?.isEmpty == true ? validation : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF357ABD)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF357ABD), width: 2)),
        filled: true,
        fillColor: const Color(0xFF357ABD).withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}