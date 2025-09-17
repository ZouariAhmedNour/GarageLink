import 'package:flutter/material.dart';
import 'package:garagelink/models/vehicule.dart';

const Color primaryBlue = Color(0xFF357ABD);
const Color lightBlue = Color(0xFFE3F2FD);
const Color darkBlue = Color(0xFF1976D2);
const Color errorRed = Color(0xFFD32F2F);
const Color successGreen = Color(0xFF388E3C);
const Color surfaceColor = Color(0xFFF8F9FA);
const Color accentOrange = Color(0xFFFF9800);

String formatDate(DateTime? d) {
  if (d == null) return '-';
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd/$mm/$yyyy';
}

String fuelTypeLabel(FuelType fuelType) {
  switch (fuelType) {
    case FuelType.essence:
      return 'Essence';
    case FuelType.diesel:
      return 'Diesel';
    case FuelType.gpl:
      return 'GPL';
    case FuelType.electrique:
      return 'Électrique';
    case FuelType.hybride:
      return 'Hybride';
  }
}

IconData fuelTypeIcon(FuelType fuelType) {
  switch (fuelType) {
    case FuelType.essence:
      return Icons.local_gas_station;
    case FuelType.diesel:
      return Icons.oil_barrel;
    case FuelType.gpl:
      return Icons.propane_tank;
    case FuelType.electrique:
      return Icons.electric_bolt;
    case FuelType.hybride:
      return Icons.electric_car;
  }
}
