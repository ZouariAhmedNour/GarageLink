import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final loginEmailProvider = StateProvider<String>((ref) => '');
final loginPasswordProvider = StateProvider<String>((ref) => '');

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
final numberControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController(text: '+216');
  ref.onDispose(() => controller.dispose());
  return controller;
});

final otpControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});