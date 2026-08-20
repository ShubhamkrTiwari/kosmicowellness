import 'package:flutter/material.dart';

class MedicationRemindersModule extends StatefulWidget {
  const MedicationRemindersModule({super.key});

  @override
  State<MedicationRemindersModule> createState() => _MedicationRemindersModuleState();
}

class _MedicationRemindersModuleState extends State<MedicationRemindersModule> {
  final List<Map<String, dynamic>> _reminders = [
    {'name': 'Metformin', 'time': '08:30 AM', 'dose': '500mg', 'active': true, 'type': 'Oral'},
    {'name': 'Insulin Glargine', 'time': '10:00 PM', 'dose': '12 units', 'active': true, 'type': 'Insulin'},
    {'name': 'Multivitamin', 'time': '09:00 AM', 'dose': '1 tab', 'active': false, 'type': 'Oral'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRefillSection(colorScheme),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          ..._reminders.map((r) => _buildReminderCard(r, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildRefillSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_basket_outlined, color: Colors.orange, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prescription Refill', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('You have 3 days of Metformin left.', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: const Text('Order Now', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> r, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r['active'] ? colorScheme.primary.withValues(alpha: 0.3) : colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(r['type'] == 'Insulin' ? Icons.colorize : Icons.medication, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${r['time']} • ${r['dose']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: r['active'],
            onChanged: (val) => setState(() => r['active'] = val),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
