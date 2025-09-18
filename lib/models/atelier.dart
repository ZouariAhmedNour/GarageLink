// atelier.dart

class Atelier {
  final String? id;
  final String name;
  final String localisation;

  Atelier({
    this.id,
    required this.name,
    required this.localisation,
  });

  // Parse JSON to Atelier object
  factory Atelier.fromJson(Map<String, dynamic> json) {
    return Atelier(
      id: json['_id']?.toString(),
      name: json['name'] ?? '',
      localisation: json['localisation'] ?? '',
    );
  }

  // Convert Atelier object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'localisation': localisation,
    }..removeWhere((key, value) => value == null); // Remove null values
  }
}