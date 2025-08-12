import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
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

class _EditLocalisationState extends ConsumerState<EditLocalisation> {
  final MapController mapController = MapController();
  late TextEditingController nomController;
  late TextEditingController emailController;
  late TextEditingController telController;
  late TextEditingController adresseController;

  @override
  void initState() {
    super.initState();
    final localisation = ref.read(localisationProvider);
    nomController = TextEditingController(text: localisation.nomGarage);
    emailController = TextEditingController(text: localisation.email);
    telController = TextEditingController(text: localisation.telephone);
    adresseController = TextEditingController(text: localisation.adresse);
  }

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    telController.dispose();
    adresseController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Service non activé, on peut avertir l'utilisateur
      await AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'Service désactivé',
        desc: 'Veuillez activer la localisation sur votre appareil.',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions refusées
        await AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Permission refusée',
          desc: 'Les permissions de localisation sont refusées.',
          btnOkOnPress: () {},
        ).show();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions refusées définitivement
      await AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'Permission refusée définitivement',
        desc: 'Veuillez autoriser la localisation dans les paramètres.',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    // Obtenir la position actuelle
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final latlng = LatLng(position.latitude, position.longitude);

    // Mettre à jour Riverpod et la map
    ref.read(localisationProvider.notifier).setPosition(latlng);
    mapController.move(latlng, 15);
  }

  @override
  Widget build(BuildContext context) {
    final localisation = ref.watch(localisationProvider);
    final notifier = ref.read(localisationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Éditer Localisation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: localisation.position ?? LatLng(36.8065, 10.1815),
                  initialZoom: 13,
                  onTap: (tapPosition, latlng) {
                    notifier.setPosition(latlng);
                    mapController.move(latlng, 15);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.yourapp.package', // Remplace par ton package
                  ),
                  if (localisation.position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: localisation.position!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (localisation.position != null)
              Text(
                "Lat: ${localisation.position!.latitude.toStringAsFixed(5)}, "
                "Lng: ${localisation.position!.longitude.toStringAsFixed(5)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Utiliser ma position actuelle"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom du garage"),
              onChanged: notifier.setNomGarage,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
              onChanged: notifier.setEmail,
            ),
            TextField(
              controller: telController,
              decoration: const InputDecoration(labelText: "Téléphone"),
              keyboardType: TextInputType.phone,
              onChanged: notifier.setTelephone,
            ),
            TextField(
              controller: adresseController,
              decoration: const InputDecoration(labelText: "Adresse"),
              onChanged: notifier.setAdresse,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.success,
                  animType: AnimType.bottomSlide,
                  title: "Succès",
                  desc: "Votre localisation a été enregistrée",
                  btnOkOnPress: () {
                    Get.back();
                  },
                ).show();
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}
