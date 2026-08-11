import 'package:flutter/material.dart';
import '../../managers/care_manager.dart';

class TodayModule extends StatefulWidget {
  const TodayModule({super.key});

  @override
  State<TodayModule> createState() => _TodayModuleState();
}

class _TodayModuleState extends State<TodayModule> {
  String _selectedTimeOfDay = 'Day';

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
                _buildGlucoseCurve(colorScheme, manager),
                const SizedBox(height: 24),
                _buildStatCards(colorScheme, manager),
                const SizedBox(height: 24),
                _buildMealMarkers(colorScheme, manager),
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
    final List? fullCurve = manager.glucoseCurve;
    final List filteredCurve = (fullCurve ?? []).where((item) {
      return item is Map && item['timeOfDay'] == _selectedTimeOfDay;
    }).toList();

    final bool hasData = filteredCurve.length > 0;
    
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
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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

  Widget _buildMealItem(String title, String time, String detail, IconData icon, ColorScheme colorScheme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(time, style: const TextStyle(fontSize: 12)),
      trailing: Text(detail, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
      contentPadding: EdgeInsets.zero,
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
    final bool hasData = curve != null && curve.length > 0;
    
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
        
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final rangePaint = Paint()..color = color.withOpacity(0.05);
    double yTop = size.height - ((140 - 40) / 160) * size.height;
    double yBottom = size.height - ((70 - 40) / 160) * size.height;
    canvas.drawRect(Rect.fromLTRB(0, yTop, size.width, yBottom), rangePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
