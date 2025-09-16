// street.dart

class Street {
  final String? id; // _id from MongoDB
  final String? name;
  final String? cityId; // Reference to City

  Street({
    this.id,
    this.name,
    this.cityId,
  });

  // Parse JSON to Street object
  factory Street.fromJson(Map<String, dynamic> json) {
    return Street(
      id: json['_id']?.toString(),
      name: json['name'],
      cityId: json['cityId']?.toString(),
    );
  }

  // Convert Street object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'cityId': cityId,
    }..removeWhere((key, value) => value == null); // Remove null values
  }
}