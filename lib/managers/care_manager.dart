import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_manager.dart';

class CareManager extends ChangeNotifier {
  static final CareManager _instance = CareManager._internal();
  factory CareManager() => _instance;
  CareManager._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Local-only data (backup/contacts)
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> get contacts => _contacts;

  // Server-synced data
  Map<String, dynamic> _dashboardMetrics = <String, dynamic>{};
  List<Map<String, dynamic>> _glucoseCurve = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _mealMarkers = <Map<String, dynamic>>[];

  Map<String, dynamic> get metrics => _dashboardMetrics;
  List<Map<String, dynamic>> get glucoseCurve => _glucoseCurve;
  List<Map<String, dynamic>> get mealMarkers => _mealMarkers;

  // Computed shortcuts from metrics
  double get averageGlucose {
    try {
      final val = _dashboardMetrics['avgGlucose'];
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  double get timeInRangePercentage {
    try {
      final val = _dashboardMetrics['timeInRangePercentage'];
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  double get estimatedA1C {
    try {
      final val = _dashboardMetrics['estA1C'];
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _contacts = _loadList('care_contacts');
    
    final bool hasContacts = _contacts != null && _contacts.length > 0;
    if (!hasContacts) {
      _contacts = [
        {'name': 'Dr. Sharma (Endo)', 'phone': '+91 98765 43210'},
        {'name': 'Anita (Primary)', 'phone': '+91 91234 56789'},
      ];
    }
    
    await fetchDashboardData();
    _isInitialized = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> _loadList(String key) {
    final String? data = _prefs.getString(key);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    await _prefs.setString(key, jsonEncode(list));
  }

  Future<void> fetchDashboardData() async {
    final token = UserManager().token;
    if (token == null) return;

    try {
      final result = await ApiService.getGlucoDashboard(token);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is Map) {
          final rawMetrics = data['metrics'];
          if (rawMetrics is Map) {
            _dashboardMetrics = Map<String, dynamic>.from(rawMetrics);
          }

          final rawCurve = data['glucoseCurve'];
          if (rawCurve is List) {
            _glucoseCurve = rawCurve.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } else {
            _glucoseCurve = [];
          }

          final rawMeals = data['mealMarkers'];
          if (rawMeals is List) {
            _mealMarkers = rawMeals.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } else {
            _mealMarkers = [];
          }
        }
      }
    } catch (e) {
      debugPrint('CareManager fetchDashboardData Error: $e');
    }
    notifyListeners();
  }

  Future<bool> addGlucoseLog(double level, String timeOfDay, String type) async {
    final token = UserManager().token;
    if (token == null) return false;

    final result = await ApiService.logGlucoseReading(
      level: level,
      timeOfDay: timeOfDay,
      readingType: type,
      token: token,
    );

    if (result['success']) {
      await fetchDashboardData();
      return true;
    }
    return false;
  }

  Future<bool> addMealLog(String type, double carbs) async {
    final token = UserManager().token;
    if (token == null) return false;

    final result = await ApiService.logMeal(
      mealType: type,
      carbs: carbs,
      token: token,
    );

    if (result['success']) {
      await fetchDashboardData();
      return true;
    }
    return false;
  }

  Future<void> saveContact(String name, String phone) async {
    _contacts.add({'name': name, 'phone': phone});
    await _saveList('care_contacts', _contacts);
    notifyListeners();
  }

  Future<void> deleteContact(int index) async {
    if (index >= 0 && index < _contacts.length) {
      _contacts.removeAt(index);
      await _saveList('care_contacts', _contacts);
      notifyListeners();
    }
  }

  String generateClinicalReport() {
    final StringBuffer report = StringBuffer();
    report.writeln('KOSMICO WELLNESS - CLINICAL REPORT');
    report.writeln('Generated on: ${DateTime.now().toString().split('.')[0]}');
    report.writeln('-----------------------------------');
    report.writeln('\nGLUCOSE SUMMARY:');
    report.writeln('Average Glucose: ${averageGlucose.toStringAsFixed(1)} mg/dL');
    report.writeln('Estimated A1C: ${estimatedA1C.toStringAsFixed(2)}%');
    report.writeln('Time in Range: ${timeInRangePercentage.toStringAsFixed(1)}%');
    
    report.writeln('\nRECENT MEALS:');
    for (var meal in _mealMarkers.reversed.take(10)) {
      report.writeln('${meal['mealType']}: ${meal['carbs']}g carbs (${meal['logTime'].split('T')[0]})');
    }
    
    report.writeln('\n-----------------------------------');
    report.writeln('End of Report');
    return report.toString();
  }

  // Food Database for Scan Meal feature
  final List<Map<String, dynamic>> foodDatabase = [
    {
      'name': 'Paneer Paratha',
      'carbs': 42.0,
      'netCarbs': 38.0,
      'gi': 'High',
      'gl': 'Med',
      'spikeRisk': 'High',
      'swap': 'Multigrain Roti',
    },
    {
      'name': 'Real Guava Juice',
      'carbs': 28.0,
      'netCarbs': 27.0,
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'Very High',
      'swap': 'Fresh Whole Guava',
    },
    {
      'name': 'Cold Drink (Cola)',
      'carbs': 35.0,
      'netCarbs': 35.0,
      'gi': 'Very High',
      'gl': 'High',
      'spikeRisk': 'Extreme',
      'swap': 'Sparkling Water / Fresh Lime',
    },
    {
      'name': 'Apple (Medium)',
      'carbs': 14.0,
      'netCarbs': 11.0,
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Good choice! Keep the skin on.',
    },
    {
      'name': 'Masala Dosa',
      'carbs': 45.0,
      'netCarbs': 42.0,
      'gi': 'High',
      'gl': 'Med',
      'spikeRisk': 'High',
      'swap': 'Oats Dosa or Moong Dal Dosa',
    },
    {
      'name': 'Dal Tadka & Rice',
      'carbs': 65.0,
      'netCarbs': 60.0,
      'gi': 'Med',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Dal with Cauliflower Rice / Quinoa',
    },
  ];
}
