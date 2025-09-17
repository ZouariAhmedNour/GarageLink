import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garagelink/models/vehicule.dart';
import 'ui_constants.dart';

class VehicleHeader extends StatelessWidget {
  final Vehicule veh;
  final VoidCallback? onTapImage;

  const VehicleHeader({required this.veh, this.onTapImage, Key? key}) : super(key: key);

  // Petite fonction locale pour choisir une icône selon le type de carburant
  IconData _fuelIcon(FuelType type) {
    switch (type) {
      case FuelType.diesel:
        return Icons.local_gas_station;
      case FuelType.hybride:
        return Icons.electric_car; // hybride -> électrique-like icon
      case FuelType.electrique:
        return Icons.electric_car;
      case FuelType.gpl:
        return Icons.local_gas_station;
      case FuelType.essence:
      return Icons.local_gas_station;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 234, 236, 238),
            darkBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: onTapImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: veh.picKm != null && veh.picKm!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: veh.picKm!.startsWith('http')
                            ? Image.network(veh.picKm!, fit: BoxFit.cover)
                            : Image.file(File(veh.picKm!), fit: BoxFit.cover),
                      )
                    : Icon(Icons.directions_car, size: 50, color: primaryBlue),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${veh.marque} ${veh.modele}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      veh.immatriculation,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_fuelIcon(veh.typeCarburant), color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        // utilise la fonction existante fuelTypeLabel pour le libellé
                        fuelTypeLabel(veh.typeCarburant),
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
