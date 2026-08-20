import 'package:flutter/material.dart';
import 'dart:async';
import '../../managers/care_manager.dart';

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
                const SizedBox(height: 24),
                _buildSyncBanner(colorScheme),
                const SizedBox(height: 24),
                _buildGlucoseCurve(colorScheme, manager),
                const SizedBox(height: 24),
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
    final manager = CareManager();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_isSyncing ? Icons.sync : Icons.bluetooth_searching, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _showDeviceManagement(context, manager),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isSyncing ? 'Syncing Vitals...' : 'Device Sync Active', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_isSyncing ? 'Fetching latest data...' : 'Connected: ${manager.connectedDeviceName}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSyncing ? null : () async {
              if (manager.devices.where((d) => d['connected']).isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please connect a device first.')));
                _showDeviceManagement(context, manager);
                return;
              }
              setState(() => _isSyncing = true);
              final success = await manager.simulateDeviceSync();
              if (mounted) {
                setState(() => _isSyncing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Vitals successfully synced from device!' : 'Sync failed. Please check device connection.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 30),
            ),
            child: _isSyncing 
              ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
              : const Text('Sync Now', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  void _showDeviceManagement(BuildContext context, CareManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeviceManagementSheet(manager: manager),
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
    // Filter curve data based on selected time of day
    final List fullCurve = manager.glucoseCurve;
    final List filteredCurve = fullCurve.where((item) {
      return item is Map && item['timeOfDay'] == _selectedTimeOfDay;
    }).toList();

    final bool hasData = filteredCurve.isNotEmpty;
    
    String lastReadingValue = '--';
    if (hasData) {
      try {
        final last = filteredCurve.last;
        if (last != null && last is Map && last['level'] != null) {
          lastReadingValue = last['level'].toString();
        }
      } catch (_) {}
    }
    
    final String lastReading = '$lastReadingValue mg/dL';

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Glucose Curve ($_selectedTimeOfDay)', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(lastReading, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          CustomPaint(
            size: const Size(double.infinity, 120),
            painter: GlucosePainter(colorScheme.primary, filteredCurve.cast<Map<String, dynamic>>()),
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Real-time sync active', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(ColorScheme colorScheme, CareManager manager) {
    final tir = manager.timeInRangePercentage.toInt();
    final a1c = manager.estimatedA1C.toStringAsFixed(1);
    final avg = manager.averageGlucose.toInt();

    return Row(
      children: [
        Expanded(child: _buildStatCard('Time in Range', '$tir%', Icons.check_circle_outline, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Est. A1C', '$a1c%', Icons.analytics_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Avg Glucose', '$avg', Icons.speed_outlined, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

class _DeviceManagementSheet extends StatefulWidget {
  final CareManager manager;
  const _DeviceManagementSheet({required this.manager});

  @override
  State<_DeviceManagementSheet> createState() => _DeviceManagementSheetState();
}

class _DeviceManagementSheetState extends State<_DeviceManagementSheet> {
  bool _isScanning = false;
  int? _pairingIndex;

  void _startScan(int index) {
    setState(() {
      _isScanning = true;
      _pairingIndex = index;
    });

    // Simulate discovering multiple signals
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void _confirmPairing(int index) {
    setState(() => _pairingIndex = null);
    widget.manager.setPairing(index, true);
    
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.manager.setPairing(index, false);
        widget.manager.toggleDeviceConnection(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.manager.devices[index]['name']} Paired Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Bluetooth Device Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Scan and pair your health hardware', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          
          if (_isScanning)
             _buildScanningView(colorScheme)
          else if (_pairingIndex != null)
             _buildFoundDeviceView(colorScheme, _pairingIndex!)
          else
            Expanded(
              child: ListenableBuilder(
                listenable: widget.manager,
                builder: (context, _) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.manager.devices.length,
                  itemBuilder: (context, index) {
                    final device = widget.manager.devices[index];
                    final bool connected = device['connected'];
                    final bool pairing = device['isPairing'] ?? false;
                    final String? lastData = device['lastData'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: connected ? colorScheme.primary : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(device['icon'], color: connected ? colorScheme.primary : Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (pairing)
                                  const Text('Pairing...', style: TextStyle(fontSize: 10, color: Colors.blue, fontStyle: FontStyle.italic))
                                else if (connected)
                                  Text('Connected • Live: ${lastData ?? 'Syncing...'}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))
                                else
                                  const Text('Disconnected', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          if (pairing)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            Switch(
                              value: connected,
                              onChanged: (val) {
                                if (val) {
                                  _startScan(index);
                                } else {
                                  widget.manager.toggleDeviceConnection(index);
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          
          if (!_isScanning && _pairingIndex == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => _startScan(widget.manager.devices.length - 2), // Simulate generic scan
                icon: const Icon(Icons.refresh),
                label: const Text('Search for Other Smartwatches'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView(ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_searching, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text('Searching for nearby devices...', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ensure your device is in pairing mode', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildFoundDeviceView(ColorScheme colorScheme, int index) {
    final device = widget.manager.devices[index];
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Devices Found:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(device['icon'], color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(child: Text(device['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  ElevatedButton(
                    onPressed: () => _confirmPairing(index),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('Pair'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _pairingIndex = null),
                child: const Text('Cancel Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlucosePainter extends CustomPainter {
  final Color color;
  final List<Map<String, dynamic>> curve;
  GlucosePainter(this.color, this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final bool hasData = curve.isNotEmpty;
    
    if (!hasData) {
      path.moveTo(0, size.height * 0.6);
      path.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.5);
      path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.4);
    } else {
      for (int i = 0; i < curve.length; i++) {
        final double x = (size.width / (curve.length == 1 ? 1 : curve.length - 1)) * i;
        final dynamic rawVal = curve[i]['level'];
        final double val = double.tryParse(rawVal?.toString() ?? '0') ?? 0.0;
        
        double y = size.height - ((val - 40) / 160) * size.height;
        y = y.clamp(0, size.height);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, paint);

    final rangePaint = Paint()..color = color.withValues(alpha: 0.05);
    double yTop = size.height - ((140 - 40) / 160) * size.height;
    double yBottom = size.height - ((70 - 40) / 160) * size.height;
    canvas.drawRect(Rect.fromLTRB(0, yTop, size.width, yBottom), rangePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
