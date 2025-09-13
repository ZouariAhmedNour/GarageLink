class PieceRechange {
  final String? id;
  final String name;
  final double prix;

  PieceRechange({
    this.id,
    required this.name,
    required this.prix,
  });

  factory PieceRechange.fromJson(Map<String, dynamic> json) {
    return PieceRechange(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      prix: _toDouble(json['prix'] ?? json['price'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'prix': prix,
    };
  }

  PieceRechange copyWith({
    String? id,
    String? name,
    double? prix,
  }) {
    return PieceRechange(
      id: id ?? this.id,
      name: name ?? this.name,
      prix: prix ?? this.prix,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}