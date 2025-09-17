import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final usernameProvider = StateProvider<String>((ref) => '');
final garageNameProvider = StateProvider<String>((ref) => '');
final matriculeFiscalProvider = StateProvider<String>((ref) => '');
final emailProvider = StateProvider<String>((ref) => '');
final phoneProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final confirmPasswordProvider = StateProvider<String>((ref) => '');
final governorateIdProvider = StateProvider<String>((ref) => '');
final cityIdProvider = StateProvider<String>((ref) => '');
final governorateNameProvider = StateProvider<String?>((ref) => null);
final cityNameProvider = StateProvider<String?>((ref) => null);
final streetAddressProvider = StateProvider<String?>((ref) => null);
// Permet de suspendre temporairement les alertes/behaviors déclenchés par un listener global d'auth
final suspendAuthAlertsProvider = StateProvider<bool>((ref) => false);

final firstNameControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final lastNameControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final garageNameControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final matriculeFiscalControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final emailControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final phoneControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController(text: '+216');
  ref.onDispose(() => controller.dispose());
  return controller;
});

final passwordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final confirmPasswordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final governorateIdControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final cityIdControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final governorateNameControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final cityNameControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final streetAddressControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});