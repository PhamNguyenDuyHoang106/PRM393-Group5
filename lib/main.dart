import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize Firebase with platform-specific options from firebase_options.dart.
  // ⚠️  BEFORE RUNNING: replace all YOUR_... placeholders in lib/firebase_options.dart
  //     and android/app/google-services.json with real values from Firebase Console.
  //     See the comments inside those files for instructions.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not yet configured (placeholders still in place) —
    // app will run in offline/mock mode until real values are filled in.
    debugPrint('[Firebase] Skipping init: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
