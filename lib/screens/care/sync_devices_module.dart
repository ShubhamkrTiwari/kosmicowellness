import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../managers/bluetooth_manager.dart';

class SyncDevicesModule extends StatefulWidget {
  const SyncDevicesModule({super.key});

  @override
  State<SyncDevicesModule> createState() => _SyncDevicesModuleState();
}

class _SyncDevicesModuleState extends State<SyncDevicesModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HardwareCategory? _selectedCategoryFilter;

  final List<Map<String, dynamic>> _presetCatalog = [
    {
      'name': 'Dexcom G7 Continuous Glucose',
      'category': HardwareCategory.cgm,
      'icon': Icons.sensors,
      'desc': 'Live 5-min interstitial glucose, customizable rate-of-change alerts & zero fingersticks.',
      'vitals': ['CGM Glucose', 'Trend Vectors', 'Sensor Diagnostics'],
      'brand': 'Dexcom',
    },
    {
      'name': 'Abbott FreeStyle Libre 3',
      'category': HardwareCategory.cgm,
      'icon': Icons.sensors,
      'desc': 'Real-time minute-by-minute streaming, 14-day wear time & continuous telemetry.',
      'vitals': ['CGM Glucose', 'Real-time Sync', '14-Day Lifespan'],
      'brand': 'Abbott',
    },
    {
      'name': 'Medtronic Guardian 4 Sensor',
      'category': HardwareCategory.cgm,
      'icon': Icons.sensors,
      'desc': 'Predictive glucose alerts with SmartGuard auto-correction telemetry integration.',
      'vitals': ['CGM Glucose', 'Predictive Lows', 'Auto Stream'],
      'brand': 'Medtronic',
    },
    {
      'name': 'Kosmico GlucoPatch Pro',
      'category': HardwareCategory.cgm,
      'icon': Icons.sensors,
      'desc': 'Dual-band continuous sensor with clinical 8.2% MARD accuracy.',
      'vitals': ['Live CGM', 'Bluetooth LE', 'Skin Temp'],
      'brand': 'Kosmico Health',
    },
    {
      'name': 'Accu-Chek Guide Glucometer',
      'category': HardwareCategory.glucometer,
      'icon': Icons.bloodtype,
      'desc': 'Bluetooth Smart spill-resistant capillary blood glucose meter with auto-logging.',
      'vitals': ['Capillary Glucose', 'Meal Markers', 'Fast Sync'],
      'brand': 'Roche',
    },
    {
      'name': 'OneTouch Verio Reflect',
      'category': HardwareCategory.glucometer,
      'icon': Icons.bloodtype,
      'desc': 'BloodSugar Mentor insights, glycemic pattern detector & automatic cloud sync.',
      'vitals': ['Blood Glucose', 'Pattern Insight'],
      'brand': 'LifeScan',
    },
    {
      'name': 'Contour Next One',
      'category': HardwareCategory.glucometer,
      'icon': Icons.bloodtype,
      'desc': 'High precision smartlight target range indicator with second-chance sampling.',
      'vitals': ['High Precision Glucose', 'Target Range'],
      'brand': 'Ascensia',
    },
    {
      'name': 'Apple Watch Ultra 2',
      'category': HardwareCategory.smartwatch,
      'icon': Icons.watch,
      'desc': 'Apple HealthKit bridge: ECG, Blood Oxygen, Resting HR & Activity Telemetry.',
      'vitals': ['Heart Rate', 'SpO2', 'Active Calories', 'Steps'],
      'brand': 'Apple',
    },
    {
      'name': 'Samsung Galaxy Watch 6',
      'category': HardwareCategory.smartwatch,
      'icon': Icons.watch,
      'desc': 'BioActive sensor: Blood Pressure (BP), ECG & Body Composition monitoring.',
      'vitals': ['Blood Pressure', 'Heart Rate', 'SpO2', 'Steps'],
      'brand': 'Samsung',
    },
    {
      'name': 'Noise ColorFit Pro 5',
      'category': HardwareCategory.smartwatch,
      'icon': Icons.watch,
      'desc': 'Real-time Optical PPG Blood Pressure, SpO2 & 24/7 Heart Rate monitoring.',
      'vitals': ['Blood Pressure', 'SpO2', 'Heart Rate', 'Steps'],
      'brand': 'Noise',
    },
    {
      'name': 'boAt Wave Elevate',
      'category': HardwareCategory.smartwatch,
      'icon': Icons.watch,
      'desc': 'Advanced health suite: Blood Pressure, Blood Oxygen, Heart Rate & Calorie burn.',
      'vitals': ['Blood Pressure', 'SpO2', 'Heart Rate', 'Steps'],
      'brand': 'boAt',
    },
    {
      'name': 'Fire-Boltt Gladiator',
      'category': HardwareCategory.smartwatch,
      'icon': Icons.watch,
      'desc': 'Continuous biometric tracking, SpO2 pulse oximeter & optical BP estimation.',
      'vitals': ['BP Estimator', 'Heart Rate', 'SpO2', 'Steps'],
      'brand': 'Fire-Boltt',
    },
    {
      'name': 'Fastrack Reflex Play',
      'category': HardwareCategory.smartwatch,
      'icon': Icons.watch,
      'desc': 'Continuous multi-vital tracking, daily step goal telemetry & sleep cycle logs.',
      'vitals': ['Heart Rate', 'SpO2', 'Steps', 'Calories'],
      'brand': 'Fastrack',
    },
    {
      'name': 'Garmin Venu 3',
      'category': HardwareCategory.fitnessTracker,
      'icon': Icons.directions_run,
      'desc': 'Advanced HRV status, Body Battery energy metrics & metabolic pulse rate.',
      'vitals': ['HRV Tracking', 'Heart Rate', 'Respiration', 'Steps'],
      'brand': 'Garmin',
    },
    {
      'name': 'Fitbit Sense 2',
      'category': HardwareCategory.fitnessTracker,
      'icon': Icons.directions_run,
      'desc': 'cEDA continuous stress tracker, skin temperature sensor & SpO2 blood oxygen.',
      'vitals': ['Stress EDA', 'Skin Temp', 'SpO2', 'Steps'],
      'brand': 'Fitbit / Google',
    },
    {
      'name': 'Omron Evolv Wireless BP Monitor',
      'category': HardwareCategory.bloodPressure,
      'icon': Icons.favorite,
      'desc': 'Clinical Grade one-piece upper arm oscillometric blood pressure monitor.',
      'vitals': ['Systolic BP', 'Diastolic BP', 'Pulse Rate'],
      'brand': 'Omron',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    BluetoothManager().init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hardware & Smartwatch Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Auto-Syncing • Bluetooth LE • Real-time Telemetry',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.hub_outlined, size: 20), text: 'Active Hub'),
            Tab(icon: Icon(Icons.bluetooth_searching, size: 20), text: 'BLE Discovery'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: BluetoothManager(),
        builder: (context, _) {
          final bleManager = BluetoothManager();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveHubTab(bleManager, colorScheme, isDark),
              _buildBleDiscoveryTab(bleManager, colorScheme, isDark),
            ],
          );
        },
      ),
    );
  }

  // ================= TAB 1: ACTIVE HARDWARE HUB =================
  Widget _buildActiveHubTab(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    final isConnected = bleManager.isConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-Sync Control Card
          _buildAutoSyncSettingsCard(bleManager, colorScheme, isDark),
          const SizedBox(height: 20),

          // Live Connection Banner
          if (isConnected) ...[
            _buildConnectedDeviceTelemetryCard(bleManager, colorScheme, isDark),
            const SizedBox(height: 20),
            _buildLiveVitalsMatrix(bleManager, colorScheme, isDark),
          ] else ...[
            _buildNoDeviceCard(colorScheme, isDark),
          ],

          const SizedBox(height: 24),
          _buildQuickActionGrid(bleManager, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildAutoSyncSettingsCard(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    final intervals = [
      {'label': '1 min', 'duration': const Duration(minutes: 1)},
      {'label': '5 min', 'duration': const Duration(minutes: 5)},
      {'label': '15 min', 'duration': const Duration(minutes: 15)},
      {'label': '30 min', 'duration': const Duration(minutes: 30)},
      {'label': '1 hr', 'duration': const Duration(hours: 1)},
    ];

    final minutesLeft = bleManager.syncCountdownSeconds ~/ 60;
    final secondsLeft = bleManager.syncCountdownSeconds % 60;
    final countdownStr = '${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.autorenew, color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Continuous Auto-Syncing',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            bleManager.autoSyncEnabled
                                ? 'Next background sync in $countdownStr'
                                : 'Auto-sync is paused',
                            style: TextStyle(
                              fontSize: 11,
                              color: bleManager.autoSyncEnabled ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: bleManager.autoSyncEnabled,
                activeTrackColor: colorScheme.primary,
                onChanged: (val) => bleManager.toggleAutoSync(val),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Sync Frequency:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: intervals.map((item) {
                      final isSelected = bleManager.autoSyncInterval == item['duration'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(item['label'] as String),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              bleManager.setAutoSyncInterval(item['duration'] as Duration);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceTelemetryCard(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    final lastSyncTimeStr = bleManager.lastSyncTime != null
        ? DateFormat('hh:mm:ss a').format(bleManager.lastSyncTime!)
        : 'Just now';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(bleManager.connectedCategory.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bleManager.connectedDeviceName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.greenAccent, width: 0.8),
                                ),
                                child: const Text(
                                  'LIVE STREAM',
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Category: ${bleManager.connectedCategory.label}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.link_off, color: Colors.white70),
                tooltip: 'Disconnect',
                onPressed: () async {
                  await bleManager.disconnect();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device disconnected successfully.')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildDeviceTelemetryChip(
                  icon: Icons.battery_charging_full,
                  label: '${bleManager.latestBatteryLevel ?? 85}%',
                  subtext: 'Battery',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDeviceTelemetryChip(
                  icon: Icons.wifi,
                  label: '${bleManager.deviceRssi ?? -54} dBm',
                  subtext: 'Signal',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDeviceTelemetryChip(
                  icon: Icons.sync,
                  label: lastSyncTimeStr,
                  subtext: 'Last Sync',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final success = await bleManager.syncDataFromDevice();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Live telemetry synced to GlucoRhythm!' : 'Sync failed.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Sync All Hardware Metrics Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTelemetryChip({required IconData icon, required String label, required String subtext}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtext, 
                style: const TextStyle(color: Colors.white60, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveVitalsMatrix(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Multi-Vital Telemetry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildVitalMatrixCard(
              title: 'Continuous Glucose',
              value: '${bleManager.latestGlucose?.toStringAsFixed(0) ?? "--"} mg/dL',
              badge: '${bleManager.glucoseTrend.symbol} ${bleManager.glucoseTrend.label}',
              badgeColor: bleManager.glucoseTrend.color,
              icon: Icons.bloodtype,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
            _buildVitalMatrixCard(
              title: 'Blood Pressure',
              value: bleManager.latestSystolic != null
                  ? '${bleManager.latestSystolic}/${bleManager.latestDiastolic} mmHg'
                  : '--/--',
              badge: bleManager.bloodPressureCategory,
              badgeColor: bleManager.bloodPressureColor,
              icon: Icons.favorite,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
            _buildVitalMatrixCard(
              title: 'Heart Rate & HRV',
              value: '${bleManager.latestHeartRate ?? "--"} BPM',
              badge: 'HRV: ${bleManager.heartRateVariability ?? 52} ms',
              badgeColor: Colors.purple,
              icon: Icons.monitor_heart,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
            _buildVitalMatrixCard(
              title: 'Blood Oxygen (SpO2)',
              value: '${bleManager.latestSpO2 ?? 99} %',
              badge: (bleManager.latestSpO2 ?? 99) >= 95 ? 'Optimal Saturation' : 'Hypoxia Alert',
              badgeColor: (bleManager.latestSpO2 ?? 99) >= 95 ? Colors.green : Colors.red,
              icon: Icons.air,
              colorScheme: colorScheme,
              isDark: isDark,
              onTap: () => _showSpo2SyncDialog(context, bleManager),
            ),
          ],
        ),
      ],
    );
  }

  void _showSpo2SyncDialog(BuildContext context, BluetoothManager bleManager) {
    final controller = TextEditingController(text: '${bleManager.latestSpO2 ?? 99}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.air, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('SpO2 Oxygen Sync', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the live reading shown on your Smartwatch screen (e.g. 99%):',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: '% SpO2',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 70 && val <= 100) {
                bleManager.updateSpo2(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('SpO2 updated to $val% and synced to GlucoRhythm!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalMatrixCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: colorScheme.primary),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDeviceCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bluetooth_searching, size: 40, color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Hardware Device Paired',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pair your Smartwatch, Continuous Glucose Monitor, or fitness tracker to stream real-time biometric vitals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Discover Nearby Devices', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Hardware Actions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.bluetooth_searching,
                label: 'Discover Devices',
                color: colorScheme.primary,
                onTap: () => _tabController.animateTo(1),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.sync,
                label: 'Sync Telemetry',
                color: Colors.green,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final success = await bleManager.syncDataFromDevice();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Live telemetry synced to GlucoRhythm!' : 'Device sync complete.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: BLE DISCOVERY & PAIRING =================
  Widget _buildBleDiscoveryTab(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    final filteredCatalog = _selectedCategoryFilter == null
        ? _presetCatalog
        : _presetCatalog.where((d) => d['category'] == _selectedCategoryFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BLE Scanning Action Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: bleManager.isScanning
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.bluetooth_searching, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bleManager.isScanning ? 'Scanning Bluetooth LE...' : 'Bluetooth GATT Scanner',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bleManager.isScanning
                            ? 'Looking for CGMs, Glucometers, Watches & Trackers'
                            : 'Scan & pair any standard Bluetooth health device',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: bleManager.isScanning
                      ? () => bleManager.stopScan()
                      : () => bleManager.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    bleManager.isScanning ? 'Stop' : 'Scan Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Filters
          const Text('Filter by Hardware Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilterChip('All Devices (${_presetCatalog.length})', null, colorScheme),
                _buildCategoryFilterChip('CGMs', HardwareCategory.cgm, colorScheme),
                _buildCategoryFilterChip('Smartwatches', HardwareCategory.smartwatch, colorScheme),
                _buildCategoryFilterChip('Glucometers (BGM)', HardwareCategory.glucometer, colorScheme),
                _buildCategoryFilterChip('Fitness Bands', HardwareCategory.fitnessTracker, colorScheme),
                _buildCategoryFilterChip('BP Monitors', HardwareCategory.bloodPressure, colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Discovered BLE Devices Section (Real Hardware nearby)
          _buildDiscoveredBleDevicesList(bleManager, colorScheme, isDark),

          // Curated Devices & Preset Catalog
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Hardware Ecosystem & Presets',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Auto-Pairing Enabled',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCatalog.length,
            itemBuilder: (context, index) {
              final device = filteredCatalog[index];
              final isConnected = bleManager.connectedDeviceName == device['name'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isConnected ? Colors.green : colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: isConnected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isConnected ? Colors.green : colorScheme.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        device['icon'] as IconData,
                        color: isConnected ? Colors.green : colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            device['desc'] as String,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (device['vitals'] as List<String>).map((v) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  v,
                                  style: TextStyle(color: colorScheme.primary, fontSize: 9.5, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isConnected)
                      ElevatedButton(
                        onPressed: bleManager.isConnecting
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                await bleManager.connectPresetDevice(
                                  device['name'] as String,
                                  device['category'] as HardwareCategory,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${device['name']} connected! Live vitals streaming.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Pair', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDiscoveredBleDevicesList(BluetoothManager bleManager, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. LIVE OVER-THE-AIR DISCOVERED NEARBY DEVICES (PEHLE SHOW HOGA)
        if (bleManager.scanResults.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Discovered Nearby Devices (${bleManager.scanResults.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE OVER-THE-AIR',
                  style: TextStyle(color: Colors.green, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bleManager.scanResults.length,
            itemBuilder: (context, index) {
              final result = bleManager.scanResults[index];
              final String name = bleManager.resolveDeviceName(result.device, result.advertisementData);
              final bool isThisConnected = bleManager.connectedDevice?.remoteId == result.device.remoteId;
              final bool isSmartwatch = bleManager.isSmartwatchOrHealthDevice(result.device);

              Color rssiColor = Colors.green;
              if (result.rssi < -80) {
                rssiColor = Colors.red;
              } else if (result.rssi < -68) {
                rssiColor = Colors.orange;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : (isSmartwatch ? const Color(0xFFF0FDF4) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isThisConnected 
                        ? Colors.green 
                        : (isSmartwatch ? const Color(0xFF10B981) : colorScheme.primary.withValues(alpha: 0.3)),
                    width: isThisConnected || isSmartwatch ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isThisConnected 
                            ? Colors.green 
                            : (isSmartwatch ? const Color(0xFF10B981) : colorScheme.primary)).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSmartwatch ? Icons.watch : Icons.bluetooth_audio,
                        color: isThisConnected 
                            ? Colors.green 
                            : (isSmartwatch ? const Color(0xFF059669) : colorScheme.primary),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 13.5,
                                    color: isSmartwatch ? const Color(0xFF065F46) : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isThisConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('CONNECTED', style: TextStyle(color: Colors.green, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${result.device.remoteId.str}',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.signal_cellular_alt, size: 12, color: rssiColor),
                              const SizedBox(width: 4),
                              Text(
                                '${result.rssi} dBm',
                                style: TextStyle(color: rssiColor, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isSmartwatch ? '• ⌚ Smartwatch Sensor' : '• BLE Device',
                                  style: TextStyle(
                                    color: isSmartwatch ? const Color(0xFF059669) : Colors.grey, 
                                    fontSize: 10,
                                    fontWeight: isSmartwatch ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isThisConnected)
                      ElevatedButton(
                        onPressed: bleManager.isConnecting
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                final success = await bleManager.connectToDevice(result.device);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? '$name paired & vitals streaming!' : 'Failed to connect to $name.'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSmartwatch ? const Color(0xFF059669) : colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // 2. SCANNING PROGRESS INDICATOR (Displayed when searching)
        if (bleManager.isScanning)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Searching for Nearby Bluetooth Devices...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Make sure your Smartwatch, CGM or Glucometer is ON and within range.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (!bleManager.isScanning && bleManager.scanResults.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap "Scan Now" above to discover physical Smartwatches, CGMs & Health Trackers nearby, or select your model from the Ecosystem presets below.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.3),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilterChip(String label, HardwareCategory? category, ColorScheme colorScheme) {
    final isSelected = _selectedCategoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : Colors.grey,
        ),
        onSelected: (val) {
          setState(() {
            _selectedCategoryFilter = val ? category : null;
          });
        },
      ),
    );
  }
}

