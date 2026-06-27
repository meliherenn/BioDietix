import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/storage/hive_local_store.dart';
import 'src/firebase_options.dart';

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
    } on Exception {
      firebaseReady = false;
    }
  }

  if (firebaseReady && AppConfig.appCheckEnabled) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: config.flavor == AppFlavor.prod
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: config.flavor == AppFlavor.prod
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider(),
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
