import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  List<Map<String, String>> _notifications = [];

  List<Map<String, String>> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['isRead'] == 'false').length;

  Future<void> init() async {
    await loadNotifications();
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

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = 'true';
      notifyListeners();
      saveNotifications();
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
