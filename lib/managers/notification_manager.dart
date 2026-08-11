import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'user_manager.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  List<Map<String, String>> _notifications = [];
  Set<String> _deletedIds = {};
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  List<Map<String, String>> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['isRead'] == 'false').length;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;

  Future<void> init() async {
    await loadDeletedIds();
    await loadNotifications();
    fetchFromApi(isInitial: true); // Fetch from API in background
  }

  Future<void> fetchFromApi({bool isInitial = true}) async {
    final token = UserManager().token;
    if (token == null) return;

    if (isInitial) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    } else {
      _isFetchingMore = true;
    }
    notifyListeners();

    try {
      final result = await ApiService.getNotifications(token, page: isInitial ? 1 : _currentPage + 1);
      debugPrint('DEBUG: Fetch Notifications API Response -> $result');
      
      if (result['success'] && result['data'] != null) {
        final List<dynamic> apiData = result['data'];
        final List<Map<String, String>> apiNotifications = apiData
            .where((item) {
              final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
              return !_deletedIds.contains(id); // Filter out deleted notifications
            })
            .map((item) {
          final String id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
          return {
            'id': id,
            'title': item['title']?.toString() ?? '',
            'message': item['message']?.toString() ?? '',
            'time': item['createdAt']?.toString() ?? 'Recent',
            'icon': item['icon']?.toString() ?? '🔔',
            'isRead': (item['isRead'] ?? false).toString(),
            'type': item['type']?.toString() ?? 'general',
          };
        }).toList();

        if (isInitial) {
          _notifications = apiNotifications;
          _currentPage = 1;
        } else {
          _notifications.addAll(apiNotifications);
          _currentPage++;
        }
        
        _hasMore = apiData.length >= 20; // Assuming limit is 20
        await saveNotifications();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String icon,
    String? type,
  }) async {
    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'time': 'Just now',
      'icon': icon,
      'isRead': 'false',
      'type': type ?? 'general',
    };

    _notifications.insert(0, newNotification);
    notifyListeners();
    await saveNotifications();
  }

  void markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = 'true';
      notifyListeners();
      await saveNotifications();

      // Call API to mark as read on backend
      final token = UserManager().token;
      if (token != null) {
        try {
          await ApiService.markNotificationRead(id, token);
        } catch (e) {
          debugPrint('Error marking notification as read on API: $e');
        }
      }
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n['isRead'] = 'true';
    }
    notifyListeners();
    saveNotifications();
  }

  void clearAll() async {
    // Record all current IDs as deleted to prevent them from coming back from API
    for (var n in _notifications) {
      if (n['id'] != null) _deletedIds.add(n['id']!);
    }
    await saveDeletedIds();

    _notifications.clear();
    notifyListeners();
    await saveNotifications();

    // Call API to clear all on backend
    final token = UserManager().token;
    if (token != null) {
      try {
        await ApiService.clearAllNotifications(token);
      } catch (e) {
        debugPrint('Error clearing all notifications from API: $e');
      }
    }
  }

  Future<void> removeNotification(String id) async {
    if (id.isEmpty) return;
    
    // Add to deleted tracking to prevent reappearance from API
    _deletedIds.add(id);
    await saveDeletedIds();

    // Backup for rollback
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index == -1) return;
    final backup = _notifications[index];

    // 1. Optimistic UI update
    _notifications.removeAt(index);
    notifyListeners();

    final token = UserManager().token;
    if (token != null) {
      try {
        debugPrint('DEBUG: Attempting to delete notification with ID: $id');
        final result = await ApiService.deleteNotification(id, token);
        
        if (result['success'] == true) {
          debugPrint('DEBUG: Server deletion successful for ID: $id');
          await saveNotifications();
        } else {
          // 2. Rollback if server failed
          debugPrint('DEBUG: Server deletion failed, rolling back UI. Error: ${result['message']}');
          if (!_notifications.any((n) => n['id'] == id)) {
            _notifications.insert(index, backup);
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('DEBUG: Exception during deletion: $e');
        // Rollback on exception
        if (!_notifications.any((n) => n['id'] == id)) {
          _notifications.insert(index, backup);
          notifyListeners();
        }
      }
    }
  }

  Future<void> clearAndReload() async {
    _notifications.clear();
    _deletedIds.clear();
    notifyListeners();
    
    await init();
  }

  String _getStorageKey(String base) {
    final email = UserManager().userEmail;
    if (email == null) return base;
    return '${base}_$email';
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getStorageKey('notifications'), jsonEncode(_notifications));
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_getStorageKey('notifications'));
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _notifications = decoded
          .map((item) => Map<String, String>.from(item))
          .where((n) => !_deletedIds.contains(n['id'])) // Double check against deleted tracking
          .toList();
      notifyListeners();
    }
  }

  Future<void> saveDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_getStorageKey('deleted_notification_ids'), _deletedIds.toList());
  }

  Future<void> loadDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? ids = prefs.getStringList(_getStorageKey('deleted_notification_ids'));
    if (ids != null) {
      _deletedIds = ids.toSet();
    }
  }
}
