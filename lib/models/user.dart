// user.dart
class User {
  final String? id; // _id from MongoDB
  final String username;
  final String? garagenom; // Nullable si googleId est présent
  final String? matriculefiscal; // Nullable si googleId est présent
  final String email;
  final String? password; // Nullable si googleId est présent
  final String? phone; // Nullable si googleId est présent
  final bool isVerified;
  final String? googleId; // Nullable
  final String? resetPasswordToken; // Nullable
  final DateTime? resetPasswordExpires; // Nullable
  final String? governorateId; // ObjectId as String, nullable
  final String governorateName;
  final String? cityId; // ObjectId as String, nullable
  final String cityName;
  final String streetAddress;
  final Location? location; // Nullable GeoJSON object
  final DateTime? createdAt; // From timestamps
  final DateTime? updatedAt; // From timestamps

  User({
    this.id,
    required this.username,
    this.garagenom,
    this.matriculefiscal,
    required this.email,
    this.password,
    this.phone,
    this.isVerified = false,
    this.googleId,
    this.resetPasswordToken,
    this.resetPasswordExpires,
    this.governorateId,
    this.governorateName = '',
    this.cityId,
    this.cityName = '',
    this.streetAddress = '',
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  // Parse JSON to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      username: json['username'] ?? '',
      garagenom: json['garagenom'],
      matriculefiscal: json['matriculefiscal'],
      email: json['email'] ?? '',
      password: json['password'],
      phone: json['phone'],
      isVerified: json['isVerified'] ?? false,
      googleId: json['googleId'],
      resetPasswordToken: json['resetPasswordToken'],
      resetPasswordExpires: json['resetPasswordExpires'] != null
          ? DateTime.parse(json['resetPasswordExpires'])
          : null,
      governorateId: json['governorateId']?.toString(),
      governorateName: json['governorateName'] ?? '',
      cityId: json['cityId']?.toString(),
      cityName: json['cityName'] ?? '',
      streetAddress: json['streetAddress'] ?? '',
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'garagenom': garagenom,
      'matriculefiscal': matriculefiscal,
      'email': email,
      'password': password,
      'phone': phone,
      'isVerified': isVerified,
      'googleId': googleId,
      'resetPasswordToken': resetPasswordToken,
      'resetPasswordExpires': resetPasswordExpires?.toIso8601String(),
      'governorateId': governorateId,
      'governorateName': governorateName,
      'cityId': cityId,
      'cityName': cityName,
      'streetAddress': streetAddress,
      'location': location?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null); 
  }
}

// Class for GeoJSON Location
class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
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