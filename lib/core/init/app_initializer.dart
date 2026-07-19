import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../../firebase_options.dart';
import '../database/db_helper.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize DB factories
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    // 2. Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('[Firebase] Skipping init: $e');
    }

    // 3. Pre-seed local SQLite manager account if not exists
    try {
      final dbHelper = DbHelper.instance;
      // Triggers opening database
      await dbHelper.database;
      
      final existingManager = await dbHelper.getUserByEmail('manager@gmail.com');
      if (existingManager == null) {
        final db = await dbHelper.database;
        await db.insert('users', {
          'id': 'usr_manager_seed',
          'name': 'Manager',
          'email': 'manager@gmail.com',
          'role': 'manager',
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('[AppInitializer] Predefined manager profile seeded in SQLite.');
      } else {
        debugPrint('[AppInitializer] Predefined manager profile already exists in SQLite.');
      }
    } catch (e) {
      debugPrint('[AppInitializer] Database seeding failed: $e');
    }
  }
}
