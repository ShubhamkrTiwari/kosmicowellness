import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../managers/care_manager.dart';
import '../../managers/bluetooth_manager.dart';
import 'sync_devices_module.dart';

class TodayModule extends StatefulWidget {
  const TodayModule({super.key});

  @override
  State<TodayModule> createState() => _TodayModuleState();
}

class _TodayModuleState extends State<TodayModule> {
  String _selectedTimeOfDay = 'Day';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _setInitialTimeOfDay();
    BluetoothManager().init();
  }

  void _setInitialTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      _selectedTimeOfDay = 'Dawn';
    } else if (hour >= 11 && hour < 17) {
      _selectedTimeOfDay = 'Day';
    } else if (hour >= 17 && hour < 21) {
      _selectedTimeOfDay = 'Dusk';
    } else {
      _selectedTimeOfDay = 'Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: CareManager(),
      builder: (context, _) {
        final manager = CareManager();
        return RefreshIndicator(
          onRefresh: () => manager.fetchDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayRibbon(colorScheme),
                const SizedBox(height: 20),
                _buildSyncBanner(colorScheme),
                const SizedBox(height: 20),
                _buildLiveHardwareVitalsStrip(colorScheme),
                const SizedBox(height: 20),
                _buildGlucoseCurve(colorScheme, manager),
                const SizedBox(height: 20),
                _buildStatCards(colorScheme, manager),
                const SizedBox(height: 24),
                _buildLifestyleTrackers(colorScheme, manager),
                const SizedBox(height: 24),
                _buildMealMarkers(colorScheme, manager),
                const SizedBox(height: 24),
                _buildMedicationMarkers(colorScheme, manager),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayRibbon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimePeriod('Dawn', Icons.wb_twilight, colorScheme),
          _buildTimePeriod('Day', Icons.wb_sunny_outlined, colorScheme),
          _buildTimePeriod('Dusk', Icons.wb_twilight_outlined, colorScheme),
          _buildTimePeriod('Night', Icons.nightlight_round, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSyncBanner(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: BluetoothManager(),
      builder: (context, _) {
        final bleManager = BluetoothManager();
        final bool isConnected = bleManager.isConnected;
        final String deviceName = bleManager.connectedDeviceName;
        final String vitalsInfo = bleManager.lastVitalsData.isNotEmpty 
            ? 'Live: ${bleManager.lastVitalsData}' 
            : (isConnected ? 'Device Synced & Active' : 'No hardware paired • Tap to pair');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConnected 
                  ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)]
                  : [const Color(0xFF334155), const Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isConnected ? colorScheme.primary : Colors.black).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSyncing ? Icons.sync : (isConnected ? bleManager.connectedCategory.icon : Icons.bluetooth_searching),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SyncDevicesModule()),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isSyncing ? 'Syncing Vitals...' : (isConnected ? deviceName : 'Hardware & CGM Sync'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isConnected) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isSyncing ? 'Extracting biometric telemetry...' : vitalsInfo,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSyncing ? null : () async {
                  if (!isConnected) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SyncDevicesModule()),
                    );
                    return;
                  }
                  setState(() => _isSyncing = true);
                  HapticFeedback.lightImpact();
                  final success = await bleManager.syncDataFromDevice();
                  if (mounted) {
                    setState(() => _isSyncing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Live biometric vitals updated!' : 'Sync failed. Check device.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isConnected ? colorScheme.primary : Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSyncing 
                  ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                  : Text(isConnected ? 'Sync Now' : 'Pair', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveHardwareVitalsStrip(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: BluetoothManager(),
      builder: (context, _) {
        final bleManager = BluetoothManager();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMiniVitalBadge(
                icon: Icons.bloodtype,
                label: 'CGM Glucose',
                value: '${bleManager.latestGlucose?.toStringAsFixed(0) ?? "112"} mg/dL',
                subtext: '${bleManager.glucoseTrend.symbol} ${bleManager.glucoseTrend.label}',
                color: bleManager.glucoseTrend.color,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncDevicesModule()));
                },
              ),
              const SizedBox(width: 10),
              _buildMiniVitalBadge(
                icon: Icons.favorite,
                label: 'Blood Pressure',
                value: bleManager.latestSystolic != null
                    ? '${bleManager.latestSystolic}/${bleManager.latestDiastolic}'
                    : '118/76',
                subtext: bleManager.bloodPressureCategory,
                color: bleManager.bloodPressureColor,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncDevicesModule()));
                },
              ),
              const SizedBox(width: 10),
              _buildMiniVitalBadge(
                icon: Icons.monitor_heart,
                label: 'Heart Rate',
                value: '${bleManager.latestHeartRate ?? 74} BPM',
                subtext: 'HRV ${bleManager.heartRateVariability ?? 52}ms',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncDevicesModule()));
                },
              ),
              const SizedBox(width: 10),
              _buildMiniVitalBadge(
                icon: Icons.air,
                label: 'SpO2 Oxygen',
                value: '${bleManager.latestSpO2 ?? 98}%',
                subtext: 'Optimal',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncDevicesModule()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniVitalBadge({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtext,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTimePeriod(String label, IconData icon, ColorScheme colorScheme) {
    final bool isActive = _selectedTimeOfDay == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeOfDay = label;
        });
      },
      child: Column(
        children: [
          Icon(icon, color: isActive ? colorScheme.primary : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? colorScheme.primary : Colors.grey,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: 4,
              decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  Widget _buildGlucoseCurve(ColorScheme colorScheme, CareManager manager) {
    final bleManager = BluetoothManager();
    final List fullCurve = manager.glucoseCurve;
    final List filteredCurve = fullCurve.where((item) {
      return item is Map && item['timeOfDay'] == _selectedTimeOfDay;
    }).toList();

    final liveGlucose = bleManager.latestGlucose ?? 112.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Continuous Glucose Waveform',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('($_selectedTimeOfDay)', style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: 70 - 180 mg/dL (ADA Standard)',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: bleManager.glucoseStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bleManager.glucoseStatusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${liveGlucose.toStringAsFixed(0)} mg/dL',
                      style: TextStyle(color: bleManager.glucoseStatusColor, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      bleManager.glucoseTrend.symbol,
                      style: TextStyle(color: bleManager.glucoseStatusColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomPaint(
            size: const Size(double.infinity, 120),
            painter: GlucosePainter(colorScheme.primary, filteredCurve.cast<Map<String, dynamic>>()),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('In Target (70-180)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('High (>180)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Low (<70)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(ColorScheme colorScheme, CareManager manager) {
    final tir = manager.timeInRangePercentage.toInt() > 0 ? manager.timeInRangePercentage.toInt() : 82;
    final a1c = manager.estimatedA1C > 0 ? manager.estimatedA1C.toStringAsFixed(1) : '5.8';
    final avg = manager.averageGlucose.toInt() > 0 ? manager.averageGlucose.toInt() : 112;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Time in Range', '$tir%', Icons.check_circle_outline, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Est. A1C', '$a1c%', Icons.analytics_outlined, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Avg Glucose', '$avg', Icons.speed_outlined, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTrackers(ColorScheme colorScheme, CareManager manager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lifestyle Trackers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About Lifestyle Tracking'),
                    content: const Text(
                      'Hydration and stress levels significantly impact blood sugar dynamics. Dehydration can lead to higher glucose concentration, while stress hormones like cortisol can trigger glucose release from the liver.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
                    ],
                  ),
                );
              },
              child: const Text('Why this?', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildHydrationCard(colorScheme, manager)),
            const SizedBox(width: 12),
            Expanded(child: _buildStressCard(colorScheme, manager)),
          ],
        ),
        const SizedBox(height: 12),
        _buildEnergyCard(colorScheme, manager),
      ],
    );
  }

  Widget _buildHydrationCard(ColorScheme colorScheme, CareManager manager) {
    final int water = manager.waterIntake;
    final double progress = (water / 2000).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 20),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Hydration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('$water / 2000 ml', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => manager.addWater(250),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('+250ml', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressCard(ColorScheme colorScheme, CareManager manager) {
    final int level = manager.stressLevel;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, color: Colors.deepPurple, size: 20),
          const SizedBox(height: 12),
          const Text('Stress Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(level == 0 ? 'Not logged' : _getStressLabel(level), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final int l = index + 1;
                final bool isSelected = level == l;
                return GestureDetector(
                  onTap: () => manager.setStressLevel(l),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _getStressEmoji(l),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tap to log', style: TextStyle(fontSize: 8, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildEnergyCard(ColorScheme colorScheme, CareManager manager) {
    final int level = manager.energyLevel;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Energy Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              if (level > 0)
                Text(_getEnergyLabel(level), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final int l = index + 1;
              final bool isSelected = level == l;
              return GestureDetector(
                onTap: () => manager.setEnergyLevel(l),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _getEnergyEmoji(l),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            }),
          ),
          if (level == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Tap to log how you feel', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  String _getEnergyEmoji(int level) {
    switch (level) {
      case 1: return '😴';
      case 2: return '🥱';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '⚡';
      default: return '❓';
    }
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Moderate';
      case 4: return 'High';
      case 5: return 'Very High';
      default: return '';
    }
  }

  String _getStressEmoji(int level) {
    switch (level) {
      case 1: return '😊';
      case 2: return '🙂';
      case 3: return '😐';
      case 4: return '😟';
      case 5: return '😫';
      default: return '❓';
    }
  }

  String _getStressLabel(int level) {
    switch (level) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Moderate';
      case 4: return 'High';
      case 5: return 'Extreme';
      default: return '';
    }
  }

  Widget _buildMealMarkers(ColorScheme colorScheme, CareManager manager) {
    final List? allMeals = manager.mealMarkers;
    final List filteredMeals = (allMeals ?? []).where((m) {
      // Logic for meal time matching ribbon selection
      if (m is! Map) return false;
      final type = m['mealType']?.toString().toLowerCase() ?? '';
      if (_selectedTimeOfDay == 'Dawn' && type == 'breakfast') return true;
      if (_selectedTimeOfDay == 'Day' && type == 'lunch') return true;
      if (_selectedTimeOfDay == 'Dusk' && type == 'snack') return true;
      if (_selectedTimeOfDay == 'Night' && type == 'dinner') return true;
      return false;
    }).toList();

    final bool hasMeals = filteredMeals.length > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meal Markers', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (!hasMeals)
           Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No meals logged for $_selectedTimeOfDay', style: const TextStyle(color: Colors.grey)))),
        if (hasMeals)
          ...filteredMeals.map((m) {
            String timeStr = '--:--';
            try {
              if (m != null && m is Map && m['logTime'] != null) {
                timeStr = m['logTime'].toString().split('T').last.substring(0, 5);
              }
            } catch (_) {}
            
            return _buildMealItem(
              (m is Map ? m['mealType'] : null) ?? 'Meal', 
              timeStr, 
              '${(m is Map ? m['carbs'] : null) ?? 0}g Carbs', 
              Icons.restaurant, 
              colorScheme
            );
          }),
      ],
    );
  }

  Widget _buildMedicationMarkers(ColorScheme colorScheme, CareManager manager) {
    final List<Map<String, dynamic>> meds = manager.medicationLogs;
    final List<Map<String, dynamic>> insulin = manager.insulinLogs;
    
    final bool hasLogs = meds.isNotEmpty || insulin.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medication & Insulin', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (!hasLogs)
           const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No medication logged today', style: TextStyle(color: Colors.grey, fontSize: 12)))),
        if (hasLogs) ...[
          ...meds.map((m) {
            String timeStr = '--:--';
            try {
              timeStr = DateTime.parse(m['time']).toString().split(' ').last.substring(0, 5);
            } catch (_) {}
            return _buildMealItem(m['name'] ?? 'Medication', timeStr, m['dose'] ?? '', Icons.medication, colorScheme);
          }),
          ...insulin.map((i) {
            String timeStr = '--:--';
            try {
              timeStr = DateTime.parse(i['time']).toString().split(' ').last.substring(0, 5);
            } catch (_) {}
            return _buildMealItem('Insulin (${i['timeOfDay']})', timeStr, '${i['units']} units', Icons.colorize, colorScheme);
          }),
        ],
      ],
    );
  }

  Widget _buildMealItem(String title, String time, String detail, IconData icon, ColorScheme colorScheme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(time, style: const TextStyle(fontSize: 12)),
      trailing: Text(detail, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class DeviceManagementSheet extends StatefulWidget {
  final CareManager manager;
  const DeviceManagementSheet({super.key, required this.manager});

  @override
  State<DeviceManagementSheet> createState() => _DeviceManagementSheetState();
}

class _DeviceManagementSheetState extends State<DeviceManagementSheet> {
  int _selectedTab = 0; // 0: Live BLE Scanner, 1: Popular Smartwatches

  @override
  void initState() {
    super.initState();
    BluetoothManager().init();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bleManager = BluetoothManager();

    return ListenableBuilder(
      listenable: bleManager,
      builder: (context, _) {
        final bool isConnected = bleManager.isConnected;
        final bool isScanning = bleManager.isScanning;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bluetooth Device Center', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Scan & connect real smartwatches & sensors', 
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Active Connected Device Card
              if (isConnected) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.bluetooth_connected, color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bleManager.connectedDeviceName, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    bleManager.lastVitalsData.isNotEmpty 
                                        ? 'Live Telemetry: ${bleManager.lastVitalsData}' 
                                        : 'Connected • Stream Active',
                                    style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => bleManager.disconnect(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(0, 30),
                              ),
                              child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLiveVitalBadge(
                                'Glucose',
                                bleManager.latestGlucose != null ? '${bleManager.latestGlucose!.toStringAsFixed(0)} mg/dL' : '--',
                                Icons.bloodtype_outlined,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildLiveVitalBadge(
                                'Heart Rate',
                                bleManager.latestHeartRate != null ? '${bleManager.latestHeartRate} BPM' : '--',
                                Icons.favorite_outline,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildLiveVitalBadge(
                                'Battery',
                                bleManager.latestBatteryLevel != null ? '${bleManager.latestBatteryLevel}%' : '92%',
                                Icons.battery_charging_full,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Custom Segmented Switch: Live BLE vs Popular Smartwatches
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bluetooth_searching, size: 16, color: _selectedTab == 0 ? Colors.white : colorScheme.onSurface),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live BLE Scanner',
                                    style: TextStyle(
                                      color: _selectedTab == 0 ? Colors.white : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.watch, size: 16, color: _selectedTab == 1 ? Colors.white : colorScheme.onSurface),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Popular Smartwatches',
                                    style: TextStyle(
                                      color: _selectedTab == 1 ? Colors.white : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Tab View
              if (_selectedTab == 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? () => bleManager.stopScan() : () => bleManager.startScan(),
                    icon: isScanning 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.radar, size: 18),
                    label: Text(isScanning ? 'Scanning for Smartwatches (Stop)...' : 'Scan for Nearby Bluetooth Devices'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isScanning ? Colors.orange[800] : colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildRealScanResults(bleManager, colorScheme),
                ),
              ] else ...[
                Expanded(
                  child: _buildPresetDevicesList(bleManager, colorScheme),
                ),
              ],

              // Done Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveVitalBadge(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value, 
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealScanResults(BluetoothManager bleManager, ColorScheme colorScheme) {
    if (bleManager.isScanning && bleManager.scanResults.isEmpty && bleManager.bondedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bluetooth_searching, size: 48, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text('Searching for Nearby Smartwatches...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Make sure your smartwatch Bluetooth is discoverable', style: TextStyle(color: Colors.grey, fontSize: 11.5)),
            const SizedBox(height: 20),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      );
    }

    if (!bleManager.isScanning && bleManager.scanResults.isEmpty && bleManager.bondedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.watch_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No Bluetooth Devices Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tap "Scan for Nearby Bluetooth Devices" above to scan for your smartwatch, fitness tracker, or glucometer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // 1. Bonded / Paired System Devices (e.g. Abhay's Wave Beat Call)
        if (bleManager.bondedDevices.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.bluetooth_connected, color: Colors.blueAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'Paired on this Phone (Tap to Connect):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bleManager.bondedDevices.map((device) {
            final String name = bleManager.resolveDeviceName(device);
            final bool isConnected = bleManager.connectedDevice?.remoteId == device.remoteId;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isConnected ? Colors.green : Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isConnected ? Colors.green : Colors.blueAccent).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.watch, color: isConnected ? Colors.green : Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${device.remoteId.str}',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Paired', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                    )
                  else
                    ElevatedButton(
                      onPressed: bleManager.isConnecting
                          ? null
                          : () async {
                              final success = await bleManager.connectToDevice(device);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? '$name connected! Live vitals updated.' : 'Failed to connect.'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // 2. Over-The-Air Scan Results
        if (bleManager.scanResults.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.radar, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Discovered Devices Nearby:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...bleManager.scanResults.map((result) {
            final int rssi = result.rssi;
            final bool isThisConnected = bleManager.connectedDevice?.remoteId == result.device.remoteId;
            final String name = bleManager.resolveDeviceName(result.device, result.advertisementData);

            Color rssiColor = rssi > -70 ? Colors.green : (rssi > -85 ? Colors.orange : Colors.red);
            String signalText = rssi >= -70 ? 'Strong' : (rssi >= -85 ? 'Medium' : 'Weak');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isThisConnected ? Colors.green : Colors.transparent),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isThisConnected ? Colors.green : colorScheme.primary).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bluetooth, color: isThisConnected ? Colors.green : colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                result.device.remoteId.str, 
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$signalText ($rssi dBm)',
                                style: TextStyle(color: rssiColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isThisConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Paired', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                    )
                  else
                    ElevatedButton(
                      onPressed: bleManager.isConnecting
                          ? null
                          : () async {
                              final success = await bleManager.connectToDevice(result.device);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? '$name connected! Live vitals synced.' : 'Failed to connect.'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Pair', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPresetDevicesList(BluetoothManager bleManager, ColorScheme colorScheme) {
    final List<Map<String, dynamic>> presets = [
      {'name': 'Samsung Galaxy Watch 6', 'category': HardwareCategory.smartwatch, 'icon': Icons.watch, 'desc': 'Blood Pressure (BP), ECG & BioActive PPG'},
      {'name': 'Noise ColorFit Pro 5', 'category': HardwareCategory.smartwatch, 'icon': Icons.watch, 'desc': 'Real-time Blood Pressure, SpO2 & Heart Rate'},
      {'name': 'boAt Wave Elevate', 'category': HardwareCategory.smartwatch, 'icon': Icons.watch, 'desc': 'BP Monitor, SpO2, Heart Rate & Step Tracker'},
      {'name': 'Fire-Boltt Gladiator', 'category': HardwareCategory.smartwatch, 'icon': Icons.watch, 'desc': 'Blood Pressure, SpO2 & 24/7 Optical Heart Rate'},
      {'name': 'Apple Watch Ultra 2', 'category': HardwareCategory.smartwatch, 'icon': Icons.watch, 'desc': 'ECG, Blood Oxygen, Active Vitals & Glucose Sync'},
      {'name': 'Fitbit Sense 2', 'category': HardwareCategory.fitnessTracker, 'icon': Icons.watch, 'desc': 'EDA Stress, SpO2 & Skin Temperature'},
      {'name': 'Fastrack Reflex Play', 'category': HardwareCategory.smartwatch, 'icon': Icons.watch, 'desc': 'BP Vitals, SpO2 & Daily Calorie Tracker'},
      {'name': 'Garmin Venu 3', 'category': HardwareCategory.fitnessTracker, 'icon': Icons.watch, 'desc': 'Advanced HRV, Body Battery & Metabolic Pulse'},
      {'name': 'Omron HeartGuide BP Watch', 'category': HardwareCategory.bloodPressure, 'icon': Icons.favorite, 'desc': 'Clinical Inflatable Cuff Blood Pressure (BP)'},
      {'name': 'Dexcom G7 Continuous Glucose', 'category': HardwareCategory.cgm, 'icon': Icons.sensors, 'desc': 'Live 5-Min Subcutaneous Glucose CGM'},
      {'name': 'Abbott FreeStyle Libre 3', 'category': HardwareCategory.cgm, 'icon': Icons.sensors, 'desc': 'Real-time minute streaming & NFC tap sync'},
      {'name': 'Accu-Chek Guide Glucometer', 'category': HardwareCategory.glucometer, 'icon': Icons.bloodtype, 'desc': 'Wireless Capillary Blood Glucose'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final item = presets[index];
        final bool isConnected = bleManager.connectedDeviceName == item['name'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isConnected ? Colors.green : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isConnected ? Colors.green : colorScheme.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: isConnected ? Colors.green : colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(item['desc'] as String, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Paired', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    await bleManager.connectPresetDevice(item['name'] as String, item['category'] as HardwareCategory);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item['name']} paired & live vitals updated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pair', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class GlucosePainter extends CustomPainter {
  final Color color;
  final List<Map<String, dynamic>> curve;
  GlucosePainter(this.color, this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Target Corridor Range Shading (70 - 180 mg/dL)
    final double yTargetTop = (size.height - ((180 - 40) / 180) * size.height).clamp(0.0, size.height);
    final double yTargetBottom = (size.height - ((70 - 40) / 180) * size.height).clamp(0.0, size.height);

    final rangePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, yTargetTop, size.width, yTargetBottom),
        const Radius.circular(8),
      ),
      rangePaint,
    );

    // Target boundary guideline lines
    final linePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, yTargetTop), Offset(size.width, yTargetTop), linePaint);
    canvas.drawLine(Offset(0, yTargetBottom), Offset(size.width, yTargetBottom), linePaint);

    // 2. Waveform Spline
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final bool hasData = curve.isNotEmpty;
    
    if (!hasData) {
      path.moveTo(0, size.height * 0.55);
      path.quadraticBezierTo(size.width * 0.25, size.height * 0.35, size.width * 0.5, size.height * 0.48);
      path.quadraticBezierTo(size.width * 0.75, size.height * 0.65, size.width, size.height * 0.42);
    } else {
      for (int i = 0; i < curve.length; i++) {
        final double x = (size.width / (curve.length == 1 ? 1 : curve.length - 1)) * i;
        final dynamic rawVal = curve[i]['level'];
        final double val = double.tryParse(rawVal?.toString() ?? '110') ?? 110.0;
        
        double y = size.height - ((val - 40) / 180) * size.height;
        y = y.clamp(0, size.height);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = (size.width / (curve.length == 1 ? 1 : curve.length - 1)) * (i - 1);
          final dynamic prevRaw = curve[i - 1]['level'];
          final double prevVal = double.tryParse(prevRaw?.toString() ?? '110') ?? 110.0;
          double prevY = (size.height - ((prevVal - 40) / 180) * size.height).clamp(0.0, size.height);

          final controlX = (prevX + x) / 2;
          path.cubicTo(controlX, prevY, controlX, y, x, y);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
