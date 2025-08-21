// facture.dart
class Facture {
  final String id;
  final DateTime date;
  final double montant;
  final String clientName;

  Facture({
    required this.id,
    required this.date,
    required this.montant,
    required this.clientName,
  });
}
