// lib/models/street.dart
class Street {
  final String id;
  final String name;
  final String? cityId;
  Street({required this.id, required this.name, this.cityId});
  factory Street.fromMap(Map<String, dynamic> m) => Street(
    id: m['_id'] ?? '',
    name: m['name'] ?? '',
    cityId: m['cityId']?.toString(),
  );
}
