// lib/models/governorate.dart
class Governorate {
  final String id;
  final String name;
  final String? nameAr;
  Governorate({required this.id, required this.name, this.nameAr});
  factory Governorate.fromMap(Map<String, dynamic> m) => Governorate(
    id: m['_id'] ?? '',
    name: m['name'] ?? '',
    nameAr: m['nameAr'],
  );
}
