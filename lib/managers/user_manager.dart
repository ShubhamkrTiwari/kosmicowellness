import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_manager.dart';
import 'subscription_manager.dart';
import '../services/api_service.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _profilePicture;
  String? _token;
  String? _userId;
  String? _sessionLoginTime;

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get profilePicture => _profilePicture;
  String? get token => _token;
  String? get userId => _userId;
  String? get sessionLoginTime => _sessionLoginTime;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    _userPhone = prefs.getString('user_phone');
    _profilePicture = prefs.getString('profile_picture');
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _sessionLoginTime = prefs.getString('session_login_time');
    
    if (_sessionLoginTime == null && _token != null) {
      _sessionLoginTime = DateTime.now().toIso8601String();
      await prefs.setString('session_login_time', _sessionLoginTime!);
    }
    
    if ((_userName == null || _userName!.trim().isEmpty || _userName == 'User') && _userEmail != null && _userEmail!.contains('@')) {
      _userName = _userEmail!.split('@').first;
    }
    
    debugPrint('DEBUG: UserManager Init - Token: ${_token != null}, UserID: $_userId, UserName: $_userName');
  }

  Future<void> saveUser(Map<String, dynamic> userData, {String? manualName}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Extract data from 'user' object or top level
    final user = userData['user'] ?? userData['data']?['user'] ?? userData['data'] ?? userData;
    
    _userName = user['name'] ?? 
                user['userName'] ?? 
                user['fullName'] ?? 
                user['username'] ?? 
                user['displayName'] ?? 
                manualName;
    _userEmail = user['email'] ?? userData['email'];
    _userPhone = user['phone'] ?? user['mobile'] ?? user['phoneNumber'];
    _userId = user['_id'] ?? user['id'] ?? user['uid'];

    if ((_userName == null || _userName!.trim().isEmpty || _userName == 'User') && _userEmail != null && _userEmail!.contains('@')) {
      _userName = _userEmail!.split('@').first;
    }
    
    debugPrint('DEBUG: UserManager SaveUser - Name: $_userName, ID: $_userId');
    
    // Explicitly check for profilePicture key to handle null/removal
    if (user is Map && user.containsKey('profilePicture')) {
      _profilePicture = user['profilePicture'];
    } else if (user is Map && user.containsKey('avatar')) {
      _profilePicture = user['avatar'];
    }

    // Update token if it's provided in the response (check multiple possible locations)
    String? newToken = userData['token'] ?? userData['data']?['token'] ?? userData['authToken'] ?? (user is Map ? user['token'] : null);
    if (newToken != null && newToken.isNotEmpty) {
      _token = newToken;
      await prefs.setString('auth_token', _token!);
    }

    if (_userName != null) await prefs.setString('user_name', _userName!);
    if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
    if (_userPhone != null) await prefs.setString('user_phone', _userPhone!);
    if (_userId != null) await prefs.setString('user_id', _userId!);
    if (_profilePicture != null) {
      await prefs.setString('profile_picture', _profilePicture!);
    } else {
      await prefs.remove('profile_picture');
    }

    _sessionLoginTime = DateTime.now().toIso8601String();
    await prefs.setString('session_login_time', _sessionLoginTime!);

    // Restore/refresh subscription state for this user id (locked features
    // unlock only after the ₹99 subscription is bought against this id)
    await SubscriptionManager().loadForUser(_userId);
    SubscriptionManager().syncFromProfile(user is Map ? Map<String, dynamic>.from(user.cast<String, dynamic>()) : null);

    // Refresh notifications for the new user
    NotificationManager().clearAndReload();
  }

  Future<void> updateProfilePicture(String? imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    _profilePicture = imageUrl;
    if (imageUrl != null) {
      await prefs.setString('profile_picture', imageUrl);
    } else {
      await prefs.remove('profile_picture');
    }
  }

  Future<void> updateProfile(String name, String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      try {
        await ApiService.clearAllNotifications(_token!);
      } catch (e) {
        debugPrint('Error clearing notifications on logout: $e');
      }
    }

    // Per-user-id subscription data must SURVIVE logout, so that logging back
    // in with the same id does not refill the 2 free trials or re-lock a
    // purchased ₹99 subscription. Only session data gets cleared below.
    final Map<String, Object> preservedSubData = {};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('trial_') ||
          key.startsWith('subscribed_') ||
          key.startsWith('sub_payment_')) {
        final value = prefs.get(key);
        if (value != null) preservedSubData[key] = value;
      }
    }

    await prefs.clear();

    for (final entry in preservedSubData.entries) {
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      }
    }

    _userName = null;
    _userEmail = null;
    _token = null;
    _userId = null;
    _sessionLoginTime = null;

    // Reset subscription/trial state so the next user starts fresh
    await SubscriptionManager().loadForUser(null);

    // Reset notification manager for next user
    await NotificationManager().clearAndReload();
  }

  bool get isLoggedIn => _token != null;
}
