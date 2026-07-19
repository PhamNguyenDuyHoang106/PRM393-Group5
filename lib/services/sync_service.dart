import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../models/pending_action.dart';
import '../models/user.dart';
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
      final dio = DioClient.instance.dio;

      switch (action.actionType) {
        case 'CREATE_PROJECT':
          if (kDebugMode) {
            print('[SyncService] Syncing: Create project ${data["name"]}');
          }
          await dio.post(
            '/projects',
            data: {
              'id': data['id'],
              'name': data['name'],
              'description': data['description'],
            },
          );
          return true;

        case 'CREATE_TASK':
          if (kDebugMode) {
            print('[SyncService] Syncing: Create task ${data["title"]}');
          }
          await dio.post(
            '/projects/${data["projectId"]}/tasks',
            data: {
              'id': data['id'],
              'title': data['title'],
              'description': data['description'],
              'priority': data['priority'],
              'assignedTo': data['assignedTo'],
              'dueDate': data['dueDate'],
            },
          );
          return true;

        case 'UPDATE_PROJECT':
          await dio.put(
            '/projects/${data["id"]}',
            data: {'name': data['name'], 'description': data['description']},
          );
          return true;

        case 'DELETE_PROJECT':
          await dio.delete('/projects/${data["project_id"]}');
          return true;

        case 'UPDATE_TASK':
          if (kDebugMode) {
            print('[SyncService] Syncing: Update task ${data["id"]}');
          }
          String? uid;
          try {
            if (Firebase.apps.isNotEmpty) {
              uid = fb.FirebaseAuth.instance.currentUser?.uid;
            }
          } catch (_) {}

          User? caller;
          if (uid != null) {
            caller = await _dbHelper.getCachedUser(uid);
          }
          final isManager = caller?.isManager ?? true;

          if (isManager) {
            await dio.put(
              '/tasks/${data["id"]}',
              data: {
                'title': data['title'],
                'description': data['description'],
                'priority': data['priority'],
                'status': data['status'],
                'assignedTo': data['assignedTo'],
                'dueDate': data['dueDate'],
              },
            );
          } else {
            await dio.patch(
              '/tasks/${data["id"]}/status',
              data: {'status': data['status']},
            );
          }
          return true;

        case 'DELETE_TASK':
          if (kDebugMode) {
            print('[SyncService] Syncing: Delete task ${data["task_id"]}');
          }
          await dio.delete('/tasks/${data["task_id"]}');
          return true;

        case 'ADD_PROJECT_MEMBER':
          if (kDebugMode) {
            print(
              '[SyncService] Syncing: Add member ${data["email"]} '
              'to project ${data["project_id"]}',
            );
          }
          await dio.post(
            '/projects/${data["project_id"]}/members',
            data: {'email': data['email']},
          );
          return true;

        case 'REMOVE_PROJECT_MEMBER':
          if (kDebugMode) {
            print(
              '[SyncService] Syncing: Remove member ${data["user_id"]} '
              'from project ${data["project_id"]}',
            );
          }
          await dio.delete(
            '/projects/${data["project_id"]}/members/${data["user_id"]}',
          );
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
