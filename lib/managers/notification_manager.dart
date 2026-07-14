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
  bool _isLoading = false;

  List<Map<String, String>> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['isRead'] == 'false').length;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await loadNotifications();
    fetchFromApi(); // Fetch from API in background
  }

  Future<void> fetchFromApi() async {
    final token = UserManager().token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.getNotifications(token);
      if (result['success'] && result['data'] != null) {
        final List<dynamic> apiData = result['data'];
        final List<Map<String, String>> apiNotifications = apiData.map((item) {
          return {
            'id': item['_id']?.toString() ?? item['id']?.toString() ?? '',
            'title': item['title']?.toString() ?? '',
            'message': item['message']?.toString() ?? '',
            'time': item['createdAt']?.toString() ?? 'Recent',
            'icon': item['icon']?.toString() ?? '🔔',
            'isRead': (item['isRead'] ?? false).toString(),
            'type': item['type']?.toString() ?? 'general',
          };
        }).toList();

        // Merge or replace
        _notifications = apiNotifications;
        await saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
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
          print('Error marking notification as read on API: $e');
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

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    saveNotifications();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
    saveNotifications();
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_notifications));
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notifications');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _notifications = decoded.map((item) => Map<String, String>.from(item)).toList();
      notifyListeners();
    }
  }
}
