// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garagelink/configurations/app_routes.dart';
import 'package:garagelink/configurations/generate_routes.dart';
import 'package:get/get.dart';
import 'package:garagelink/firebase_options.dart';

// IMPORTS POUR LES PROVIDERS
import 'package:garagelink/providers/auth_provider.dart';
import 'package:garagelink/providers/mecaniciens_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // 1) Charger token + user depuis le secure storage au démarrage,
    // puis, si on a un token, précharger les mécaniciens.
    Future.microtask(() async {
      try {
        await ref.read(authNotifierProvider.notifier).loadFromStorage();
        final token = ref.read(authTokenProvider);
        debugPrint('🔐 Token chargé au démarrage: $token');

        if (token != null && token.isNotEmpty) {
          // Précharger la liste des mécaniciens (optionnel mais pratique)
          await ref.read(mecaniciensProvider.notifier).loadAll();
          debugPrint('🔁 Liste des mécaniciens préchargée');
        }
      } catch (e) {
        debugPrint('⚠️ Erreur lors de l\'initialisation auth: $e');
      }
    });

    // 2) Navigation basée sur l'état Firebase Auth (ta logique existante)
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Get.offAllNamed(AppRoutes.login);
      } else if (user.emailVerified) {
        Get.offAllNamed(AppRoutes.mecaHome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GarageLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Colors.black,
            size: 30,
          ),
        ),
      ),
      getPages: GenerateRoutes.getPages,
      initialRoute: AppRoutes.splashScreen, // nouvelle route par défaut

      // 🔹 Ajout pour le DatePicker
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'), // pour que le DatePicker soit en français
    );
  }
}
