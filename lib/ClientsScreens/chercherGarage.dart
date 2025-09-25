import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:garagelink/MecanicienScreens/Reservations/creerResa.dart';
import 'package:garagelink/models/service.dart';
import 'package:garagelink/providers/chercher_garage_providers';
import 'package:garagelink/providers/service_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:garagelink/models/user.dart';

class ChercherGarageScreen extends ConsumerStatefulWidget {
  const ChercherGarageScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChercherGarageScreen> createState() => _SearchGarageScreenState();
}

class _SearchGarageScreenState extends ConsumerState<ChercherGarageScreen> {
  LatLng? myLocation;
  final MapController _mapController = MapController();
  bool _mapCentered = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _determinePositionAndCenter(); // recentre la map si possible
      // recharge les garages (le notifier peut déjà charger dans son constructeur)
      ref.read(garagesProvider.notifier).loadAll();
    });
  }

  Future<void> _determinePositionAndCenter() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() => myLocation = LatLng(36.81897, 10.16579)); // Tunis par défaut
        try {
          _mapController.move(myLocation!, 13);
        } catch (_) {}
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() => myLocation = LatLng(36.81897, 10.16579));
          try {
            _mapController.move(myLocation!, 13);
          } catch (_) {}
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => myLocation = LatLng(36.81897, 10.16579));
        try {
          _mapController.move(myLocation!, 13);
        } catch (_) {}
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => myLocation = LatLng(pos.latitude, pos.longitude));

      // recentre via controller (si possible)
      try {
        _mapController.move(myLocation!, 13);
      } catch (_) {}
    } catch (e) {
      debugPrint('gps error: $e');
    }
  }

 

  List<Marker> _buildMarkers(List<User> garages) {
  return garages.map((g) {
    final coords = g.location?.coordinates;
    if (coords == null || coords.length < 2) return null;
    final lng = coords[0];
    final lat = coords[1];

    return Marker(
      width: 40,
      height: 40,
      point: LatLng(lat, lng),
      child: GestureDetector(
        onTap: () {
          if (!mounted) return;

          // Décaler le chargement des services après le build
          Future.microtask(() async {
            await ref.read(serviceProvider.notifier).loadAll();

            // Puis ouvrir le bottom sheet
            if (!mounted) return;
            showModalBottomSheet(
              context: context,
              builder: (_) => _garageDetailsSheet(g),
            );
          });
        },
        child: const Icon(Icons.location_on, size: 36),
      ),
    );
  }).whereType<Marker>().toList();
}

 Widget _garageDetailsSheet(User g) {
  // On lit le provider des services
  final servicesState = ref.watch(serviceProvider);

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Wrap(
      children: [
        // Infos garage
        ListTile(
          title: Text(g.garagenom ?? g.username),
          subtitle: Text(g.streetAddress),
        ),
        if (g.phone != null) ListTile(leading: const Icon(Icons.phone), title: Text(g.phone!)),
        if ((g.email).isNotEmpty) ListTile(leading: const Icon(Icons.email), title: Text(g.email)),
        const SizedBox(height: 8),

        // Services du garage
        const Divider(),
        const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        if (servicesState.loading)
          const Center(child: CircularProgressIndicator())
        else if (servicesState.error != null)
          Text('Erreur: ${servicesState.error}')
        else
          Column(
            children: servicesState.services
                .map((s) => ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.description),
                      trailing: Chip(
                        label: Text(
                          s.statut == ServiceStatut.actif ? 'Actif' : 'Désactivé',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            s.statut == ServiceStatut.actif ? Colors.green : Colors.red,
                      ),
                    ))
                .toList(),
          ),

        const SizedBox(height: 12),

        // Bouton Réserver
        ElevatedButton.icon(
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreerResaScreen(garage: g),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Réserver'),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final garagesAsync = ref.watch(garagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chercher un garage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              if (!mounted) return;
              // Récupère la position + lance la recherche autour de moi
              await _determinePositionAndCenter();
              
            },
            tooltip: 'Rechercher autour de ma position',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!mounted) return;
              ref.read(garagesProvider.notifier).loadAll();
            },
            tooltip: 'Recharger tous les garages',
          ),
        ],
      ),
      body: Column(
        children: [
          // petite info : nombre de garages (utile pour debug/UX) + contrôle du rayon
         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: garagesAsync.when(
    data: (garages) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${garages.length} garages trouvés'),
        if (myLocation != null) const Text('Localisation activée'),
      ],
    ),
    loading: () => const SizedBox.shrink(),
    error: (e, st) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('Erreur: $e'), const SizedBox()],
    ),
  ),
),

          // ----- map -----
          Expanded(
            child: garagesAsync.when(
              data: (garages) {
                if (garages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 48),
                        const SizedBox(height: 8),
                        const Text('Aucun garage trouvé.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.read(garagesProvider.notifier).loadAll(),
                          child: const Text('Recharger'),
                        ),
                      ],
                    ),
                  );
                }

                final markers = _buildMarkers(garages);
                final center = myLocation ?? (markers.isNotEmpty ? markers.first.point : LatLng(36.81897, 10.16579));

                // recentre la carte une seule fois après le build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_mapCentered) {
                    try {
                      _mapController.move(center, 12);
                    } catch (_) {}
                    _mapCentered = true;
                  }
                });

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(onTap: (_, __) => Navigator.of(context).maybePop()),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.garagelink',
                        ),
                        MarkerLayer(markers: [
                          if (myLocation != null)
                            Marker(
                              width: 36,
                              height: 36,
                              point: myLocation!,
                              child: const Icon(Icons.person_pin_circle),
                            ),
                          ...markers,
                        ]),
                      ],
                    ),

                    // attribution
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.white70,
                        child: const Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
