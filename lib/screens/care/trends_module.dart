import 'package:flutter/material.dart';

class TrendsModule extends StatelessWidget {
  const TrendsModule({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyAverages(colorScheme),
          const SizedBox(height: 24),
          _buildTimeInRangeBars(colorScheme),
          const SizedBox(height: 24),
          _buildSpikePredictor(colorScheme),
          const SizedBox(height: 24),
          _buildPatternInsights(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSpikePredictor(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Spike Predictor',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Beta', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Based on your lunch (Pasta) and activity (Low), we estimate a potential rise in 45 minutes.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildPredictionMetric('Estimated Spike', '+65 mg/dL', Colors.red),
          const SizedBox(height: 12),
          _buildPredictionMetric('Confidence Score', '88%', Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Recommendation: Take a 10-minute brisk walk to mitigate this rise.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionMetric(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildWeeklyAverages(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Averages', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendItem('Fasting', '92', Icons.arrow_downward, Colors.green),
              _buildTrendItem('Post-Meal', '145', Icons.arrow_upward, Colors.red),
              _buildTrendItem('Overall', '118', Icons.remove, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Icon(icon, color: color, size: 14),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeInRangeBars(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time in Range', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRangeBar('In Range (70-140)', 0.84, Colors.green),
        const SizedBox(height: 8),
        _buildRangeBar('High (>140)', 0.12, Colors.orange),
        const SizedBox(height: 8),
        _buildRangeBar('Low (<70)', 0.04, Colors.red),
      ],
    );
  }

  Widget _buildRangeBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('${(percentage * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPatternInsights(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pattern Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildInsightItem('Dawn Phenomenon', 'Early morning rise detected in 4 of last 7 days.', Icons.wb_sunny_outlined, colorScheme),
        _buildInsightItem('Post-Lunch Swing', 'Average rise of 54 mg/dL after lunch.', Icons.lunch_dining, colorScheme),
        _buildInsightItem('Better Sleep', 'Night time stability improved by 15%.', Icons.bedtime_outlined, colorScheme),
      ],
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
