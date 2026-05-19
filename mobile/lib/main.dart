import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(BioDietixApp(firebaseReady: firebaseReady));
}
