import 'package:flutter_test/flutter_test.dart';
import 'package:kosmico/managers/bluetooth_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BluetoothManager Hardware & CGM Sync Tests', () {
    late BluetoothManager manager;

    setUp(() {
      manager = BluetoothManager();
    });

    test('Initial telemetry state and default vitals', () {
      expect(manager.latestGlucose, isNotNull);
      expect(manager.latestHeartRate, isNotNull);
      expect(manager.latestSystolic, isNotNull);
      expect(manager.latestDiastolic, isNotNull);
      expect(manager.latestSpO2, isNotNull);
      expect(manager.bloodPressureCategory, isNotEmpty);
      expect(manager.glucoseStatusLabel, isNotEmpty);
    });

    test('Auto-sync intervals configuration', () {
      expect(manager.autoSyncEnabled, isTrue);
      manager.setAutoSyncInterval(const Duration(minutes: 15));
      expect(manager.autoSyncInterval, const Duration(minutes: 15));
      expect(manager.syncCountdownSeconds, 900);

      manager.toggleAutoSync(false);
      expect(manager.autoSyncEnabled, isFalse);
    });

    test('Preset Device Connection and Telemetry update', () async {
      await manager.connectPresetDevice('Dexcom G7 Continuous Glucose', HardwareCategory.cgm);
      expect(manager.isConnected, isTrue);
      expect(manager.connectedDeviceName, 'Dexcom G7 Continuous Glucose');
      expect(manager.connectedCategory, HardwareCategory.cgm);
      expect(manager.latestBatteryLevel, isNotNull);
      expect(manager.deviceRssi, isNotNull);
      expect(manager.sensorDaysRemaining, greaterThan(0));
    });

    test('One-Tap NFC CGM Sensor Scanning and History Buffer extraction', () async {
      final result = await manager.scanNfcSensor();
      expect(result['success'], isTrue);
      expect(result['glucose'], greaterThan(50));
      expect(result['daysRemaining'], greaterThan(0));
      expect(manager.nfcHistoryBuffer.length, 33); // 32 historical points + 1 live
      expect(manager.sensorSerial.startsWith('LIBRE-'), isTrue);
    });

    test('2-Point CGM Sensor Calibration', () async {
      final double fingerstickValue = 125.0;
      final success = await manager.calibrateSensor(fingerstickValue);
      expect(success, isTrue);
      expect(manager.latestGlucose, fingerstickValue);
      expect(manager.lastCalibrationTime, isNotNull);
      expect(manager.sensorMARD, 7.8);
    });

    test('Blood pressure classification helper', () {
      expect(manager.bloodPressureCategory, isNotEmpty);
      expect(manager.bloodPressureColor, isNotNull);
    });

    test('Disconnection resets device state correctly', () async {
      await manager.disconnect();
      expect(manager.connectedDevice, isNull);
      expect(manager.connectedDeviceName, 'No device connected');
    });
  });
}
