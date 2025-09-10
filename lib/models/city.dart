// lib/models/city.dart
class City {
  final String id;
  final String name;
  final String? nameAr;
  final String? postalCode;
  final List<double>? coordinates; // [lng, lat]
  final String? governorateId;

  City({
    required this.id,
    required this.name,
    this.nameAr,
    this.postalCode,
    this.coordinates,
    this.governorateId,
  });

  factory City.fromMap(Map<String, dynamic> m) => City(
    id: m['_id'] ?? '',
    name: m['name'] ?? '',
    nameAr: m['nameAr'],
    postalCode: m['postalCode'],
    governorateId: m['governorateId'] is Map ? (m['governorateId']['_id'] ?? '') : (m['governorateId']?.toString()),
    coordinates: m['location'] != null && m['location']['coordinates'] != null
        ? List<double>.from(m['location']['coordinates'].map((x) => (x as num).toDouble()))
        : null,
  );
}
