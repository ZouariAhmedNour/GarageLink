// city.dart

class City {
  final String? id; // _id from MongoDB
  final String? name;
  final String? nameAr; // Name in Arabic
  final String? governorateId; // Reference to Governorate
  final String? postalCode;
  final Location? location; // GeoJSON object

  City({
    this.id,
    this.name,
    this.nameAr,
    this.governorateId,
    this.postalCode,
    this.location,
  });

  // Parse JSON to City object
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['_id']?.toString(),
      name: json['name'],
      nameAr: json['nameAr'],
      governorateId: json['governorateId']?.toString(),
      postalCode: json['postalCode'],
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
    );
  }

  // Convert City object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'nameAr': nameAr,
      'governorateId': governorateId,
      'postalCode': postalCode,
      'location': location?.toJson(),
    }..removeWhere((key, value) => value == null); // Remove null values
  }
}

// Class for GeoJSON Location
class Location {
  final String type;
  final List<double> coordinates;

  Location({
    this.type = 'Point',
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>?)?.cast<double>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}