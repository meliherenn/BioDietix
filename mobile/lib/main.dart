import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/storage/hive_local_store.dart';
import 'src/firebase_options.dart';
import 'src/services/app_check_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final localStore = HiveLocalStore();
  await localStore.init();
  final initialLanguage = await localStore.loadLanguage();
  final initialThemeMode = await localStore.loadThemeMode();

  var firebaseReady = false;
  if (BiodietixFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: BiodietixFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } else {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } on Exception catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: ${error.runtimeType}');
      }
      firebaseReady = false;
    }
  }

  await AppCheckService.instance.initialize(
    flavor: config.flavor,
    enabled: AppConfig.appCheckEnabled,
    firebaseReady: firebaseReady,
  );
  if (kDebugMode && firebaseReady && AppConfig.appCheckEnabled) {
    await AppCheckService.instance.runDebugDiagnostic(
      authUserPresent: FirebaseAuth.instance.currentUser != null,
    );
  }

  runApp(
    BioDietixApp(
      config: config,
      firebaseReady: firebaseReady,
      localStore: localStore,
      initialLanguage: initialLanguage,
      initialThemeMode: initialThemeMode,
    ),
  );
}
