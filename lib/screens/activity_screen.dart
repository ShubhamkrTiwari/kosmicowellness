import 'package:flutter/material.dart';
import '../managers/care_manager.dart';
import '../managers/step_counter_manager.dart';
import 'care/activity_module.dart';

/// Dedicated full-screen page for the footstep counter and its linked
/// trackers (activity-based hydration goal and food vs burn guidance).
/// Opens from the home screen feature hub; the same module also lives
/// inside the GlucoRhythm care dashboard as the "Activity" tab.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    // Start the live pedometer as soon as the dedicated screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StepCounterManager().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: ListenableBuilder(
          listenable: CareManager(),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity & Footsteps',
                style: TextStyle(
                  color: Color(0xFF00833E),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${CareManager().stepsToday} steps today • ${CareManager().distanceKm.toStringAsFixed(2)} km',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      body: const ActivityModule(),
    );
  }
}
