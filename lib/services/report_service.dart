import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../managers/care_manager.dart';
import '../managers/user_manager.dart';

class ReportService {
  static Future<void> shareClinicalReport(CareManager manager) async {
    final pdf = pw.Document();
    final String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final String userName = UserManager().userName ?? 'Valued User';
    
    // Load font if needed, but standard ones are okay
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('KOSMICO WELLNESS', style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.green800)),
                    pw.Text('Clinical Glucose Report', style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('Patient: $userName', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Metrics Grid (Glucose Summary)
            pw.Text('Glucose Summary', style: pw.TextStyle(font: boldFont, fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                _buildMetricCard('Average Glucose', '${manager.averageGlucose.toStringAsFixed(1)} mg/dL', PdfColors.green50),
                pw.SizedBox(width: 10),
                _buildMetricCard('Estimated A1C', '${manager.estimatedA1C.toStringAsFixed(2)}%', PdfColors.blue50),
                pw.SizedBox(width: 10),
                _buildMetricCard('Time In Range', '${manager.timeInRangePercentage.toStringAsFixed(1)}%', PdfColors.orange50),
              ],
            ),
            pw.SizedBox(height: 30),

            // Lifestyle Metrics
            pw.Text('Lifestyle Metrics (Today)', style: pw.TextStyle(font: boldFont, fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Bullet(text: 'Water Intake: ${manager.waterIntake} ml'),
            pw.Bullet(text: 'Stress Level: ${_getStressText(manager.stressLevel)}'),
            pw.SizedBox(height: 30),

            // Recent Meals Table
            pw.Text('Recent Meals & Logs', style: pw.TextStyle(font: boldFont, fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Meal Type', 'Carbs (g)', 'Status', 'Date'],
              data: manager.mealMarkers.reversed.take(15).map((meal) {
                return [
                  meal['mealType'] ?? 'N/A',
                  '${meal['carbs'] ?? 0}g',
                  meal['status'] ?? 'Logged',
                  (meal['logTime'] ?? '').toString().split('T')[0],
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
            ),
            
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text(
                'Note: This is an automatically generated report based on user-logged data. Please consult your physician for medical advice.',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    // Share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Kosmico_Report_${userName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          ],
        ),
      ),
    );
  }

  static String _getStressText(int level) {
    if (level == 1) return 'Very Low';
    if (level == 2) return 'Low';
    if (level == 3) return 'Moderate';
    if (level == 4) return 'High';
    if (level == 5) return 'Very High';
    return 'Not Logged';
  }
}
