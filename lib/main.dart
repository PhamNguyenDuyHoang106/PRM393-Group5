import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/init/app_initializer.dart';

void main() async {
  await AppInitializer.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
