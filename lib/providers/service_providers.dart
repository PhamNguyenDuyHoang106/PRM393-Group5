import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncService(connectivity);
});
