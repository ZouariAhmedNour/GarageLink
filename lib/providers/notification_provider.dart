// providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compteur simple de notifications non lues / évènements récents.
/// Valeur = nombre d'évènements non vus. 0 = rien à afficher.
final newNotificationProvider = StateProvider<int>((ref) => 0);
