class Rapport {
  final String id;
  final String orderId;
  final String panne;
  final String pieces;
  final String notes;

  Rapport({
    required this.id,
    required this.orderId,
    required this.panne,
    required this.pieces,
    required this.notes,
  });

  Rapport copyWith({
    String? id,
    String? orderId,
    String? panne,
    String? pieces,
    String? notes,
  }) {
    return Rapport(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      panne: panne ?? this.panne,
      pieces: pieces ?? this.pieces,
      notes: notes ?? this.notes,
    );
  }
}
