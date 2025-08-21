// intervention.dart
class Intervention {
  final String id;
  final DateTime date;
  final String clientName;
  final String type; // ex: "Révision", "Freins", ...
  final int dureeMinutes; // durée en minutes
  final double prix; // prix facturé (optionnel)

  Intervention({
    required this.id,
    required this.date,
    required this.clientName,
    required this.type,
    required this.dureeMinutes,
    required this.prix,
  });
}
