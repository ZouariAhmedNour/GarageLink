class Facture {
  final String id;
  final DateTime date;
  final double montant;
  final String clientName;
  final String? clientEmail;
  final String? devisId;
  final String? immatriculation; // <-- ajouté
  final bool? isPaid;
  final String? notes;

  Facture({
    required this.id,
    required this.date,
    required this.montant,
    required this.clientName,
    this.clientEmail,
    this.devisId,
    this.immatriculation,
    this.isPaid,
    this.notes,
  });

  Facture copyWith({
    String? id,
    DateTime? date,
    double? montant,
    String? clientName,
    String? clientEmail,
    String? devisId,
    String? immatriculation,
    bool? isPaid,
    String? notes,
  }) {
    return Facture(
      id: id ?? this.id,
      date: date ?? this.date,
      montant: montant ?? this.montant,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      devisId: devisId ?? this.devisId,
      immatriculation: immatriculation ?? this.immatriculation,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
    );
  }
}
