import 'package:flutter/material.dart';

class ActivityImpactModule extends StatefulWidget {
  const ActivityImpactModule({super.key});

  @override
  State<ActivityImpactModule> createState() => _ActivityImpactModuleState();
}

class _ActivityImpactModuleState extends State<ActivityImpactModule> {
  String _selectedActivity = 'Walking';
  double _duration = 30; // minutes
  String _intensity = 'Moderate';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalculator(colorScheme),
          const SizedBox(height: 32),
          const Text('Recent Workouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildWorkoutItem('Morning Walk', '45 min', '-12 mg/dL drop', Icons.directions_walk, Colors.green, colorScheme),
          _buildWorkoutItem('Gym Session', '60 min', '-28 mg/dL drop', Icons.fitness_center, Colors.orange, colorScheme),
          _buildWorkoutItem('Yoga', '30 min', '-5 mg/dL drop', Icons.self_improvement, Colors.blue, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCalculator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exercise Impact Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildDropdown('Activity', ['Walking', 'Running', 'Cycling', 'Swimming', 'Strength Training'], _selectedActivity, (v) => setState(() => _selectedActivity = v!)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration', style: TextStyle(fontSize: 12)),
              Text('${_duration.toInt()} min', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _duration,
            min: 5,
            max: 120,
            divisions: 23,
            label: '${_duration.toInt()} min',
            onChanged: (v) => setState(() => _duration = v),
          ),
          const SizedBox(height: 8),
          _buildDropdown('Intensity', ['Low', 'Moderate', 'High'], _intensity, (v) => setState(() => _intensity = v!)),
          const SizedBox(height: 24),
          _buildImpactResult(colorScheme),
        ],
      ),
    );
  }

  Widget _buildImpactResult(ColorScheme colorScheme) {
    // Mock calculation
    double factor = _intensity == 'High' ? 1.5 : (_intensity == 'Moderate' ? 1.0 : 0.5);
    int drop = (_duration * 0.4 * factor).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_down, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            'Estimated Glucose Drop: -$drop mg/dL',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildWorkoutItem(String title, String duration, String impact, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(duration, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(impact, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
