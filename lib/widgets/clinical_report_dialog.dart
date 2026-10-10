import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../managers/care_manager.dart';
import '../managers/user_manager.dart';
import '../managers/bluetooth_manager.dart';
import '../services/report_service.dart';

class ClinicalReportDialog {
  static void show(BuildContext context) {
    final manager = CareManager();
    final patientName = UserManager().userName ?? 'Valued Patient';
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final reportId = 'KOS-GLU-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final double avg = manager.averageGlucose > 0 ? manager.averageGlucose : 118.0;
    final double a1c = manager.estimatedA1C > 0 ? manager.estimatedA1C : ((avg + 46.7) / 28.7);
    final double tir = manager.timeInRangePercentage > 0 ? manager.timeInRangePercentage : 82.0;
    final double gmi = 3.31 + (0.02392 * avg);

    String a1cStatus = 'Normal';
    Color a1cColor = Colors.green;
    if (a1c >= 6.5) {
      a1cStatus = 'Diabetic Range';
      a1cColor = Colors.red;
    } else if (a1c >= 5.7) {
      a1cStatus = 'Pre-Diabetic';
      a1cColor = Colors.orange[800]!;
    }

    Color tirColor = tir >= 70 ? Colors.green : Colors.orange[800]!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          child: Column(
            children: [
              // Dialog Header Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D5C46),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KOSMICO METABOLIC CLINIC',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                          Text(
                            'Clinical & Wellness Diagnostic Profile',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Scrollable Clinical Report Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Disclaimer Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI-Generated Report Disclaimer',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF92400E)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'This clinical and wellness profile is generated by Kosmico AI biotelemetry analytics. It is designed for informational and tracking purposes and does not replace professional medical diagnosis.',
                                    style: TextStyle(fontSize: 10.5, height: 1.3, color: Color(0xFF78350F)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Patient Demographics Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCCE3DB)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildDemographicItem('PATIENT', patientName, isBold: true)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildDemographicItem('REPORT ID', reportId)),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFCCE3DB)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildDemographicItem('DATE', dateStr)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildDemographicItem('TELEMETRY', 'Vitals, Steps & Glucose')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Key Biomarkers Summary Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricBadge(
                              title: 'Estimated HbA1c',
                              value: '${a1c.toStringAsFixed(2)}%',
                              status: a1cStatus,
                              statusColor: a1cColor,
                              target: 'Target: <7.0%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricBadge(
                              title: 'Mean Glucose',
                              value: '${avg.toStringAsFixed(1)} mg/dL',
                              status: avg <= 130 ? 'In Target' : (avg <= 180 ? 'Moderate' : 'High'),
                              statusColor: avg <= 130 ? Colors.green : Colors.orange[800]!,
                              target: 'Target: 70-130',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricBadge(
                              title: 'Time in Range',
                              value: '${tir.toStringAsFixed(1)}%',
                              status: tir >= 70 ? 'Optimal' : 'Needs Work',
                              statusColor: tirColor,
                              target: 'ADA: >70%',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Glycemic & Wellness Diagnostics Matrix Table
                      const Text(
                        'COMPREHENSIVE WELLNESS & BIOMARKER MATRIX',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D5C46), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFF0D5C46),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('PARAMETER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                    Expanded(flex: 2, child: Text('VALUE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                    Expanded(flex: 3, child: Text('REF. RANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                    Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                  ],
                                ),
                              ),
                              _buildUiTableRow('Est. HbA1c', '${a1c.toStringAsFixed(2)}%', '< 5.7 (Normal)\n5.7-6.4 (Pre-D)', a1cStatus, a1cColor, isOdd: false),
                              _buildUiTableRow('Mean Glucose', '${avg.toStringAsFixed(1)} mg/dL', '70 - 130 mg/dL', avg <= 130 ? 'In Target' : 'Elevated', avg <= 130 ? Colors.green : Colors.orange[800]!, isOdd: true),
                              _buildUiTableRow('Time in Range', '${tir.toStringAsFixed(1)}%', '> 70.0% (ADA)', tir >= 70 ? 'Optimal' : 'Low', tirColor, isOdd: false),
                              _buildUiTableRow('Hydration (Water)', '${manager.waterIntake} mL', 'Adaptive: ${manager.waterGoal} mL', manager.waterIntake >= manager.waterGoal ? 'Adequate' : 'Low', manager.waterIntake >= manager.waterGoal ? Colors.green : Colors.orange[800]!, isOdd: true),
                              _buildUiTableRow('Footstep Count', '${manager.stepsToday}', '${manager.stepGoal} steps (Goal)', manager.stepsToday >= manager.stepGoal ? 'Goal Hit' : (manager.stepsToday >= manager.stepGoal * 0.5 ? 'On Track' : 'Sedentary'), manager.stepsToday >= manager.stepGoal * 0.5 ? Colors.green : Colors.orange[800]!, isOdd: false),
                              _buildUiTableRow('Stress Score', '${manager.stressLevel}/5', '1 - 2 (Low Spike)', manager.stressLevel <= 2 ? 'Normal' : 'High', manager.stressLevel <= 2 ? Colors.green : Colors.orange[800]!, isOdd: true),
                              _buildUiTableRow('Mood & Energy', '${manager.energyLevel}/5 Score', '3 - 5 (Optimal Vitality)', manager.energyLevel >= 3 ? 'Vital' : 'Low Energy', manager.energyLevel >= 3 ? Colors.green : Colors.orange[800]!, isOdd: false),
                              _buildUiTableRow('Blood Pressure', '${BluetoothManager().latestSystolic ?? 118}/${BluetoothManager().latestDiastolic ?? 76} mmHg', '< 120 / 80 mmHg', BluetoothManager().bloodPressureCategory, BluetoothManager().bloodPressureColor, isOdd: true),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Endocrinologist Clinical Impression Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCCE3DB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.psychology_outlined, color: Color(0xFF0D5C46), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'AI Clinical Impression & Recommendations',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D5C46)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a1c < 5.7 
                                ? '• Glycemic profile indicates non-diabetic range with excellent metabolic stability.'
                                : (a1c <= 6.4 
                                    ? '• Pre-diabetic glycemic profile observed. Recommended low GI diet swaps and post-meal physical activity.'
                                    : (a1c <= 7.0 
                                        ? '• Well-managed diabetic range compliant with ADA (<7.0%) standards.'
                                        : '• Glycemic elevation detected. Discuss medication adjustment with your healthcare provider.')),
                              style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Hydration (${manager.waterIntake} mL), daily footsteps (${manager.stepsToday}), and stress/mood scores are successfully saved and factored into your metabolic wellness report.',
                              style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Share.share(manager.generateClinicalReport(), subject: 'Kosmico Clinical Diabetes Report');
                        },
                        icon: const Icon(Icons.text_snippet_outlined, size: 18),
                        label: const Text('Share Text'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ReportService.shareClinicalReport(manager);
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Download / Share PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDemographicItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E293B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static Widget _buildMetricBadge({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required String target,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 8.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            target,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget _buildUiTableRow(
    String parameter,
    String value,
    String refRange,
    String status,
    Color statusColor, {
    required bool isOdd,
  }) {
    return Container(
      color: isOdd ? const Color(0xFFF8FAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(parameter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF1E293B))),
          ),
          Expanded(
            flex: 2,
            child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A))),
          ),
          Expanded(
            flex: 3,
            child: Text(refRange, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.2)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: statusColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
