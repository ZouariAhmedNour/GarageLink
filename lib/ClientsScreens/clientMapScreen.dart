// lib/screens/client_map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

class ClientMapScreen extends ConsumerStatefulWidget {
  const ClientMapScreen({super.key});

  @override
  ConsumerState<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends ConsumerState<ClientMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _current;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationFlow();
    });
  }

  Future<void> _initLocationFlow() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = 'Service de localisation désactivé. Veuillez activer le GPS.');
        _showEnableLocationDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => _error = 'Permission de localisation refusée.');
        _showPermissionDeniedDialog();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Permission refusée définitivement. Ouvrez les paramètres de l\'application.');
        _showPermissionDeniedDialog();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _updatePosition(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() => _error = 'Erreur localisation: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updatePosition(double lat, double lng) {
    setState(() {
      _current = LatLng(lat, lng);
    });
    // Déplacer la carte après build
    Future.microtask(() {
      if (_current != null) _mapController.move(_current!, 15.0);
    });
  }

  Future<void> _recenter() async {
    setState(() => _loading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _updatePosition(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() => _error = 'Impossible de récupérer la position: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission refusée'),
        content: const Text('La permission de localisation est nécessaire pour centrer la carte. Voulez-vous ouvrir les paramètres ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Ouvrir paramètres'),
          ),
        ],
      ),
    );
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activer le GPS'),
        content: const Text('Le GPS est désactivé. Veux-tu ouvrir les paramètres de localisation du device ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('Ouvrir paramètres'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = LatLng(36.8065, 10.1815); // fallback (Tunis)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma localisation'),
        backgroundColor: const Color(0xFF357ABD),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Get.defaultDialog(
                title: 'Info',
                middleText: 'Active le GPS et autorise la localisation pour centrer la carte sur ta position.',
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // v8 utilise initialCenter / initialZoom
              initialCenter: _current ?? defaultCenter,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.garagelink',
              ),
              if (_current != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _current!,
                      width: 80,
                      height: 80,
                      // v8: Marker uses 'child' (widget) au lieu de 'builder'
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.my_location, color: Color(0xFF357ABD)),
                          ),
                          const SizedBox(height: 4),
                          const Text('Vous', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (_loading)
            const Positioned(
              top: 16,
              left: 16,
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Localisation en cours...'),
                ),
              ),
            ),

          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.black87))),
                      TextButton(
                        onPressed: () {
                          setState(() => _error = null);
                          _initLocationFlow();
                        },
                        child: const Text('Réessayer'),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'recenter',
            onPressed: _recenter,
            backgroundColor: const Color(0xFF357ABD),
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'save',
            onPressed: () {
              if (_current == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Position non disponible')));
                return;
              }
              Get.back(result: {'lat': _current!.latitude, 'lng': _current!.longitude});
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}
