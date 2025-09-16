// piece.dart

class Piece {
  final String? id; // _id from MongoDB
  final String name;
  final double prix;

  Piece({
    this.id,
    required this.name,
    required this.prix,
  });

  // Parse JSON to Piece object
  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      id: json['_id']?.toString(),
      name: json['name'] ?? '',
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convert Piece object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'prix': prix,
    }..removeWhere((key, value) => value == null); // Remove null values
  }
}