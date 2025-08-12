import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';


// Modèle de localisation
class Localisation {
  String nomGarage;
  String email;
  String telephone;
  String adresse;
  LatLng? position;

  Localisation({
    this.nomGarage = '',
    this.email = '',
    this.telephone = '',
    this.adresse = '',
    this.position,
  });
}

// Provider pour gérer l'état
class LocalisationNotifier extends StateNotifier<Localisation> {
  LocalisationNotifier() : super(Localisation());

  void setNomGarage(String value) {
    state = Localisation(
      nomGarage: value,
      email: state.email,
      telephone: state.telephone,
      adresse: state.adresse,
      position: state.position,
    );
  }

  void setEmail(String value) {
    state = Localisation(
      nomGarage: state.nomGarage,
      email: value,
      telephone: state.telephone,
      adresse: state.adresse,
      position: state.position,
    );
  }

  void setTelephone(String value) {
    state = Localisation(
      nomGarage: state.nomGarage,
      email: state.email,
      telephone: value,
      adresse: state.adresse,
      position: state.position,
    );
  }

  void setAdresse(String value) {
    state = Localisation(
      nomGarage: state.nomGarage,
      email: state.email,
      telephone: state.telephone,
      adresse: value,
      position: state.position,
    );
  }

  void setPosition(LatLng value) {
    state = Localisation(
      nomGarage: state.nomGarage,
      email: state.email,
      telephone: state.telephone,
      adresse: state.adresse,
      position: value,
    );
  }
}

// Déclaration du provider
final localisationProvider =
    StateNotifierProvider<LocalisationNotifier, Localisation>(
  (ref) => LocalisationNotifier(),
);
