import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'care_manager.dart';

enum SensorStatus { idle, unsupported, permissionRequired, permanentlyDenied, running, error }

/// Live footstep counter built on the device pedometer sensor.
///
/// Android streams the hardware step counter (cumulative since boot) and iOS
/// streams CMPedometer updates. We persist the last raw counter per day so
/// steps taken while the app was closed are still credited on next launch.
/// On unsupported platforms (web/desktop/emulators without a sensor) the UI
/// falls back to manual step logging.
class StepCounterManager extends ChangeNotifier {
  static final StepCounterManager _instance = StepCounterManager._internal();
  factory StepCounterManager() => _instance;
  StepCounterManager._internal();

  static const String _counterKey = 'ped_last_counter';
  static const String _counterDateKey = 'ped_last_counter_date';

  StreamSubscription<StepCount>? _stepSub;
  SharedPreferences? _prefs;
  SensorStatus _status = SensorStatus.idle;
  int _lastCounter = 0;
  bool _hasBaseline = false;
  String _lastError = '';

  SensorStatus get status => _status;
  String get lastError => _lastError;
  bool get isRunning => _status == SensorStatus.running;
  bool get isPlatformSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Requests required permissions and starts streaming footstep counts.
  Future<void> start() async {
    if (!isPlatformSupported) {
      _setStatus(SensorStatus.unsupported);
      return;
    }
    if (_status == SensorStatus.running) return;

    if (Platform.isAndroid && await _needsActivityPermission()) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _stepSub?.cancel();
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (Object e) {
          _lastError = e.toString();
          _setStatus(SensorStatus.error);
        },
      );
      _setStatus(SensorStatus.running);
    } on PlatformException catch (e) {
      _lastError = e.message ?? e.code;
      _setStatus(SensorStatus.error);
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SensorStatus.error);
    }
  }

  void stop() {
    _stepSub?.cancel();
    _stepSub = null;
    _hasBaseline = false;
    _setStatus(SensorStatus.idle);
  }

  Future<bool> _needsActivityPermission() async {
    // ACTIVITY_RECOGNITION is only enforced on Android 10 (API 29)+;
    // permission_handler reports granted below that.
    var status = await Permission.activityRecognition.status;
    if (status.isGranted) return false;
    if (status.isPermanentlyDenied) {
      _setStatus(SensorStatus.permanentlyDenied);
      return true;
    }
    status = await Permission.activityRecognition.request();
    if (status.isGranted) return false;
    _setStatus(status.isPermanentlyDenied ? SensorStatus.permanentlyDenied : SensorStatus.permissionRequired);
    return true;
  }

  void _onStepCount(StepCount event) {
    final int counter = event.steps;
    final String today = DateTime.now().toString().split(' ')[0];
    final prefs = _prefs;

    if (!_hasBaseline) {
      _hasBaseline = true;
      if (prefs != null && prefs.getString(_counterDateKey) == today) {
        // Same day: resume from the persisted counter so steps taken while the
        // app was terminated are credited as a delta.
        _lastCounter = prefs.getInt(_counterKey) ?? counter;
        final int delta = counter - _lastCounter;
        if (delta > 0) CareManager().addSteps(delta);
      } else {
        _lastCounter = counter;
        prefs?.setString(_counterDateKey, today);
      }
      prefs?.setInt(_counterKey, counter);
      return;
    }

    int delta = counter - _lastCounter;
    if (delta < 0) delta = 0; // Device rebooted: hardware counter reset.
    _lastCounter = counter;
    prefs?.setString(_counterDateKey, today);
    prefs?.setInt(_counterKey, counter);
    if (delta > 0) CareManager().addSteps(delta);
  }

  void _setStatus(SensorStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }
}
