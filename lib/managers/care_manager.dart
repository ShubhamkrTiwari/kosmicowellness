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

  // Local-only data (backup/contacts/lifestyle/devices)
  List<Map<String, dynamic>> _contacts = [];
  int _waterIntake = 0; // in ml
  int _stressLevel = 0; // 0-5 scale (0 means not logged)
  int _energyLevel = 0; // 0-5 scale (0 means not logged)
  List<Map<String, dynamic>> _medicationLogs = [];
  List<Map<String, dynamic>> _insulinLogs = [];
  List<Map<String, dynamic>> _communityPosts = [];
  
  List<Map<String, dynamic>> _devices = [
    {'name': 'Dexcom G7 CGM', 'type': 'CGM', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.sensors},
    {'name': 'Apple Watch Ultra', 'type': 'Smartwatch', 'connected': true, 'isPairing': false, 'lastData': '98 mg/dL', 'icon': Icons.watch},
    {'name': 'Samsung Galaxy Watch 6', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Fitbit Sense 2', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Garmin Venu 3', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Google Pixel Watch 3', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Fossil Gen 6', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Generic Smartwatch', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.bluetooth},
    {'name': 'Accu-Chek Guide', 'type': 'Glucometer', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.bloodtype},
  ];
  
  List<Map<String, dynamic>> get contacts => _contacts;
  int get waterIntake => _waterIntake;
  int get stressLevel => _stressLevel;
  int get energyLevel => _energyLevel;
  List<Map<String, dynamic>> get medicationLogs => _medicationLogs;
  List<Map<String, dynamic>> get insulinLogs => _insulinLogs;
  List<Map<String, dynamic>> get communityPosts => _communityPosts;
  List<Map<String, dynamic>> get devices => _devices;

  String get connectedDeviceName {
    final connected = _devices.where((d) => d['connected'] == true).toList();
    if (connected.isEmpty) return 'No device connected';
    if (connected.length == 1) return connected.first['name'];
    return '${connected.first['name']} + ${connected.length - 1} more';
  }

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
    
    // Load lifestyle data with daily reset logic
    _loadLifestyleData();
    _loadCommunityPosts();
    
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

  void setPairing(int index, bool val) {
    if (index >= 0 && index < _devices.length) {
      _devices[index]['isPairing'] = val;
      notifyListeners();
    }
  }

  void toggleDeviceConnection(int index) {
    if (index >= 0 && index < _devices.length) {
      final bool newVal = !_devices[index]['connected'];
      _devices[index]['connected'] = newVal;
      if (newVal) {
        _devices[index]['lastData'] = '${80 + (DateTime.now().millisecond % 40)} mg/dL';
      } else {
        _devices[index]['lastData'] = null;
      }
      notifyListeners();
    }
  }

  Future<bool> simulateDeviceSync() async {
    final token = UserManager().token;
    if (token == null) return false;

    // Generate a realistic random glucose reading (between 80 and 160)
    final double randomLevel = 80 + (DateTime.now().millisecond % 80).toDouble();
    final hour = DateTime.now().hour;
    String timeOfDay = 'Day';
    if (hour >= 5 && hour < 11) timeOfDay = 'Dawn';
    else if (hour >= 17 && hour < 21) timeOfDay = 'Dusk';
    else if (hour >= 21 || hour < 5) timeOfDay = 'Night';

    // Log it to the server
    final result = await ApiService.logGlucoseReading(
      level: randomLevel,
      timeOfDay: timeOfDay,
      readingType: 'Random',
      notes: 'Auto-synced from wearable device',
      token: token,
    );

    if (result['success']) {
      await fetchDashboardData();
      return true;
    }
    return false;
  }

  // Lifestyle methods
  void _loadLifestyleData() {
    final String today = DateTime.now().toString().split(' ')[0];
    final String lastLoggedDate = _prefs.getString('last_lifestyle_date') ?? '';
    
    if (lastLoggedDate != today) {
      // New day, reset local metrics
      _waterIntake = 0;
      _stressLevel = 0;
      _energyLevel = 0;
      _medicationLogs = [];
      _insulinLogs = [];
      _prefs.setString('last_lifestyle_date', today);
      _prefs.setInt('daily_water', 0);
      _prefs.setInt('daily_stress', 0);
      _prefs.setInt('daily_energy', 0);
      _prefs.setString('daily_meds', '[]');
      _prefs.setString('daily_insulin', '[]');
    } else {
      _waterIntake = _prefs.getInt('daily_water') ?? 0;
      _stressLevel = _prefs.getInt('daily_stress') ?? 0;
      _energyLevel = _prefs.getInt('daily_energy') ?? 0;
      _medicationLogs = _loadList('daily_meds');
      _insulinLogs = _loadList('daily_insulin');
    }
  }

  void _loadCommunityPosts() {
    _communityPosts = _loadList('community_posts');
    if (_communityPosts.isEmpty) {
      // Default posts if none exist
      _communityPosts = [
        {
          'id': '1',
          'user': 'Rohan M.',
          'time': '2 hours ago',
          'content': 'Just tried the Almond Flour Roti from the Recipes tab! It actually tasted great and my post-meal glucose was only 132. Progress! 🎉',
          'image': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=400&q=80',
          'likes': 12,
          'isLiked': false,
          'comments': [],
        },
        {
          'id': '2',
          'user': 'Sneha K.',
          'time': '5 hours ago',
          'content': 'Managed to walk 10k steps today. Feeling tired but seeing more stable trends in the morning. Anyone has tips for Dawn Phenomenon?',
          'image': null,
          'likes': 24,
          'isLiked': false,
          'comments': [],
        },
      ];
    } else {
      // Ensure all loaded posts have the comments field (migration logic)
      for (var post in _communityPosts) {
        if (post['comments'] == null) post['comments'] = [];
        if (post['isLiked'] == null) post['isLiked'] = false;
      }
    }
  }

  Future<void> addCommunityPost(String user, String content, {String? image}) async {
    final newPost = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user': user,
      'time': 'Just now',
      'content': content,
      'image': image,
      'likes': 0,
      'isLiked': false,
      'comments': [],
    };
    _communityPosts.insert(0, newPost);
    await _saveList('community_posts', _communityPosts);
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final index = _communityPosts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      final bool currentlyLiked = _communityPosts[index]['isLiked'] ?? false;
      _communityPosts[index]['isLiked'] = !currentlyLiked;
      _communityPosts[index]['likes'] = (_communityPosts[index]['likes'] ?? 0) + (currentlyLiked ? -1 : 1);
      await _saveList('community_posts', _communityPosts);
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String comment) async {
    final index = _communityPosts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      final List comments = List.from(_communityPosts[index]['comments'] ?? []);
      comments.add({
        'user': 'You',
        'text': comment,
        'time': 'Just now',
      });
      _communityPosts[index]['comments'] = comments;
      await _saveList('community_posts', _communityPosts);
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    _communityPosts.removeWhere((p) => p['id'] == postId);
    await _saveList('community_posts', _communityPosts);
    notifyListeners();
  }

  Future<void> addWater(int amount) async {
    _waterIntake += amount;
    await _prefs.setInt('daily_water', _waterIntake);
    notifyListeners();
  }

  Future<void> setStressLevel(int level) async {
    _stressLevel = level;
    await _prefs.setInt('daily_stress', _stressLevel);
    notifyListeners();
  }

  Future<void> setEnergyLevel(int level) async {
    _energyLevel = level;
    await _prefs.setInt('daily_energy', _energyLevel);
    notifyListeners();
  }

  Future<void> addMedicationLog(String name, String dose) async {
    _medicationLogs.add({
      'name': name,
      'dose': dose,
      'time': DateTime.now().toIso8601String(),
    });
    await _saveList('daily_meds', _medicationLogs);
    notifyListeners();
  }

  Future<void> addInsulinLog(double units, String timeOfDay) async {
    _insulinLogs.add({
      'units': units,
      'timeOfDay': timeOfDay,
      'time': DateTime.now().toIso8601String(),
    });
    await _saveList('daily_insulin', _insulinLogs);
    notifyListeners();
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
    
    report.writeln('\nLIFESTYLE METRICS (TODAY):');
    report.writeln('Water Intake: $_waterIntake ml');
    String stressDesc = 'Not Logged';
    if (_stressLevel == 1) stressDesc = 'Very Low';
    else if (_stressLevel == 2) stressDesc = 'Low';
    else if (_stressLevel == 3) stressDesc = 'Moderate';
    else if (_stressLevel == 4) stressDesc = 'High';
    else if (_stressLevel == 5) stressDesc = 'Very High';
    report.writeln('Stress Level: $stressDesc');

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
      'name': 'Plain Roti / Chapati',
      'carbs': 18.0,
      'netCarbs': 15.0,
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Good choice! Try Multigrain Roti for even better control.',
      'keywords': ['roti', 'chapati', 'phulka', 'bread', 'flatbread', 'wheat'],
    },
    {
      'name': 'Multigrain Roti',
      'carbs': 15.0,
      'netCarbs': 11.0,
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Excellent choice for glucose management.',
      'keywords': ['roti', 'multigrain', 'bread', 'wheat', 'fiber'],
    },
    {
      'name': 'Paneer Paratha',
      'carbs': 42.0,
      'netCarbs': 38.0,
      'gi': 'High',
      'gl': 'Med',
      'spikeRisk': 'High',
      'swap': 'Plain Roti or Multigrain Roti',
      'keywords': ['paratha', 'stuffed paratha', 'paneer', 'dough', 'stuffed'],
    },
    {
      'name': 'Real Guava Juice',
      'carbs': 28.0,
      'netCarbs': 27.0,
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'Very High',
      'swap': 'Fresh Whole Guava',
      'keywords': ['juice', 'drink', 'beverage', 'guava', 'liquid'],
    },
    {
      'name': 'Cold Drink (Cola)',
      'carbs': 35.0,
      'netCarbs': 35.0,
      'gi': 'Very High',
      'gl': 'High',
      'spikeRisk': 'Extreme',
      'swap': 'Sparkling Water / Fresh Lime',
      'keywords': ['cola', 'drink', 'soda', 'beverage', 'can', 'bottle'],
    },
    {
      'name': 'Aloo Paratha',
      'carbs': 35.0,
      'netCarbs': 32.0,
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Plain Roti or Vegetable Roti',
      'keywords': ['paratha', 'aloo', 'potato', 'stuffed'],
    },
    {
      'name': 'Apple (Medium)',
      'carbs': 14.0,
      'netCarbs': 11.0,
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Good choice! Keep the skin on.',
      'keywords': ['apple', 'fruit', 'round', 'red', 'green'],
    },
    {
      'name': 'Plain Dosa',
      'carbs': 25.0,
      'netCarbs': 23.0,
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Med',
      'swap': 'Oats Dosa or Moong Dal Dosa',
      'keywords': ['dosa', 'pancake', 'south indian', 'plain'],
    },
    {
      'name': 'Masala Dosa',
      'carbs': 45.0,
      'netCarbs': 42.0,
      'gi': 'High',
      'gl': 'Med',
      'spikeRisk': 'High',
      'swap': 'Oats Dosa or Moong Dal Dosa',
      'keywords': ['dosa', 'pancake', 'crepe', 'south indian'],
    },
    {
      'name': 'Dal Tadka & Rice',
      'carbs': 65.0,
      'netCarbs': 60.0,
      'gi': 'Med',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Dal with Cauliflower Rice / Quinoa',
      'keywords': ['rice', 'dal', 'grain', 'bowl', 'curry'],
    },
    {
      'name': 'Water (Bottle)',
      'carbs': 0.0,
      'netCarbs': 0.0,
      'gi': 'None',
      'gl': 'None',
      'spikeRisk': 'None',
      'swap': 'Great choice! Stay hydrated.',
      'keywords': ['water', 'bottle', 'plastic', 'liquid', 'transparent'],
    },
    {
      'name': 'Samosa (1 piece)',
      'carbs': 18.0,
      'netCarbs': 16.0,
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'Very High',
      'swap': 'Baked Paneer Cubes',
      'keywords': ['samosa', 'pastry', 'fried', 'snack', 'triangle'],
    },
    {
      'name': 'Banana (Medium)',
      'carbs': 27.0,
      'netCarbs': 24.0,
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Berries or Guava',
      'keywords': ['banana', 'fruit', 'yellow', 'long'],
    },
    {
      'name': 'Pizza (1 slice)',
      'carbs': 25.0,
      'netCarbs': 23.0,
      'gi': 'High',
      'gl': 'Med',
      'spikeRisk': 'High',
      'swap': 'Keto Pizza or Whole Wheat Roti',
      'keywords': ['pizza', 'cheese', 'pepperoni', 'italian', 'fast food'],
    },
    {
      'name': 'Indian Thali (Full)',
      'carbs': 85.0,
      'netCarbs': 78.0,
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'Very High',
      'swap': 'Smaller portion of rice, more salad/dal',
      'keywords': ['thali', 'platter', 'meal', 'tableware', 'dishware', 'lunch', 'dinner', 'plate', 'rice', 'curry', 'bowl', 'katori', 'indian cuisine'],
    },
    {
      'name': 'Salad Bowl',
      'carbs': 12.0,
      'netCarbs': 8.0,
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Great choice! Add protein.',
      'keywords': ['salad', 'vegetable', 'leafy', 'green', 'healthy', 'broccoli', 'cucumber'],
    },
  ];
}
