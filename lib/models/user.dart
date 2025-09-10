import 'dart:convert';

class UserModel {
  final String id;
  final String username;
  final String garagenom;
  final String matriculefiscal;
  final String email;
  final String phone;
  final String streetAddress;
  final bool isVerified;
  final Map<String, dynamic>? location; // { "type": "Point", "coordinates": [lng, lat] }
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.garagenom,
    required this.matriculefiscal,
    required this.email,
    required this.phone,
    required this.streetAddress,
    this.isVerified = false,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['_id'] ?? m['id'] ?? '',
        username: m['username'] ?? '',
        garagenom: m['garagenom'] ?? '',
        matriculefiscal: m['matriculefiscal'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        streetAddress: m['streetAddress'] ?? '',
        isVerified: m['isVerified'] ?? false,
        location: m['location'] != null ? Map<String, dynamic>.from(m['location']) : null,
        createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt']) : null,
        updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : null,
      );

  Map<String, dynamic> toMap() => {
        'username': username,
        'garagenom': garagenom,
        'matriculefiscal': matriculefiscal,
        'email': email,
        'phone': phone,
        'streetAddress': streetAddress,
        'location': location,
      };

  String toJson() => json.encode(toMap());
  factory UserModel.fromJson(String src) => UserModel.fromMap(json.decode(src));
}
