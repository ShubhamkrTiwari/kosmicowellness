import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
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
  ImageLabeler? _imageLabeler;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
    }
  }

  @override
  void dispose() {
    _imageLabeler?.close();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning is only supported on Android/iOS devices.')),
      );
      return;
    }

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
        
        final inputImage = InputImage.fromFilePath(image.path);
        final labels = await _imageLabeler!.processImage(inputImage);
        
        if (mounted) {
          _matchFoodWithLocalDatabase(labels);
        }
      }
    } catch (e) {
      debugPrint('Scan Error: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e. Please re-run the app.')),
        );
      }
    }
  }

  void _matchFoodWithLocalDatabase(List<ImageLabel> labels) {
    final db = CareManager().foodDatabase;
    Map<String, dynamic>? match;

    // Check for direct matches in our database
    for (var label in labels) {
      final labelText = label.label.toLowerCase();
      
      // Find food in our local DB that matches the ML label
      for (var food in db) {
        final foodName = food['name'].toString().toLowerCase();
        if (foodName.contains(labelText) || labelText.contains(foodName)) {
          match = food;
          break;
        }
      }
      if (match != null) break;
    }

    // Smart fallback if no direct match
    if (match == null && labels.isNotEmpty) {
      final String allLabels = labels.map((l) => l.label.toLowerCase()).join(' ');
      
      if (allLabels.contains('bottle') || allLabels.contains('water') || allLabels.contains('plastic')) {
        match = db.firstWhere((f) => f['name'] == 'Water (Bottle)');
      } else if (allLabels.contains('fruit') || allLabels.contains('apple')) {
        match = db.firstWhere((f) => f['name'] == 'Apple (Medium)');
      } else if (allLabels.contains('juice') || allLabels.contains('drink') || allLabels.contains('beverage')) {
        match = db.firstWhere((f) => f['name'] == 'Real Guava Juice');
      } else if (allLabels.contains('bread') || allLabels.contains('dough')) {
        match = db.firstWhere((f) => f['name'] == 'Paneer Paratha');
      } else if (allLabels.contains('food') || allLabels.contains('dish') || allLabels.contains('cuisine')) {
        match = db.firstWhere((f) => f['name'] == 'Dal Tadka & Rice');
      } else {
        // Definitely not food? 
        match = null; 
      }
    }

    setState(() {
      _isScanning = false;
      _showResult = true;
      _currentFoodData = match;
    });
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
          if (_showResult) _buildResultView(colorScheme),
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
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_capturedImage != null && !_isScanning)
             ClipRRect(
               borderRadius: BorderRadius.circular(24),
               child: kIsWeb 
                ? Image.network(_capturedImage!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : Image.file(File(_capturedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
             ),

          if (_capturedImage == null && !_isScanning)
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
          
          if (_isScanning) ...[
             if (_capturedImage != null)
                Opacity(
                  opacity: 0.5,
                  child: kIsWeb
                    ? Image.network(_capturedImage!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    : Image.file(File(_capturedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
             _buildScanAnimation(colorScheme),
             const Positioned(
               top: 40,
               child: Text('AI RECOGNIZING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
        if (_isScanning) setState(() {});
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
          Text('Best local match: ${food['name']}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
