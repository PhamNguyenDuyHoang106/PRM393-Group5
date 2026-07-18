import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/database/db_helper.dart';
import '../models/pending_action.dart';
import 'connectivity_service.dart';

class SyncService {
  final ConnectivityService _connectivityService;
  final DbHelper _dbHelper = DbHelper.instance;
  bool _isSyncing = false;

  SyncService(this._connectivityService) {
    // Listen to connection changes and trigger sync automatically when going online
    _connectivityService.connectionStream.listen((isOnline) {
      if (isOnline) {
        if (kDebugMode) {
          print(
            '[SyncService] Device is online. Starting pending synchronization queue...',
          );
        }
        triggerSync();
      }
    });
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    if (!_connectivityService.isOnline) return;

    _isSyncing = true;

    try {
      final List<PendingAction> actions = await _dbHelper.getPendingActions();
      if (actions.isEmpty) {
        if (kDebugMode) print('[SyncService] Sync queue is empty.');
        _isSyncing = false;
        return;
      }

      if (kDebugMode) {
        print(
          '[SyncService] Found ${actions.length} pending offline actions to sync.',
        );
      }

      for (var action in actions) {
        final success = await _processAction(action);
        if (success) {
          await _dbHelper.dequeueAction(action.id);
          if (kDebugMode) {
            print(
              '[SyncService] Synchronized action ${action.id} (${action.actionType}) successfully. Dequeued.',
            );
          }
        } else {
          // If a request fails, we stop the sync sequence to maintain order
          if (kDebugMode) {
            print(
              '[SyncService] Failed to sync action ${action.id}. Pausing synchronization.',
            );
          }
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) print('[SyncService] Error during sync run: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processAction(PendingAction action) async {
    // Deserialize payload
    final Map<String, dynamic> data = jsonDecode(action.payload);

    try {
      // In actual implementation, this calls DioClient and posts to Spring Boot REST backend
      // e.g. DioClient.instance.post(url, data: data)
      switch (action.actionType) {
        case 'CREATE_TASK':
          if (kDebugMode) {
            print(
              '[SyncService] REST Mock Post: Creating task: ${data["title"]}',
            );
          }
          // Mock Network delay
          await Future.delayed(const Duration(seconds: 1));
          return true;

        case 'UPDATE_TASK':
          if (kDebugMode) {
            print('[SyncService] REST Mock Put: Updating task: ${data["id"]}');
          }
          await Future.delayed(const Duration(seconds: 1));
          return true;

        case 'CREATE_PROJECT':
          if (kDebugMode) {
            print(
              '[SyncService] REST Mock Post: Creating project: ${data["name"]}',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          return true;

        case 'ADD_PROJECT_MEMBER':
          if (kDebugMode) {
            print(
              '[SyncService] REST Mock Post: Adding ${data["user_email"]} '
              'to project ${data["project_id"]}',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          return true;

        case 'REMOVE_PROJECT_MEMBER':
          if (kDebugMode) {
            print(
              '[SyncService] REST Mock Delete: Removing ${data["user_id"]} '
              'from project ${data["project_id"]}',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          return true;

        default:
          if (kDebugMode) {
            print('[SyncService] Unknown action type: ${action.actionType}');
          }
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SyncService] API Error processing action ${action.id}: $e');
      }
      return false;
    }
  }
}
