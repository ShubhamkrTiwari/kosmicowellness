import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../managers/care_manager.dart';

class ScanMealModule extends StatefulWidget {
  const ScanMealModule({super.key});

  @override
  State<ScanMealModule> createState() => _ScanMealModuleState();
}

class _ScanMealModuleState extends State<ScanMealModule> {
  bool _isScanning = false;
  bool _showResult = false;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _currentFoodData;

  Future<void> _startScan() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isScanning = true;
          _showResult = false;
        });
        
        // High-fidelity simulation of AI analysis picking a random starting point
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted) {
          final db = CareManager().foodDatabase;
          setState(() {
            _isScanning = false;
            _showResult = true;
            // Pick a random guess from DB
            _currentFoodData = db[Random().nextInt(db.length)];
          });
        }
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  void _showFoodCorrectionDialog() {
    final db = CareManager().foodDatabase;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not what you\'re eating?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: db.length,
            itemBuilder: (context, index) {
              final item = db[index];
              return ListTile(
                title: Text(item['name']),
                subtitle: Text('${item['carbs']}g Carbs'),
                onTap: () {
                  setState(() {
                    _currentFoodData = item;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildScannerView(colorScheme),
          const SizedBox(height: 24),
          if (_showResult && _currentFoodData != null) _buildResultView(colorScheme),
          if (!_isScanning && !_showResult) _buildInstructions(colorScheme),
        ],
      ),
    );
  }

  Widget _buildScannerView(ColorScheme colorScheme) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        image: (_capturedImage != null && !_isScanning) 
          ? DecorationImage(image: FileImage(File(_capturedImage!.path)), fit: BoxFit.cover)
          : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_capturedImage == null)
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
          
          if (_isScanning) ...[
             if (_capturedImage != null)
                Opacity(
                  opacity: 0.5,
                  child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
             _buildScanAnimation(colorScheme),
             const Positioned(
               top: 40,
               child: Text('AI ANALYZING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
             ),
          ],

          Positioned(
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: Icon(_capturedImage == null ? Icons.camera_alt : Icons.refresh),
              label: Text(_isScanning ? 'Processing...' : (_capturedImage == null ? 'Scan Plate' : 'Retake')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanAnimation(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 310),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Positioned(
          top: 20 + value,
          child: Container(
            width: 250,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(color: colorScheme.primary, blurRadius: 15, spreadRadius: 4),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        if (_isScanning) setState(() {}); // Loop animation
      },
    );
  }

  Widget _buildResultView(ColorScheme colorScheme) {
    final Map<String, dynamic>? food = _currentFoodData;
    if (food == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Text('Scan Result:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton.icon(
                onPressed: _showFoodCorrectionDialog,
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('AI suggests: ${food['name']}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Carbs', '${food['carbs'] ?? 0}g', Colors.orange),
              _buildMetric('Net Carbs', '${food['netCarbs'] ?? 0}g', Colors.blue),
              _buildMetric('GI', food['gi'] ?? 'Med', Colors.green),
              _buildMetric('GL', food['gl'] ?? 'Med', Colors.yellow[800] ?? Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          _buildRiskBanner('Spike Risk: ${food['spikeRisk'] ?? 'Med'}', Icons.warning_amber_rounded, _getRiskColor(food['spikeRisk']?.toString() ?? 'Med')),
          const SizedBox(height: 16),
          _buildSwapSuggestion(colorScheme, food['swap']?.toString() ?? 'Healthier options'),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low': return Colors.green;
      case 'med': return Colors.orange;
      case 'high': return Colors.red;
      case 'very high': return Colors.red[700] ?? Colors.red;
      case 'extreme': return Colors.red[900] ?? Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRiskBanner(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSwapSuggestion(ColorScheme colorScheme, String swap) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Smart Swap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            swap.contains('choice') ? swap : 'Try replacing with $swap to manage your glucose levels better.',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'Place your food in the center of the frame and click Scan to see nutritional insights.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
