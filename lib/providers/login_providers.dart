import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final loginEmailProvider = StateProvider<String>((ref) => '');
final loginPasswordProvider = StateProvider<String>((ref) => '');
final resetTokenProvider = StateProvider<String>((ref) => '');
final newPasswordProvider = StateProvider<String>((ref) => '');
final confirmNewPasswordProvider = StateProvider<String>((ref) => '');

final loginEmailControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final loginPasswordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final resetTokenControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final newPasswordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final confirmNewPasswordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});