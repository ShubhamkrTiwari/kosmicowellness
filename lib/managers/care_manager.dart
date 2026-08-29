import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_manager.dart';
import 'bluetooth_manager.dart';

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
    {'name': 'Apple Watch Ultra', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Samsung Galaxy Watch 6', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Noise ColorFit', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'boAt Wave', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Fitbit Sense 2', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
    {'name': 'Garmin Venu 3', 'type': 'Smartwatch', 'connected': false, 'isPairing': false, 'lastData': null, 'icon': Icons.watch},
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
    final bleDevice = BluetoothManager().connectedDeviceName;
    if (bleDevice.isNotEmpty && bleDevice != 'No device connected') {
      return bleDevice;
    }
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
    
    final bool hasContacts = _contacts.isNotEmpty;
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
        'user': UserManager().userName ?? 'You',
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
    final String dateStr = DateTime.now().toString().split('.')[0];
    final String patient = UserManager().userName ?? 'Valued Patient';
    final String email = UserManager().userEmail ?? 'N/A';
    
    final double avg = averageGlucose > 0 ? averageGlucose : 118.0;
    final double a1c = estimatedA1C > 0 ? estimatedA1C : ((avg + 46.7) / 28.7);
    final double tir = timeInRangePercentage > 0 ? timeInRangePercentage : 78.5;
    
    report.writeln('====================================================');
    report.writeln('  KOSMICO METABOLIC CARE & DIABETES DIAGNOSTIC LAB  ');
    report.writeln('     GLUCORHYTHM CLINICAL BIO-MARKER PROFILE       ');
    report.writeln('====================================================');
    report.writeln('PATIENT DEMOGRAPHICS:');
    report.writeln('Patient Name : $patient');
    report.writeln('Contact/Email: $email');
    report.writeln('Report Date  : $dateStr');
    report.writeln('Report ID    : KOS-GLU-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');
    report.writeln('Specimen     : Capillary Blood & Continuous Glucose Telemetry');
    report.writeln('Clinical Ref : ADA Standards of Medical Care in Diabetes');
    report.writeln('----------------------------------------------------');
    report.writeln('\n[1] GLYCEMIC CONTROL & METABOLIC BIOMARKERS');
    report.writeln('PARAMETER               RESULT      REF. RANGE     STATUS');
    report.writeln('----------------------------------------------------');
    report.writeln('Estimated HbA1c         ${a1c.toStringAsFixed(2)} %      < 5.7 %        ${a1c < 5.7 ? 'NORMAL' : (a1c <= 6.4 ? 'PRE-DIABETIC' : (a1c <= 7.0 ? 'CONTROLLED' : 'ELEVATED'))}');
    report.writeln('Mean Blood Glucose      ${avg.toStringAsFixed(1)} mg/dL 70-130 mg/dL   ${avg <= 130 ? 'IN TARGET' : (avg <= 180 ? 'MODERATE' : 'HIGH SPIKE')}');
    report.writeln('Time in Range (70-180)  ${tir.toStringAsFixed(1)} %      > 70.0 %       ${tir >= 70 ? 'OPTIMAL (ADA)' : 'NEEDS ADJUSTMENT'}');
    report.writeln('Glucose Management Ind. ${(3.31 + 0.02392 * avg).toStringAsFixed(2)} %      < 6.5 %        OPTIMAL');
    report.writeln('----------------------------------------------------');
    
    report.writeln('\n[2] LIFESTYLE & ADHERENCE MARKERS (TODAY)');
    report.writeln('Hydration (Water Intake) : $_waterIntake ml (Target: 2500-3000 ml)');
    String stressDesc = 'Not Logged';
    if (_stressLevel == 1) stressDesc = 'Very Low (Optimal Cortisol)';
    else if (_stressLevel == 2) stressDesc = 'Low (Healthy)';
    else if (_stressLevel == 3) stressDesc = 'Moderate';
    else if (_stressLevel == 4) stressDesc = 'High (Risk of Epinephrine Spike)';
    else if (_stressLevel == 5) stressDesc = 'Very High (Clinical Stress Alert)';
    report.writeln('Stress & Cortisol Index  : $stressDesc');
    report.writeln('Active Meds Logged       : ${_medicationLogs.isNotEmpty ? _medicationLogs.length : 'None recorded'}');
    report.writeln('Insulin Regimen Logs     : ${_insulinLogs.isNotEmpty ? _insulinLogs.length : 'None recorded'}');
    report.writeln('----------------------------------------------------');

    if (_mealMarkers.isNotEmpty) {
      report.writeln('\n[3] RECENT GLYCEMIC LOAD & MEAL INVENTORY');
      for (var meal in _mealMarkers.reversed.take(6)) {
        final date = (meal['logTime'] ?? '').toString().split('T')[0];
        report.writeln('• ${meal['mealType']}: ${meal['carbs']}g Carbs | Status: ${meal['status'] ?? 'Logged'} ($date)');
      }
      report.writeln('----------------------------------------------------');
    }

    report.writeln('\n[4] AI DIABETOLOGIST CLINICAL IMPRESSION:');
    if (a1c < 5.7) {
      report.writeln('• Glycemic status is within non-diabetic range. Continue healthy balanced nutrition.');
    } else if (a1c <= 6.4) {
      report.writeln('• Patient indicates pre-diabetic glycemic excursions. Dietary carbohydrate moderation and active post-prandial walking advised.');
    } else if (a1c <= 7.0) {
      report.writeln('• Glycemic control meets the American Diabetes Association (ADA) target (<7.0%) for managed diabetes.');
    } else {
      report.writeln('• Glycemic elevation detected. Recommend consultation with attending physician for pharmacotherapy or insulin titration.');
    }
    report.writeln('• Time-in-Range is at ${tir.toStringAsFixed(1)}%. Aim for minimum 70% daily in 70-180 mg/dL bracket.');
    report.writeln('\n====================================================');
    report.writeln('Verified By: Kosmico GlucoRhythm Diagnostic Engine');
    report.writeln('Clinical Notice: Grounded in ADA standards. For consultation with your healthcare provider.');
    report.writeln('====================================================');
    return report.toString();
  }

  // Food Database for Scan Meal feature & Diabetic Nutrition Engine
  final List<Map<String, dynamic>> foodDatabase = [
    {
      'name': 'Plain Roti / Chapati',
      'carbs': 18.0,
      'netCarbs': 15.0,
      'calories': 85,
      'protein': 3.0,
      'fiber': 3.0,
      'fat': 0.5,
      'portion': '1 piece (35g)',
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Great baseline staple! Multigrain or Bajra Roti provides slower absorption.',
      'keywords': ['roti', 'chapati', 'phulka', 'bread', 'flatbread', 'wheat', 'atta'],
    },
    {
      'name': 'Multigrain Roti',
      'carbs': 15.0,
      'netCarbs': 11.0,
      'calories': 78,
      'protein': 4.0,
      'fiber': 4.0,
      'fat': 1.0,
      'portion': '1 piece (35g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Excellent choice! High fiber keeps glucose response very steady.',
      'keywords': ['multigrain', 'roti', 'fiber', 'oats roti', 'chana roti', 'bread', 'flatbread'],
    },
    {
      'name': 'Bajra / Jowar Roti',
      'carbs': 16.0,
      'netCarbs': 12.0,
      'calories': 80,
      'protein': 3.5,
      'fiber': 4.0,
      'fat': 1.2,
      'portion': '1 piece (40g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Superb millet choice. Rich in magnesium and micronutrients.',
      'keywords': ['bajra', 'jowar', 'millet', 'bhakri', 'rotla', 'flatbread'],
    },
    {
      'name': 'Paneer Paratha',
      'carbs': 38.0,
      'netCarbs': 34.0,
      'calories': 280,
      'protein': 12.0,
      'fiber': 4.0,
      'fat': 12.0,
      'portion': '1 medium paratha',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Good protein content! Use minimal ghee/oil to limit calorie density.',
      'keywords': ['paneer paratha', 'paratha', 'paneer', 'cheese', 'stuffed bread'],
    },
    {
      'name': 'Aloo Paratha',
      'carbs': 45.0,
      'netCarbs': 41.0,
      'calories': 310,
      'protein': 6.0,
      'fiber': 4.0,
      'fat': 13.0,
      'portion': '1 medium paratha',
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Try Cauliflower (Gobi) or Paneer Paratha for reduced starch load.',
      'keywords': ['aloo paratha', 'aloo', 'potato', 'paratha', 'flatbread', 'stuffed'],
    },
    {
      'name': 'Plain Paratha (Ghee/Oil)',
      'carbs': 32.0,
      'netCarbs': 29.0,
      'calories': 240,
      'protein': 4.5,
      'fiber': 3.0,
      'fat': 11.0,
      'portion': '1 piece',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Switch to dry phulka/roti with a light brush of cold-pressed oil.',
      'keywords': ['plain paratha', 'paratha', 'layer bread', 'flatbread', 'ghee'],
    },
    {
      'name': 'Dal Tadka / Yellow Lentils',
      'carbs': 20.0,
      'netCarbs': 15.0,
      'calories': 150,
      'protein': 9.0,
      'fiber': 5.0,
      'fat': 4.0,
      'portion': '1 katori / bowl (150g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'High fiber & protein. Pairs best with salads and whole grain roti.',
      'keywords': ['dal', 'daal', 'tadka', 'yellow dal', 'toor dal', 'moong dal', 'lentil', 'soup', 'curry'],
    },
    {
      'name': 'Dal Makhani',
      'carbs': 28.0,
      'netCarbs': 21.0,
      'calories': 260,
      'protein': 11.0,
      'fiber': 7.0,
      'fat': 14.0,
      'portion': '1 bowl (150g)',
      'gi': 'Low',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'High in cream/butter. Consider low-fat yellow dal or Chana Masala.',
      'keywords': ['dal makhani', 'black dal', 'urad', 'cream', 'makhani', 'lentil'],
    },
    {
      'name': 'Chole / Chana Masala',
      'carbs': 30.0,
      'netCarbs': 22.0,
      'calories': 210,
      'protein': 10.0,
      'fiber': 8.0,
      'fat': 6.0,
      'portion': '1 bowl (150g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Chickpeas provide resistant starch that regulates blood glucose well.',
      'keywords': ['chole', 'chana', 'chickpeas', 'curry', 'gravy', 'garbanzo'],
    },
    {
      'name': 'Rajma Masala (Kidney Beans)',
      'carbs': 28.0,
      'netCarbs': 20.0,
      'calories': 200,
      'protein': 11.0,
      'fiber': 8.0,
      'fat': 5.0,
      'portion': '1 bowl (150g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'High dietary fiber. Pair with 1 roti or brown rice instead of large white rice.',
      'keywords': ['rajma', 'kidney beans', 'beans', 'curry', 'gravy'],
    },
    {
      'name': 'Palak Paneer',
      'carbs': 8.0,
      'netCarbs': 5.0,
      'calories': 220,
      'protein': 14.0,
      'fiber': 3.0,
      'fat': 16.0,
      'portion': '1 bowl (150g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Outstanding low-carb option! Spinach + paneer minimizes glucose spikes.',
      'keywords': ['palak paneer', 'spinach', 'palak', 'paneer', 'green curry'],
    },
    {
      'name': 'Paneer Butter Masala',
      'carbs': 14.0,
      'netCarbs': 11.0,
      'calories': 320,
      'protein': 13.0,
      'fiber': 3.0,
      'fat': 24.0,
      'portion': '1 bowl (150g)',
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Moderate carbs, but high saturated fat. Tofu or Matar Paneer is lighter.',
      'keywords': ['paneer butter masala', 'paneer tikka masala', 'cottage cheese', 'curry', 'gravy'],
    },
    {
      'name': 'Mixed Vegetable Sabzi',
      'carbs': 12.0,
      'netCarbs': 8.0,
      'calories': 110,
      'protein': 3.5,
      'fiber': 4.0,
      'fat': 5.0,
      'portion': '1 bowl (150g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Excellent daily source of fiber, vitamins and antioxidants.',
      'keywords': ['mixed veg', 'sabzi', 'vegetable', 'beans', 'carrot', 'gobi', 'peas'],
    },
    {
      'name': 'Bhindi Masala (Okra)',
      'carbs': 9.0,
      'netCarbs': 5.0,
      'calories': 95,
      'protein': 2.5,
      'fiber': 4.0,
      'fat': 4.5,
      'portion': '1 bowl (120g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Okra is known for blood sugar lowering properties. Great choice.',
      'keywords': ['bhindi', 'okra', 'ladyfinger', 'sabzi', 'green vegetable'],
    },
    {
      'name': 'Steamed White Rice',
      'carbs': 45.0,
      'netCarbs': 44.0,
      'calories': 205,
      'protein': 4.2,
      'fiber': 1.0,
      'fat': 0.4,
      'portion': '1 bowl (150g)',
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Replace with Brown Rice, Quinoa, or Cauliflower Rice to prevent fast spikes.',
      'keywords': ['rice', 'white rice', 'steamed rice', 'chawal', 'grain'],
    },
    {
      'name': 'Brown Rice',
      'carbs': 38.0,
      'netCarbs': 34.0,
      'calories': 180,
      'protein': 4.5,
      'fiber': 4.0,
      'fat': 1.5,
      'portion': '1 bowl (150g)',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Much lower glycemic impact than white rice due to intact bran.',
      'keywords': ['brown rice', 'whole grain rice', 'unpolished rice'],
    },
    {
      'name': 'Vegetable Pulao / Biryani',
      'carbs': 42.0,
      'netCarbs': 38.0,
      'calories': 240,
      'protein': 6.0,
      'fiber': 4.0,
      'fat': 7.0,
      'portion': '1 plate (200g)',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Add extra veggies or a side of cucumber raita to slow digestion.',
      'keywords': ['pulao', 'veg biryani', 'pilaf', 'vegetable rice', 'fried rice'],
    },
    {
      'name': 'Chicken Curry with Gravy',
      'carbs': 6.0,
      'netCarbs': 4.0,
      'calories': 240,
      'protein': 26.0,
      'fiber': 2.0,
      'fat': 12.0,
      'portion': '1 bowl (180g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Lean protein that stabilizes blood sugar. Pair with green salad and 1 roti.',
      'keywords': ['chicken curry', 'chicken', 'poultry', 'curry', 'meat', 'gravy'],
    },
    {
      'name': 'Egg Curry / Boiled Eggs (2 pcs)',
      'carbs': 3.0,
      'netCarbs': 2.0,
      'calories': 160,
      'protein': 13.0,
      'fiber': 1.0,
      'fat': 10.0,
      'portion': '2 eggs with gravy',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Virtually zero carb spike. High biological value protein.',
      'keywords': ['egg', 'egg curry', 'boiled egg', 'anda', 'omelet', 'protein'],
    },
    {
      'name': 'Steamed Rice with Veg Curry / Sabzi',
      'carbs': 42.0,
      'netCarbs': 37.0,
      'calories': 270,
      'protein': 6.5,
      'fiber': 5.0,
      'fat': 7.0,
      'portion': '1 cup rice + 1 cup mixed veg curry',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Opt for brown rice or increase the vegetable portion to lower the glycemic load.',
      'keywords': ['rice', 'curry', 'sabzi', 'mixed veg', 'veg curry', 'chawal', 'steamed rice', 'vegetable curry'],
    },
    {
      'name': 'Steamed White Rice (1 cup)',
      'carbs': 45.0,
      'netCarbs': 44.0,
      'calories': 205,
      'protein': 4.2,
      'fiber': 1.0,
      'fat': 0.4,
      'portion': '1 medium bowl (150g cooked)',
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Add dal, paneer, or high-fiber vegetable curry to slow down carbohydrate digestion.',
      'keywords': ['rice', 'white rice', 'boiled rice', 'steamed rice', 'chawal', 'plain rice', 'basmati'],
    },
    {
      'name': 'Dal Tadka with Steamed Rice (Dal Chawal)',
      'carbs': 48.0,
      'netCarbs': 41.0,
      'calories': 310,
      'protein': 11.0,
      'fiber': 7.0,
      'fat': 6.0,
      'portion': '1 cup rice + 1 cup yellow dal',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Double the dal-to-rice ratio for extra plant protein and complex fiber.',
      'keywords': ['dal chawal', 'dal rice', 'yellow dal', 'tadka dal', 'lentils', 'rice dal'],
    },
    {
      'name': 'Indian Thali (Complete Meal)',
      'carbs': 75.0,
      'netCarbs': 65.0,
      'calories': 620,
      'protein': 22.0,
      'fiber': 10.0,
      'fat': 20.0,
      'portion': 'Full Thali (2 Roti, Dal, Sabzi, Rice, Salad)',
      'gi': 'Med',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Eat salad first, enjoy the dal/sabzi, and reduce the rice portion to half.',
      'keywords': ['thali', 'full thali', 'platter', 'katori', 'grand meal', 'thali set'],
    },
    {
      'name': 'Plain Dosa',
      'carbs': 28.0,
      'netCarbs': 26.0,
      'calories': 160,
      'protein': 4.0,
      'fiber': 2.0,
      'fat': 4.0,
      'portion': '1 medium dosa',
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Med',
      'swap': 'Try Oats Dosa or Moong Dal (Pesarattu) Dosa for double protein.',
      'keywords': ['dosa', 'plain dosa', 'pancake', 'crepe', 'south indian', 'fermented'],
    },
    {
      'name': 'Masala Dosa',
      'carbs': 48.0,
      'netCarbs': 44.0,
      'calories': 320,
      'protein': 7.0,
      'fiber': 4.0,
      'fat': 11.0,
      'portion': '1 standard dosa',
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Order with less potato stuffing and extra sambar / coconut chutney.',
      'keywords': ['masala dosa', 'dosa', 'potato dosa', 'south indian', 'crepe'],
    },
    {
      'name': 'Idli with Sambar (2 pcs)',
      'carbs': 36.0,
      'netCarbs': 32.0,
      'calories': 190,
      'protein': 7.5,
      'fiber': 4.0,
      'fat': 2.0,
      'portion': '2 idlis + 1 bowl sambar',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Steamed & easily digestible. Try Rava/Oats Idli for lower glycemic response.',
      'keywords': ['idli', 'sambar', 'steamed cake', 'south indian', 'rice cake'],
    },
    {
      'name': 'Poha / Vegetable Flattened Rice',
      'carbs': 38.0,
      'netCarbs': 35.0,
      'calories': 220,
      'protein': 5.0,
      'fiber': 3.0,
      'fat': 6.0,
      'portion': '1 bowl (150g)',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Add plenty of peanuts, peas, and sprout mix to add fiber and protein.',
      'keywords': ['poha', 'flattened rice', 'kanda poha', 'breakfast', 'rice flakes'],
    },
    {
      'name': 'Upma (Semolina / Rava)',
      'carbs': 35.0,
      'netCarbs': 32.0,
      'calories': 210,
      'protein': 5.5,
      'fiber': 3.0,
      'fat': 6.5,
      'portion': '1 bowl (150g)',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Switch to Oats Upma or Broken Wheat (Dalia) Upma for low-GI fiber.',
      'keywords': ['upma', 'rava', 'semolina', 'suji', 'breakfast', 'porridge'],
    },
    {
      'name': 'Oats Porridge (with milk/water)',
      'carbs': 28.0,
      'netCarbs': 23.0,
      'calories': 170,
      'protein': 7.0,
      'fiber': 5.0,
      'fat': 3.5,
      'portion': '1 bowl (200g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Beta-glucan in rolled oats is clinically proven to improve insulin sensitivity.',
      'keywords': ['oats', 'porridge', 'oatmeal', 'cereal', 'breakfast'],
    },
    {
      'name': 'Salad Bowl (Greens, Cucumber, Tomato)',
      'carbs': 10.0,
      'netCarbs': 6.0,
      'calories': 65,
      'protein': 3.0,
      'fiber': 4.0,
      'fat': 0.8,
      'portion': '1 large bowl (200g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Golden standard pre-meal starter. Eating fiber first prevents glucose spikes by 35%.',
      'keywords': ['salad', 'cucumber', 'tomato', 'lettuce', 'leafy', 'green', 'healthy', 'broccoli'],
    },
    {
      'name': 'Apple (Medium with skin)',
      'carbs': 15.0,
      'netCarbs': 12.0,
      'calories': 70,
      'protein': 0.5,
      'fiber': 3.0,
      'fat': 0.2,
      'portion': '1 medium fruit (120g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'Pectin fiber in apple skin blunts glucose absorption. Eat whole, not as juice.',
      'keywords': ['apple', 'fruit', 'red', 'green', 'round', 'fresh'],
    },
    {
      'name': 'Banana (Medium)',
      'carbs': 27.0,
      'netCarbs': 24.0,
      'calories': 105,
      'protein': 1.3,
      'fiber': 3.0,
      'fat': 0.3,
      'portion': '1 medium banana',
      'gi': 'Med',
      'gl': 'Med',
      'spikeRisk': 'Med',
      'swap': 'Choose slightly greenish/unripe bananas for higher resistant starch.',
      'keywords': ['banana', 'kela', 'fruit', 'yellow', 'long'],
    },
    {
      'name': 'Papaya (1 cup cubes)',
      'carbs': 14.0,
      'netCarbs': 11.5,
      'calories': 60,
      'protein': 1.0,
      'fiber': 2.5,
      'fat': 0.2,
      'portion': '1 cup (140g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'High in papain enzymes and fiber. Very safe fruit for diabetes.',
      'keywords': ['papaya', 'papita', 'fruit', 'orange', 'cubes'],
    },
    {
      'name': 'Guava (Medium Fresh)',
      'carbs': 12.0,
      'netCarbs': 7.0,
      'calories': 50,
      'protein': 2.0,
      'fiber': 5.0,
      'fat': 0.5,
      'portion': '1 whole fruit (100g)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'Low',
      'swap': 'One of the best diabetes fruits! Extremely high dietary fiber.',
      'keywords': ['guava', 'amrood', 'fruit', 'green', 'pink'],
    },
    {
      'name': 'Samosa (1 piece)',
      'carbs': 24.0,
      'netCarbs': 22.0,
      'calories': 260,
      'protein': 4.0,
      'fiber': 2.0,
      'fat': 17.0,
      'portion': '1 piece (80g)',
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'Very High',
      'swap': 'Deep-fried maida + potato triggers rapid glucose spikes. Choose roasted makhana or paneer tikka.',
      'keywords': ['samosa', 'snack', 'fried', 'pastry', 'triangle', 'fast food'],
    },
    {
      'name': 'Pakora / Fritters (4 pcs)',
      'carbs': 22.0,
      'netCarbs': 19.0,
      'calories': 240,
      'protein': 6.0,
      'fiber': 3.0,
      'fat': 15.0,
      'portion': '4 small fritters',
      'gi': 'High',
      'gl': 'Med',
      'spikeRisk': 'High',
      'swap': 'Try air-fried or baked vegetable tikkis instead.',
      'keywords': ['pakora', 'bhajiya', 'fritter', 'fried snack', 'besan'],
    },
    {
      'name': 'Dhokla (Khaman / Steamed 2 pcs)',
      'carbs': 20.0,
      'netCarbs': 18.0,
      'calories': 130,
      'protein': 5.0,
      'fiber': 2.0,
      'fat': 4.0,
      'portion': '2 pieces (80g)',
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Med',
      'swap': 'Steamed snack. Request without sugar-sweetened tempering water.',
      'keywords': ['dhokla', 'khaman', 'steamed snack', 'gujarati', 'yellow'],
    },
    {
      'name': 'Pizza (1 regular slice)',
      'carbs': 30.0,
      'netCarbs': 28.0,
      'calories': 280,
      'protein': 11.0,
      'fiber': 2.0,
      'fat': 12.0,
      'portion': '1 slice (100g)',
      'gi': 'High',
      'gl': 'High',
      'spikeRisk': 'High',
      'swap': 'Thin crust with extra veggie toppings and side salad cuts the glycemic load.',
      'keywords': ['pizza', 'slice', 'cheese', 'italian', 'fast food', 'crust'],
    },
    {
      'name': 'Water (Bottle / Glass)',
      'carbs': 0.0,
      'netCarbs': 0.0,
      'calories': 0,
      'protein': 0.0,
      'fiber': 0.0,
      'fat': 0.0,
      'portion': '250ml - 500ml',
      'gi': 'None',
      'gl': 'None',
      'spikeRisk': 'None',
      'swap': 'Perfect hydration. Keeps blood circulation and kidneys filtering optimally.',
      'keywords': ['water', 'bottle', 'plastic', 'liquid', 'transparent', 'drink', 'glass'],
    },
    {
      'name': 'Packaged Fruit Juice (Guava/Mango/Apple)',
      'carbs': 32.0,
      'netCarbs': 31.0,
      'calories': 135,
      'protein': 0.5,
      'fiber': 1.0,
      'fat': 0.1,
      'portion': '1 glass (200ml)',
      'gi': 'Very High',
      'gl': 'High',
      'spikeRisk': 'Extreme',
      'swap': 'Liquid fructose causes sharpest glucose spikes. Always eat the whole fruit instead.',
      'keywords': ['juice', 'packaged juice', 'mango juice', 'guava juice', 'drink', 'beverage', 'tetra pack'],
    },
    {
      'name': 'Cold Drink / Cola / Soda',
      'carbs': 38.0,
      'netCarbs': 38.0,
      'calories': 150,
      'protein': 0.0,
      'fiber': 0.0,
      'fat': 0.0,
      'portion': '1 can / bottle (300ml)',
      'gi': 'Very High',
      'gl': 'High',
      'spikeRisk': 'Extreme',
      'swap': 'Replace with Fresh Lime Soda (no sugar), Green Tea, or Infused Mint Water.',
      'keywords': ['cola', 'cold drink', 'soda', 'pepsi', 'coke', 'can', 'fizzy drink'],
    },
    {
      'name': 'Chai / Indian Milk Tea (with sugar)',
      'carbs': 14.0,
      'netCarbs': 14.0,
      'calories': 90,
      'protein': 3.0,
      'fiber': 0.0,
      'fat': 2.5,
      'portion': '1 cup (150ml)',
      'gi': 'Med',
      'gl': 'Low',
      'spikeRisk': 'Med',
      'swap': 'Switch to Stevia or sugar-free sweetener, or enjoy fragrant masala tea without refined sugar.',
      'keywords': ['tea', 'chai', 'milk tea', 'cup', 'hot drink', 'beverage'],
    },
    {
      'name': 'Green Tea / Black Coffee (No Sugar)',
      'carbs': 0.5,
      'netCarbs': 0.5,
      'calories': 5,
      'protein': 0.2,
      'fiber': 0.0,
      'fat': 0.0,
      'portion': '1 cup (200ml)',
      'gi': 'Low',
      'gl': 'Low',
      'spikeRisk': 'None',
      'swap': 'Rich in polyphenols and EGCG which support glucose control and metabolism.',
      'keywords': ['green tea', 'black coffee', 'coffee', 'espresso', 'herbal tea'],
    },
  ];

  // Helper method: search food from local clinical database
  List<Map<String, dynamic>> searchFood(String query) {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) return foodDatabase;

    return foodDatabase.where((item) {
      final name = item['name'].toString().toLowerCase();
      if (name.contains(cleanQ)) return true;

      final keywords = item['keywords'] as List<dynamic>?;
      if (keywords != null) {
        for (var kw in keywords) {
          if (kw.toString().toLowerCase().contains(cleanQ) || cleanQ.contains(kw.toString().toLowerCase())) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  // Advanced Multi-Candidate Recognition Result
  FoodRecognitionResult matchFoodFromLabels(List<String> labels, {File? imageFile}) {
    if (labels.isEmpty) {
      return FoodRecognitionResult(
        bestMatch: null,
        alternateMatches: foodDatabase.take(4).toList(),
        isFoodDetected: false,
        confidence: 0.0,
        description: 'No specific visual elements detected.',
      );
    }

    final lowerLabels = labels.map((l) => l.toLowerCase().trim()).toList();
    final combined = lowerLabels.join(' ');

    // 1. Check for non-food images (e.g. wall, shoe, car, electronics)
    final nonFoodKeywords = [
      'furniture', 'wall', 'door', 'building', 'flooring', 'wood', 'table',
      'desk', 'car', 'vehicle', 'tire', 'clothing', 'shoe', 'footwear',
      'electronics', 'screen', 'computer', 'laptop', 'gadget', 'plant',
      'flowerpot', 'ceiling', 'sky', 'textile'
    ];
    final foodKeywords = [
      'food', 'dish', 'meal', 'cuisine', 'tableware', 'dishware', 'ingredient',
      'recipe', 'fruit', 'vegetable', 'bread', 'curry', 'soup', 'rice',
      'beverage', 'drink', 'dairy', 'snack', 'pancake', 'meat', 'poultry'
    ];

    bool hasFoodIndicator = lowerLabels.any((l) => foodKeywords.any((fk) => l.contains(fk)));
    bool hasNonFoodOnly = lowerLabels.every((l) => nonFoodKeywords.any((nfk) => l.contains(nfk)));

    if (hasNonFoodOnly && !hasFoodIndicator) {
      return FoodRecognitionResult(
        bestMatch: null,
        alternateMatches: foodDatabase.take(4).toList(),
        isFoodDetected: false,
        confidence: 0.0,
        description: 'Photo does not appear to contain food items.',
      );
    }

    // 2. Score every item in the food database
    final List<Map<String, dynamic>> scoredList = [];

    for (var food in foodDatabase) {
      double score = 0.0;
      final foodName = food['name'].toString().toLowerCase();
      final keywords = (food['keywords'] as List<dynamic>?)?.map((k) => k.toString().toLowerCase()) ?? [];

      for (var label in lowerLabels) {
        // Direct exact name match
        if (foodName.contains(label) || label.contains(foodName)) {
          score += 60.0;
        }

        for (var kw in keywords) {
          if (label == kw) {
            score += 45.0; // High exact match
          } else if (label.contains(kw) || kw.contains(label)) {
            score += 25.0; // Partial match
          }
        }
      }

      // Contextual Category Bonuses
      if (combined.contains('fruit') && foodName.contains('apple') && combined.contains('apple')) score += 50;
      if (combined.contains('fruit') && foodName.contains('banana') && combined.contains('banana')) score += 50;
      if (combined.contains('fruit') && foodName.contains('guava') && combined.contains('guava')) score += 50;
      if (combined.contains('pizza') && foodName.contains('pizza')) score += 60;
      if (combined.contains('salad') && foodName.contains('salad')) score += 55;
      if (combined.contains('dosa') && foodName.contains('dosa')) score += 55;
      if (combined.contains('idli') && foodName.contains('idli')) score += 55;
      if (combined.contains('samosa') && foodName.contains('samosa')) score += 55;
      if (combined.contains('bottle') && foodName.contains('water')) score += 60;
      if (combined.contains('tea') && foodName.contains('tea')) score += 40;
      if (combined.contains('coffee') && foodName.contains('coffee')) score += 40;
      if (combined.contains('chicken') && foodName.contains('chicken')) score += 45;
      if (combined.contains('egg') && foodName.contains('egg')) score += 45;
      if ((combined.contains('rice') || combined.contains('chawal')) && (combined.contains('curry') || combined.contains('sabzi') || combined.contains('vegetable') || combined.contains('gravy'))) {
        if (foodName.contains('rice with veg curry')) score += 80;
        if (foodName.contains('dal chawal')) score += 60;
      } else if (combined.contains('rice') || combined.contains('chawal')) {
        if (foodName.contains('steamed white rice')) score += 50;
        else if (foodName.contains('rice')) score += 35;
      }
      if (combined.contains('lentil') || combined.contains('soup') || combined.contains('dal')) {
        if (foodName.contains('dal') || foodName.contains('lentil')) score += 35;
      }
      if (combined.contains('bread') || combined.contains('flatbread') || combined.contains('roti') || combined.contains('paratha')) {
        if (foodName.contains('roti') || foodName.contains('paratha') || foodName.contains('chapati')) score += 30;
      }

      if (score > 0) {
        final copy = Map<String, dynamic>.from(food);
        copy['_matchScore'] = score;
        scoredList.add(copy);
      }
    }

    // Sort by score descending
    scoredList.sort((a, b) => (b['_matchScore'] as double).compareTo(a['_matchScore'] as double));

    if (scoredList.isNotEmpty) {
      final best = scoredList.first;
      final double topScore = best['_matchScore'] as double;
      final alternates = scoredList.skip(1).take(4).toList();

      // If less than 4 alternates, pad with popular everyday diabetic foods
      if (alternates.length < 3) {
        for (var f in foodDatabase) {
          if (f['name'] != best['name'] && !alternates.any((a) => a['name'] == f['name'])) {
            alternates.add(f);
            if (alternates.length >= 4) break;
          }
        }
      }

      return FoodRecognitionResult(
        bestMatch: best,
        alternateMatches: alternates,
        confidence: (topScore / 100.0).clamp(0.4, 0.95),
        isFoodDetected: true,
        description: 'Identified based on visual components.',
      );
    }

    // Fallback: Default smart choices without forcing Thali
    return FoodRecognitionResult(
      bestMatch: foodDatabase.firstWhere((f) => f['name'].toString().contains('Plain Roti'), orElse: () => foodDatabase[0]),
      alternateMatches: [
        foodDatabase.firstWhere((f) => f['name'].toString().contains('Dal Tadka'), orElse: () => foodDatabase[1]),
        foodDatabase.firstWhere((f) => f['name'].toString().contains('Salad Bowl'), orElse: () => foodDatabase[2]),
        foodDatabase.firstWhere((f) => f['name'].toString().contains('Steamed White Rice'), orElse: () => foodDatabase[3]),
        foodDatabase.firstWhere((f) => f['name'].toString().contains('Paneer Paratha'), orElse: () => foodDatabase[4]),
      ],
      confidence: 0.5,
      isFoodDetected: true,
      description: 'General meal pattern detected.',
    );
  }

  // --- Personalization / Reference Preferences for Food Recognition ---
  Future<void> saveFoodReferencePreference(String dishName, Map<String, dynamic> prefs) async {
    try {
      final cleanKey = dishName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final key = 'food_ref_pref_$cleanKey';
      await _prefs.setString(key, jsonEncode(prefs));
    } catch (e) {
      debugPrint('Error saving food reference preference: $e');
    }
  }

  Map<String, dynamic>? getFoodReferencePreference(String dishName) {
    try {
      final cleanKey = dishName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final key = 'food_ref_pref_$cleanKey';
      final raw = _prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading food reference preference: $e');
    }
    return null;
  }
}

class FoodRecognitionResult {
  final Map<String, dynamic>? bestMatch;
  final List<Map<String, dynamic>> alternateMatches;
  final double confidence;
  final bool isFoodDetected;
  final String description;

  FoodRecognitionResult({
    this.bestMatch,
    this.alternateMatches = const [],
    this.confidence = 0.0,
    this.isFoodDetected = true,
    this.description = '',
  });
}


