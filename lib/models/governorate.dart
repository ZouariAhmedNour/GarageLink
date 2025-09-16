// governorate.dart

class Governorate {
  final String? id; // _id from MongoDB
  final String? name;
  final String? nameAr; // Name in Arabic

  Governorate({
    this.id,
    this.name,
    this.nameAr,
  });

  // Parse JSON to Governorate object
  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['_id']?.toString(),
      name: json['name'],
      nameAr: json['nameAr'],
    );
  }

  // Convert Governorate object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'nameAr': nameAr,
    }..removeWhere((key, value) => value == null); // Remove null values
  }
}