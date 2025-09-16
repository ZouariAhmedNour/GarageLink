// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:garagelink/models/user.dart';
import 'package:garagelink/services/user_api.dart';

// Keys pour le stockage sécurisé
const _kStorageTokenKey = 'GARAGELINK_TOKEN';
const _kStorageUserKey = 'GARAGELINK_USER';

final _secureStorage = const FlutterSecureStorage();

// Etat simple contenant token + user
class AuthState {
  final String? token;
  final User? user;
  final bool loading;

  AuthState({this.token, this.user, this.loading = false});

  AuthState copyWith({String? token, User? user, bool? loading}) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      loading: loading ?? this.loading,
    );
  }
}

// StateNotifier qui gère l'auth
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(): super(AuthState());

  String? get token => state.token;
  User? get user => state.user;
  bool get isLoggedIn => state.token != null && state.token!.isNotEmpty;

  /// Charger token + user depuis le secure storage (à appeler au démarrage)
  Future<void> loadFromStorage() async {
    try {
      state = state.copyWith(loading: true);
      final savedToken = await _secureStorage.read(key: _kStorageTokenKey);
      final savedUserJson = await _secureStorage.read(key: _kStorageUserKey);

      User? u;
      if (savedUserJson != null) {
        final Map<String, dynamic> data = jsonDecode(savedUserJson);
        u = User.fromJson(data);
      }

      state = state.copyWith(token: savedToken, user: u, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  /// Enregistrer token + (optionnel) user en mémoire + storage
  Future<void> setToken(String newToken, {User? userToSave}) async {
    state = state.copyWith(token: newToken, user: userToSave);
    await _secureStorage.write(key: _kStorageTokenKey, value: newToken);
    if (userToSave != null) {
      await _secureStorage.write(key: _kStorageUserKey, value: jsonEncode(userToSave.toJson()));
    }
  }

  /// Mettre à jour seulement l'objet User (après récupération profile)
  Future<void> setUser(User u) async {
    state = state.copyWith(user: u);
    await _secureStorage.write(key: _kStorageUserKey, value: jsonEncode(u.toJson()));
  }

  /// Supprimer token + user (logout)
  Future<void> clear() async {
    state = AuthState();
    await _secureStorage.delete(key: _kStorageTokenKey);
    await _secureStorage.delete(key: _kStorageUserKey);
  }

  /// Helper : login en appelant ton UserApi, persiste token et récupère le profil
  /// Usage : await ref.read(authNotifierProvider.notifier).login(email, password);
  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true);
    try {
      final token = await UserApi.login(email: email, password: password);
      // stocke token provisoirement
      await _secureStorage.write(key: _kStorageTokenKey, value: token);
      // récupère le profile
      final profile = await UserApi.getProfile(token);
      // update state + persist user
      await _secureStorage.write(key: _kStorageUserKey, value: jsonEncode(profile.toJson()));
      state = AuthState(token: token, user: profile, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }
}

// Provider principal : StateNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// Provider simple pour compatibilité avec ton code existant
// (tu peux continuer à utiliser `ref.read(authTokenProvider)` dans tes autres providers)
final authTokenProvider = Provider<String?>((ref) {
  final st = ref.watch(authNotifierProvider);
  return st.token;
});

// Provider pour l'utilisateur courant
final currentUserProvider = Provider<User?>((ref) {
  final st = ref.watch(authNotifierProvider);
  return st.user;
});
