import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../managers/care_manager.dart';
import '../../managers/step_counter_manager.dart';

/// Footstep counter hub. Steps drive two linked trackers:
///  • Smart Hydration — daily water goal grows with step count.
///  • Food vs Burn — carb load of today's meals converted to the steps
///    needed to offset it (post-meal walk guidance for glucose control).
class ActivityModule extends StatefulWidget {
  const ActivityModule({super.key});

  @override
  State<ActivityModule> createState() => _ActivityModuleState();
}

class _ActivityModuleState extends State<ActivityModule> {
  static const List<int> _goalOptions = [5000, 7500, 10000, 12500, 15000];

  /// Comma-groups an integer for display (e.g. 12500 -> "12,500").
  String _grp(num value) {
    final String s = (value.isFinite ? value.round() : 0).toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    // Auto-start the live pedometer; permission prompt happens inside start().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StepCounterManager().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([CareManager(), StepCounterManager()]),
      builder: (context, _) {
        final manager = CareManager();
        final sensor = StepCounterManager();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSensorBanner(colorScheme, sensor),
              const SizedBox(height: 16),
              _buildStepDashboard(colorScheme, manager),
              const SizedBox(height: 16),
              _buildManualAddCard(colorScheme, manager),
              const SizedBox(height: 16),
              _buildStepHistorySection(colorScheme, manager),
              const SizedBox(height: 24),
              _buildSectionHeader('Smart Hydration', Icons.water_drop,
                  'Your water target adapts to today\u2019s activity: +150 ml per 1,000 steps', colorScheme),
              const SizedBox(height: 12),
              _buildHydrationCard(colorScheme, manager),
              const SizedBox(height: 24),
              _buildSectionHeader('Food vs Burn', Icons.local_fire_department,
                  'Steps needed to offset today\u2019s logged carbohydrate load', colorScheme),
              const SizedBox(height: 12),
              _buildFoodBalanceCard(colorScheme, manager),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ---------- Sensor status ----------

  Widget _buildSensorBanner(ColorScheme colorScheme, StepCounterManager sensor) {
    IconData icon;
    Color color;
    String message;
    String? actionLabel;
    VoidCallback? action;

    switch (sensor.status) {
      case SensorStatus.running:
        icon = Icons.sensors;
        color = Colors.green;
        message = 'Live step sensor active \u2014 footsteps are counted automatically.';
      case SensorStatus.unsupported:
        icon = Icons.sensors_off;
        color = Colors.grey;
        message = 'No step sensor on this device. Use manual logging below to track steps.';
      case SensorStatus.permissionRequired:
        icon = Icons.lock_outline;
        color = Colors.orange;
        message = 'Activity recognition permission is required to read the step counter.';
        actionLabel = 'Grant Permission';
        action = () => sensor.start();
      case SensorStatus.permanentlyDenied:
        icon = Icons.error_outline;
        color = Colors.red;
        message = 'Activity permission was permanently denied. Enable it in app settings.';
        actionLabel = 'Open App Settings';
        action = () => openAppSettings();
      case SensorStatus.error:
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        message = 'Step sensor error: ${sensor.lastError}';
        actionLabel = 'Retry';
        action = () => sensor.start();
      case SensorStatus.idle:
        icon = Icons.directions_walk;
        color = colorScheme.primary;
        message = 'Footstep counter is paused. Start it to track steps live.';
        actionLabel = 'Start Live Counter';
        action = () => sensor.start();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12, height: 1.3)),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: action,
              child: Text(actionLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Step dashboard ----------

  Widget _buildStepDashboard(ColorScheme colorScheme, CareManager manager) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary.withValues(alpha: 0.08), colorScheme.primary.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStepRing(manager),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today\u2019s Steps', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _grp(manager.stepsToday),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30, color: colorScheme.primary),
                    ),
                    Text('Goal: ${_grp(manager.stepGoal)} steps', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _goalOptions.map((goal) {
                        final bool selected = manager.stepGoal == goal;
                        return GestureDetector(
                          onTap: () => manager.setStepGoal(goal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected ? colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? colorScheme.primary : Colors.grey.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${goal >= 1000 ? '${(goal / 1000).toStringAsFixed(goal % 1000 == 0 ? 0 : 1)}k' : goal}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildActivityStat(Icons.route, 'Distance', '${manager.distanceKm.toStringAsFixed(2)} km', Colors.blue, colorScheme),
              _buildActivityStat(Icons.local_fire_department, 'Burned', '${manager.caloriesBurned.toStringAsFixed(0)} kcal', Colors.deepOrange, colorScheme),
              _buildActivityStat(Icons.timelapse, 'Active', '${manager.activeMinutes} min', Colors.teal, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepRing(CareManager manager) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 110,
      height: 110,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: manager.stepProgress),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(progress: value, color: colorScheme.primary),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text('of goal', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat(IconData icon, String label, String value, Color color, ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  // ---------- Manual step logging ----------

  Widget _buildManualAddCard(ColorScheme colorScheme, CareManager manager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Add Steps (Manual)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Walked without your phone or sensor unavailable? Log footsteps now or after your run.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [500, 1000, 2500, 5000].map((amount) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: amount == 5000 ? 0 : 8),
                  child: OutlinedButton(
                    onPressed: () => manager.addSteps(amount),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('+${_grp(amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Step History (Today to Last Week) ----------

  Widget _buildStepHistorySection(ColorScheme colorScheme, CareManager manager) {
    final weeklyHistory = manager.getWeeklyStepHistory();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: Color(0xFF0D5C46), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Step History (Today – Last Week)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D5C46)),
                  ),
                ],
              ),
              Text(
                'Goal: ${_grp(manager.stepGoal)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weeklyHistory.map((entry) {
                final int steps = entry['steps'];
                final String day = entry['day'];
                final double progress = entry['progress'];
                final bool isToday = day == 'Today';
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          steps > 0 ? (steps >= 1000 ? '${(steps / 1000).toStringAsFixed(1)}k' : '$steps') : '0',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? colorScheme.primary : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              FractionallySizedBox(
                                heightFactor: progress.clamp(0.05, 1.0),
                                child: Container(
                                  width: 14,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isToday
                                          ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)]
                                          : [Colors.teal[300]!, Colors.teal[700]!],
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? colorScheme.primary : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Smart hydration (linked to steps) ----------

  Widget _buildHydrationCard(ColorScheme colorScheme, CareManager manager) {
    final int water = manager.waterIntake;
    final int goal = manager.waterGoal;
    final double progress = manager.hydrationProgress;
    final int deficit = goal - water;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Water Intake', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$water ml', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.blue)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('/ $goal ml target', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              if (goal > 2000) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('+${goal - 2000} ml activity bonus', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          if (deficit > 0)
            Text(
              'You need ${deficit}ml more to stay hydrated at your current activity level.',
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
            )
          else
            const Text('Hydration target met for today\u2019s activity level. Great job! \u{1F4AA}',
                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildWaterChip('Glass 200ml', Icons.local_cafe, 200, colorScheme),
              const SizedBox(width: 8),
              _buildWaterChip('Bottle 500ml', Icons.local_drink_outlined, 500, colorScheme),
              const SizedBox(width: 8),
              _buildWaterChip('Large 750ml', Icons.local_drink, 750, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterChip(String label, IconData icon, int amount, ColorScheme colorScheme) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => CareManager().addWater(amount),
        icon: Icon(icon, size: 14, color: Colors.blue),
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ---------- Food vs burn (linked to steps + meal intake) ----------

  Widget _buildFoodBalanceCard(ColorScheme colorScheme, CareManager manager) {
    final String today = DateTime.now().toString().split(' ')[0];
    final List<Map<String, dynamic>> todaysMeals = manager.mealMarkers
        .where((m) => (m['logTime'] ?? '').toString().startsWith(today))
        .toList();

    double totalCarbs = 0;
    for (final meal in todaysMeals) {
      final double carbs = double.tryParse((meal['carbs'] ?? 0).toString()) ?? 0;
      totalCarbs += carbs.isFinite ? carbs : 0;
    }
    final double carbKcal = totalCarbs * 4; // 4 kcal per gram of carbohydrate
    final double stepsToBurn = carbKcal / 0.04; // ~0.04 kcal burned per step
    final double balanceProgress = stepsToBurn <= 0 ? 0.0 : (manager.stepsToday / stepsToBurn).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todaysMeals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No meals logged today. Log meals in Scan Meal or Log Entry, and your post-meal walk targets will appear here.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${totalCarbs.toStringAsFixed(0)}g', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.deepOrange)),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Text('carbs today', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const Spacer(),
                Text('${carbKcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              stepsToBurn <= 0
                  ? 'Walk targets appear once carbs are logged.'
                  : 'Walk ${_grp(stepsToBurn.round())} steps today to fully offset your carb load (~100 steps per gram).',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: balanceProgress,
                backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_grp(manager.stepsToday)} / ${_grp(stepsToBurn.round())} steps',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ...todaysMeals.map((meal) {
              final parsedCarbs = double.tryParse((meal['carbs'] ?? 0).toString()) ?? 0;
              final carbs = parsedCarbs.isFinite ? parsedCarbs : 0;
              final walkSteps = (carbs * 100).round();
              final time = (meal['logTime'] ?? '').toString().split('T').last;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${meal['mealType'] ?? 'Meal'} \u2022 ${carbs.toStringAsFixed(0)}g carbs \u2022 ${time.length >= 5 ? time.substring(0, 5) : ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Walk ${_grp(walkSteps)} steps',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A 10\u201315 min post-meal walk blunts glucose spikes by improving insulin sensitivity \u2014 aim for ~1,200 steps after each meal.',
                    style: TextStyle(fontSize: 10.5, color: Colors.green, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ),
      ],
    );
  }
}

/// Simple circular progress ring for step goal completion.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = -1.5 * 3.141592653589793; // -90 degrees
    final sweepAngle = 2 * 3.141592653589793 * progress;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, 2 * 3.141592653589793, false, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
