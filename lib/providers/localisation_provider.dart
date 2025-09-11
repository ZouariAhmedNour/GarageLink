// lib/providers/localisation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Modèle Localisation étendu (utilisé par le provider)
class Localisation {
  final String nomGarage;
  final String email;
  final String telephone;
  final String adresse;
  final LatLng? position;

  // Champs supplémentaires pour completion du profil
  final String matriculefiscal;
  final String? governorateId;
  final String? governorateName;
  final String? cityId;
  final String? cityName;

  Localisation({
    this.nomGarage = '',
    this.email = '',
    this.telephone = '',
    this.adresse = '',
    this.position,
    this.matriculefiscal = '',
    this.governorateId,
    this.governorateName,
    this.cityId,
    this.cityName,
  });

  Localisation copyWith({
    String? nomGarage,
    String? email,
    String? telephone,
    String? adresse,
    LatLng? position,
    String? matriculefiscal,
    String? governorateId,
    String? governorateName,
    String? cityId,
    String? cityName,
  }) {
    return Localisation(
      nomGarage: nomGarage ?? this.nomGarage,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      position: position ?? this.position,
      matriculefiscal: matriculefiscal ?? this.matriculefiscal,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
    );
  }

  /// Convertit l'état en payload conforme à ton backend (completeProfile / signup)
  Map<String, dynamic> toPayload() {
    final Map<String, dynamic> p = {
      'username': nomGarage,
      'email': email,
      'phone': telephone,
      'streetAddress': adresse,
      'matriculefiscal': matriculefiscal,
      // governorate/city uniquement si définis
      if (governorateId != null) 'governorateId': governorateId,
      if (governorateName != null) 'governorateName': governorateName,
      if (cityId != null) 'cityId': cityId,
      if (cityName != null) 'cityName': cityName,
      if (position != null)
        'location': {
          'type': 'Point',
          'coordinates': [position!.longitude, position!.latitude],
        },
    };
    return p;
  }
}

/// StateNotifier qui expose des setters pratiques
class LocalisationNotifier extends StateNotifier<Localisation> {
  LocalisationNotifier() : super(Localisation());

  void setNomGarage(String v) => state = state.copyWith(nomGarage: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setTelephone(String v) => state = state.copyWith(telephone: v);
  void setAdresse(String v) => state = state.copyWith(adresse: v);
  void setPosition(LatLng v) => state = state.copyWith(position: v);
  void setMatriculeFiscal(String v) => state = state.copyWith(matriculefiscal: v);

  /// Quand tu sélectionnes un gouvernorat, envoie id + name
  void setGovernorate({required String id, required String name}) {
    state = state.copyWith(
      governorateId: id,
      governorateName: name,
      // reset city when governorate changes
      cityId: null,
      cityName: null,
    );
  }

  /// Quand tu sélectionnes une ville, envoie id + name
  void setCity({required String id, required String name}) {
    state = state.copyWith(cityId: id, cityName: name);
  }

  /// Retourne le payload prêt à envoyer au backend
  Map<String, dynamic> toPayload({String? password, String? garagenom}) {
    final payload = state.toPayload();
    if (password != null && password.isNotEmpty) payload['password'] = password;
    if (garagenom != null) payload['garagenom'] = garagenom;
    return payload;
  }
}

final localisationProvider =
    StateNotifierProvider<LocalisationNotifier, Localisation>(
  (ref) => LocalisationNotifier(),
);
