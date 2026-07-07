import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _token;

  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    _userPhone = prefs.getString('user_phone');
    _token = prefs.getString('auth_token');
  }

  Future<void> saveUser(Map<String, dynamic> userData, {String? manualName}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Extract data from 'user' object or top level
    final user = userData['user'] ?? userData;
    
    _userName = user['name'] ?? manualName;
    _userEmail = user['email'];
    _userPhone = user['phone'];
    _token = userData['token'] ?? userData['data']?['token'];

    if (_userName != null) await prefs.setString('user_name', _userName!);
    if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
    if (_userPhone != null) await prefs.setString('user_phone', _userPhone!);
    if (_token != null) await prefs.setString('auth_token', _token!);
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
    await prefs.clear();
    _userName = null;
    _userEmail = null;
    _token = null;
  }

  bool get isLoggedIn => _token != null;
}
