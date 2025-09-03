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

String carburantLabel(Carburant carburant) {
  switch (carburant) {
    case Carburant.essence:
      return 'Essence';
    case Carburant.diesel:
      return 'Diesel';
    case Carburant.gpl:
      return 'GPL';
    case Carburant.electrique:
      return 'Électrique';
    case Carburant.hybride:
      return 'Hybride';
    }
}

IconData carburantIcon(Carburant carburant) {
  switch (carburant) {
    case Carburant.essence:
      return Icons.local_gas_station;
    case Carburant.diesel:
      return Icons.oil_barrel;
    case Carburant.gpl:
      return Icons.propane_tank;
    case Carburant.electrique:
      return Icons.electric_bolt;
    case Carburant.hybride:
      return Icons.electric_car;
    }
}
