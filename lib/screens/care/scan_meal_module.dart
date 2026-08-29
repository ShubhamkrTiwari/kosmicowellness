import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/gemini_service.dart';
import '../../managers/care_manager.dart';

class ScanMealModule extends StatefulWidget {
  const ScanMealModule({super.key});

  @override
  State<ScanMealModule> createState() => _ScanMealModuleState();
}

class _ScanMealModuleState extends State<ScanMealModule> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _showResult = false;
  bool _isLogging = false;
  bool _isFoodDetected = true;
  String _scanStatusText = 'ANALYZING MEAL...';
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _currentFoodData;
  List<Map<String, dynamic>> _alternateMatches = [];
  double _portionMultiplier = 1.0;
  String _selectedMealType = 'Lunch';
  String _scanSource = 'Gemini AI Vision';

  // Reference Details state
  String _selectedFilling = 'Standard';
  String _selectedOilLevel = 'Normal Home-cooked';
  String _selectedSweetness = 'Sugar-Free / None';
  final TextEditingController _notesController = TextEditingController();
  bool _isReanalyzing = false;

  @override
  void initState() {
    super.initState();
    _setDefaultMealType();
  }

  void _loadReferencePreferencesForCurrentFood(String dishName) {
    if (dishName.isEmpty) return;
    final prefs = CareManager().getFoodReferencePreference(dishName);
    if (prefs != null) {
      setState(() {
        _selectedFilling = prefs['filling']?.toString() ?? 'Standard';
        _selectedOilLevel = prefs['oilLevel']?.toString() ?? 'Normal Home-cooked';
        _selectedSweetness = prefs['sweetness']?.toString() ?? 'Sugar-Free / None';
        _notesController.text = prefs['notes']?.toString() ?? '';
      });
    } else {
      setState(() {
        _selectedFilling = 'Standard';
        _selectedOilLevel = 'Normal Home-cooked';
        _selectedSweetness = 'Sugar-Free / None';
        _notesController.clear();
      });
    }
  }

  void _setDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      _selectedMealType = 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      _selectedMealType = 'Lunch';
    } else if (hour >= 16 && hour < 19) {
      _selectedMealType = 'Snack';
    } else {
      _selectedMealType = 'Dinner';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Scan Your Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo of your food plate or choose from your photo gallery for instant glycemic analysis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _startScan(ImageSource.camera);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_rounded, color: colorScheme.primary, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _startScan(ImageSource.gallery);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_rounded, color: colorScheme.secondary, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startScan(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;

      setState(() {
        _capturedImage = image;
        _isScanning = true;
        _showResult = false;
        _isFoodDetected = true;
        _portionMultiplier = 1.0;
        _scanStatusText = 'EXTRACTING VISUAL FEATURES...';
      });

      Map<String, dynamic>? foodResult;
      List<Map<String, dynamic>> alternates = [];
      String detectedSource = 'Gemini AI Vision';

      final isCloudActive = await GeminiService().isKeyConfigured;

      if (!isCloudActive) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _isFoodDetected = false;
            _showResult = true;
            _currentFoodData = null;
            _alternateMatches = CareManager().foodDatabase.take(4).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gemini API key is not configured. Please search or select your dish.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) setState(() => _scanStatusText = 'ANALYZING WITH GEMINI AI VISION...');

      try {
        final aiResponse = await GeminiService().analyzeFoodImage(image);
        if (aiResponse.data != null && !aiResponse.isFallback) {
          foodResult = aiResponse.data;
          detectedSource = 'Gemini AI Vision';

          if (foodResult!['isFood'] == false) {
            if (mounted) {
              setState(() {
                _isScanning = false;
                _isFoodDetected = false;
                _showResult = true;
                _currentFoodData = null;
                _alternateMatches = CareManager().foodDatabase.take(4).toList();
              });
            }
            return;
          }

          if (foodResult['alternates'] is List && (foodResult['alternates'] as List).isNotEmpty) {
            for (var alt in foodResult['alternates']) {
              final altName = alt.toString().trim();
              if (altName.isEmpty) continue;
              final match = CareManager().searchFood(altName);
              if (match.isNotEmpty) {
                alternates.add(match.first);
              } else {
                double altCarbs = (foodResult['carbs'] as num? ?? 35.0).toDouble();
                double altFiber = (foodResult['fiber'] as num? ?? 4.0).toDouble();
                double altProtein = (foodResult['protein'] as num? ?? 8.0).toDouble();
                double altFat = (foodResult['fat'] as num? ?? 6.0).toDouble();
                int altCalories = (foodResult['calories'] as num? ?? 250).toInt();
                String altGi = foodResult['gi']?.toString() ?? 'Med';
                String altGl = foodResult['gl']?.toString() ?? 'Med';
                String altRisk = foodResult['spikeRisk']?.toString() ?? 'Med';

                alternates.add({
                  'name': altName,
                  'carbs': altCarbs,
                  'fiber': altFiber,
                  'netCarbs': ((altCarbs - altFiber) > 0 ? (altCarbs - altFiber) : (altCarbs * 0.85)).roundToDouble(),
                  'calories': altCalories,
                  'protein': altProtein,
                  'fat': altFat,
                  'portion': '1 standard serving',
                  'gi': altGi,
                  'gl': altGl,
                  'spikeRisk': altRisk,
                  'swap': 'Eat with fresh fiber salad to minimize postprandial glucose spike.',
                });
              }
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isScanning = false;
              _isFoodDetected = false;
              _showResult = true;
              _currentFoodData = null;
              _alternateMatches = CareManager().foodDatabase.take(4).toList();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(aiResponse.errorMessage ?? 'Could not analyze food photo. Please search or pick dish manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Gemini vision scan failed: $e');
        if (mounted) {
          setState(() {
            _isScanning = false;
            _isFoodDetected = false;
            _showResult = true;
            _currentFoodData = null;
            _alternateMatches = CareManager().foodDatabase.take(4).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Scan Error: $e. Please search your food dish manually.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (alternates.isEmpty) {
        alternates = CareManager().foodDatabase
            .where((f) => f['name'] != foodResult!['name'])
            .take(4)
            .toList();
      }

      if (mounted) {
        setState(() {
          _isScanning = false;
          _currentFoodData = foodResult;
          _alternateMatches = alternates;
          _scanSource = detectedSource;
          _isFoodDetected = true;
          _showResult = true;
        });
        _loadReferencePreferencesForCurrentFood(foodResult['name']?.toString() ?? '');
      }
    } catch (e) {
      debugPrint('Scan Error: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reanalyzeWithReferenceDetails() async {
    if (_capturedImage == null && _currentFoodData == null) return;
    
    setState(() => _isReanalyzing = true);

    try {
      final dishName = _currentFoodData?['name']?.toString() ?? 'Meal';
      final refDetails = {
        'dishName': dishName,
        'filling': _selectedFilling,
        'oilLevel': _selectedOilLevel,
        'sweetness': _selectedSweetness,
        'notes': _notesController.text.trim(),
      };

      // Save user preference for personalization & learning
      await CareManager().saveFoodReferencePreference(dishName, refDetails);

      GeminiResponse? aiResponse;
      if (_capturedImage != null) {
        aiResponse = await GeminiService().analyzeFoodImage(
          _capturedImage!,
          referenceDetails: refDetails,
        );
      } else {
        aiResponse = await GeminiService().analyzeFoodByName(
          "$dishName with ${_selectedFilling != 'Standard' ? '$_selectedFilling filling, ' : ''}$_selectedOilLevel, $_selectedSweetness, ${_notesController.text}",
        );
      }

      if (aiResponse.data != null && !aiResponse.isFallback) {
        final updatedData = Map<String, dynamic>.from(aiResponse.data!);
        setState(() {
          _currentFoodData = updatedData;
          _scanSource = 'Gemini AI Vision + Refined Context';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Nutrition updated for ${_selectedFilling != 'Standard' ? '$_selectedFilling ' : ''}$dishName!'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1B5E20),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _adjustNutritionLocally(refDetails);
      }
    } catch (e) {
      debugPrint('Re-analyze error: $e');
      final refDetails = {
        'filling': _selectedFilling,
        'oilLevel': _selectedOilLevel,
        'sweetness': _selectedSweetness,
        'notes': _notesController.text.trim(),
      };
      _adjustNutritionLocally(refDetails);
    } finally {
      if (mounted) {
        setState(() => _isReanalyzing = false);
      }
    }
  }

  void _adjustNutritionLocally(Map<String, dynamic> refDetails) {
    if (_currentFoodData == null) return;
    final current = Map<String, dynamic>.from(_currentFoodData!);
    double carbs = (current['carbs'] as num? ?? 30.0).toDouble();
    double protein = (current['protein'] as num? ?? 6.0).toDouble();
    double fat = (current['fat'] as num? ?? 5.0).toDouble();
    double fiber = (current['fiber'] as num? ?? 3.0).toDouble();

    final filling = refDetails['filling']?.toString().toLowerCase() ?? '';
    if (filling.contains('paneer') || filling.contains('cheese')) {
      protein += 7.0;
      fat += 8.0;
    } else if (filling.contains('chicken') || filling.contains('keema')) {
      protein += 12.0;
      fat += 6.0;
    } else if (filling.contains('aloo') || filling.contains('potato')) {
      carbs += 14.0;
      fiber += 1.5;
    } else if (filling.contains('tofu') || filling.contains('soya')) {
      protein += 9.0;
      fat += 4.0;
    }

    final oil = refDetails['oilLevel']?.toString().toLowerCase() ?? '';
    if (oil.contains('fried') || oil.contains('rich')) {
      fat += 10.0;
    } else if (oil.contains('less') || oil.contains('zero')) {
      fat = (fat - 4.0).clamp(1.0, 100.0);
    }

    final sweet = refDetails['sweetness']?.toString().toLowerCase() ?? '';
    if (sweet.contains('high')) {
      carbs += 18.0;
    } else if (sweet.contains('mild')) {
      carbs += 8.0;
    }

    final cal = (carbs * 4 + protein * 4 + fat * 9).round();
    current['carbs'] = carbs.roundToDouble();
    current['fiber'] = fiber.roundToDouble();
    current['netCarbs'] = ((carbs - fiber) > 0 ? (carbs - fiber) : (carbs * 0.85)).roundToDouble();
    current['protein'] = protein.roundToDouble();
    current['fat'] = fat.roundToDouble();
    current['calories'] = cal;
    current['confidence_score'] = 'High';
    current['assumptions_made'] = 'Customized locally using reference parameters: $filling filling, $oil, $sweet.';

    setState(() {
      _currentFoodData = current;
      _scanSource = 'Clinical Engine (Adjusted)';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrition updated based on reference details!'),
          backgroundColor: Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFoodCorrectionDialog() {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = CareManager().foodDatabase;
    bool isSearchingCloud = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          height: MediaQuery.of(modalCtx).size.height * 0.8,
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select or Search Dish',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pick your exact food for accurate glycemic calculations:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search (e.g. Bajra Roti, Dal, Paneer, Dosa)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.travel_explore, color: Colors.teal),
                    tooltip: 'AI Web Search',
                    onPressed: () async {
                      if (searchController.text.trim().isEmpty) return;
                      setModalState(() => isSearchingCloud = true);
                      final aiRes = await GeminiService().analyzeFoodByName(searchController.text.trim());
                      if (aiRes.data != null) {
                        setState(() {
                          _currentFoodData = aiRes.data;
                          _scanSource = 'Gemini AI Search';
                          _isFoodDetected = true;
                          _showResult = true;
                        });
                        _loadReferencePreferencesForCurrentFood(aiRes.data!['name']?.toString() ?? '');
                        if (mounted) Navigator.pop(modalCtx);
                      }
                      return;
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (query) {
                  setModalState(() {
                    searchResults = CareManager().searchFood(query);
                  });
                },
                onSubmitted: (query) async {
                  if (query.trim().isNotEmpty && searchResults.isEmpty) {
                    setModalState(() => isSearchingCloud = true);
                    final aiRes = await GeminiService().analyzeFoodByName(query.trim());
                    if (aiRes.data != null) {
                      setState(() {
                        _currentFoodData = aiRes.data;
                        _scanSource = 'Gemini AI Search';
                        _isFoodDetected = true;
                        _showResult = true;
                      });
                      _loadReferencePreferencesForCurrentFood(aiRes.data!['name']?.toString() ?? '');
                      if (mounted) Navigator.pop(modalCtx);
                    }
                    return;
                  }
                  setModalState(() => isSearchingCloud = false);
                },
              ),
              if (isSearchingCloud)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No matching dish found for "${searchController.text}"', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                final customName = searchController.text.trim();
                                setState(() {
                                  _currentFoodData = {
                                    'name': customName,
                                    'carbs': 25.0,
                                    'netCarbs': 20.0,
                                    'calories': 180,
                                    'protein': 5.0,
                                    'fiber': 3.0,
                                    'fat': 4.0,
                                    'portion': '1 serving',
                                    'gi': 'Med',
                                    'gl': 'Low',
                                    'spikeRisk': 'Med',
                                    'confidence_score': 'Medium',
                                    'assumptions_made': 'User-defined custom entry.',
                                    'swap': 'Pair with high fiber salad and protein to reduce glycemic spike.',
                                  };
                                  _scanSource = 'Custom Food Entry';
                                  _isFoodDetected = true;
                                  _showResult = true;
                                });
                                _loadReferencePreferencesForCurrentFood(customName);
                                Navigator.pop(modalCtx);
                              },
                              icon: const Icon(Icons.add),
                              label: Text('Use "${searchController.text}"'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          final risk = item['spikeRisk']?.toString() ?? 'Low';
                          final riskColor = _getRiskColor(risk);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.restaurant, color: riskColor, size: 22),
                            ),
                            title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              '${item['carbs'] ?? 0}g Carbs • ${item['calories'] ?? 0} kcal • GI: ${item['gi'] ?? 'Med'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                risk,
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _currentFoodData = item;
                                _scanSource = 'Selected from Database';
                                _isFoodDetected = true;
                                _showResult = true;
                              });
                              _loadReferencePreferencesForCurrentFood(item['name'] ?? '');
                              Navigator.pop(modalCtx);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logMealToCareManager() async {
    if (_currentFoodData == null) return;
    
    final double rawCarbs = double.tryParse(_currentFoodData!['carbs']?.toString() ?? '0') ?? 0.0;
    final double scaledCarbs = (rawCarbs * _portionMultiplier).roundToDouble();

    setState(() => _isLogging = true);
    
    try {
      final success = await CareManager().addMealLog(_selectedMealType, scaledCarbs);
      if (mounted) {
        setState(() => _isLogging = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Logged $_selectedMealType: ${_currentFoodData!['name']} (${scaledCarbs.toStringAsFixed(0)}g carbs)',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to health log locally.'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLogging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScannerView(colorScheme),
          const SizedBox(height: 20),
          if (_showResult) ...[
            if (!_isFoodDetected) 
              _buildNoFoodDetectedCard(colorScheme)
            else if (_currentFoodData != null)
              _buildResultView(colorScheme),
            const SizedBox(height: 24),
          ],
          if (!_isScanning && !_showResult) _buildInstructions(colorScheme),
        ],
      ),
    );
  }

  Widget _buildNoFoodDetectedCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: Colors.orange, size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            'Could Not Identify Food',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Please ensure the photo clearly shows your plate or meal, or choose your dish from the clinical list below:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImageSourcePicker,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retake Photo'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showFoodCorrectionDialog,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search Food'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(ColorScheme colorScheme) {
    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Display Image if available
            if (_capturedImage != null)
              Positioned.fill(
                child: Opacity(
                  opacity: _isScanning ? 0.4 : 1.0,
                  child: kIsWeb
                      ? Image.network(_capturedImage!.path, fit: BoxFit.cover)
                      : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                ),
              ),

            // Empty state placeholder
            if (_capturedImage == null && !_isScanning)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Plate & Meal Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Point at your food to calculate carbs & glucose impact',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),

            // Scanning Laser Animation
            if (_isScanning) ...[
              _buildScanAnimation(colorScheme),
              Positioned(
                top: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _scanStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Action Buttons Overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _showImageSourcePicker,
                      icon: Icon(_capturedImage == null ? Icons.camera_alt_rounded : Icons.photo_camera_back_rounded, size: 20),
                      label: Text(
                        _isScanning
                            ? 'Processing...'
                            : (_capturedImage == null ? 'Scan Food Plate' : 'Retake / New Photo'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  if (_capturedImage != null && !_isScanning) ...[
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        tooltip: 'Search & Pick Dish',
                        onPressed: _showFoodCorrectionDialog,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanAnimation(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 280),
      duration: const Duration(milliseconds: 1400),
      builder: (context, value, child) {
        return Positioned(
          top: 30 + value,
          child: Container(
            width: 270,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
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
    final Map<String, dynamic> food = _currentFoodData!;
    
    final double rawCarbs = double.tryParse(food['carbs']?.toString() ?? '0') ?? 0.0;
    final double rawFiber = double.tryParse(food['fiber']?.toString() ?? '0') ?? 0.0;
    final double rawNetCarbs = double.tryParse(food['netCarbs']?.toString() ?? '') ?? 
        ((rawCarbs - rawFiber) > 0 ? (rawCarbs - rawFiber) : (rawCarbs * 0.85));
    final double rawProtein = double.tryParse(food['protein']?.toString() ?? '0') ?? 0.0;
    final double rawFat = double.tryParse(food['fat']?.toString() ?? '0') ?? 0.0;
    final int rawCalories = int.tryParse(food['calories']?.toString() ?? '0') ?? 
        (rawCarbs * 4 + rawProtein * 4 + rawFat * 9).round();

    final double carbs = (rawCarbs * _portionMultiplier).roundToDouble();
    final double fiber = (rawFiber * _portionMultiplier).roundToDouble();
    final double netCarbs = (rawNetCarbs * _portionMultiplier).roundToDouble();
    final int calories = (rawCalories * _portionMultiplier).round();
    final double protein = (rawProtein * _portionMultiplier);

    // Dynamic Glycemic Load and Spike Risk calculation
    final String giRating = food['gi']?.toString() ?? 'Med';
    double giFactor = 55.0;
    if (giRating.toLowerCase().contains('high')) {
      giFactor = 70.0;
    } else if (giRating.toLowerCase().contains('low')) {
      giFactor = 40.0;
    }
    
    final double glycemicLoad = (giFactor * netCarbs) / 100.0;
    String adjustedRisk = 'Low';
    if (glycemicLoad >= 20.0 || netCarbs >= 45.0) {
      adjustedRisk = 'High';
    } else if (glycemicLoad >= 10.0 || netCarbs >= 25.0) {
      adjustedRisk = 'Med';
    } else {
      adjustedRisk = 'Low';
    }

    final Color riskColor = _getRiskColor(adjustedRisk);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Edit Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _scanSource,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (food['confidence_score'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(food['confidence_score']).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded, size: 10, color: _getConfidenceColor(food['confidence_score'])),
                                const SizedBox(width: 3),
                                Text(
                                  '${food['confidence_score']} Conf.',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: _getConfidenceColor(food['confidence_score']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          '• ${food['portion'] ?? '1 serving'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      food['name'] ?? 'Analyzed Food',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (food['ingredients'] is List && (food['ingredients'] as List).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (food['ingredients'] as List).map((ing) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '• ${ing.toString()}',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showFoodCorrectionDialog,
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          // Reference & Hidden Details Input Card
          _buildReferenceDetailsSection(colorScheme),

          // Alternate Candidate Chips (Did you mean?)
          if (_alternateMatches.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Similar matches (tap to switch):',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _alternateMatches.map((alt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        alt['name']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      avatar: const Icon(Icons.restaurant_menu, size: 13),
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      onPressed: () {
                        setState(() {
                          _currentFoodData = alt;
                          _scanSource = 'Selected Alternative';
                        });
                        _loadReferencePreferencesForCurrentFood(alt['name']?.toString() ?? '');
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Portion Size Adjuster
          _buildPortionSelector(colorScheme),

          const SizedBox(height: 18),

          // Main Nutrition Grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Carbs', '${carbs.toStringAsFixed(0)}g', Colors.orange[800]!)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('Net Carbs', '${netCarbs.toStringAsFixed(0)}g', Colors.blue[700]!)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('Calories', '$calories', Colors.deepOrange)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Protein', '${protein.toStringAsFixed(1)}g', Colors.teal[700]!)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('Fiber', '${fiber.toStringAsFixed(1)}g', Colors.green[700]!)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMetricCard('GI / GL', '${food['gi'] ?? 'Med'} / ${food['gl'] ?? 'Low'}', Colors.purple[700]!)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // AI Assumptions & Clinical Notes
          _buildAssumptionsCard(colorScheme, food),

          const SizedBox(height: 14),

          // Spike Risk Banner
          _buildRiskBanner(
            'Spike Risk: $adjustedRisk',
            Icons.speed_rounded,
            riskColor,
          ),

          const SizedBox(height: 14),

          // Smart Swap Recommendation
          _buildSwapSuggestion(
            colorScheme,
            food['swap']?.toString() ?? 'Pair with green salad or fiber-rich sabzi for optimal glucose control.',
          ),

          const SizedBox(height: 20),

          // Meal Logging Bar
          _buildLogMealSection(colorScheme, carbs),
        ],
      ),
    );
  }

  Widget _buildReferenceDetailsSection(ColorScheme colorScheme) {
    final fillings = ['Standard', 'Aloo', 'Paneer', 'Mixed Veg', 'Dal / Lentils', 'Chicken / Keema', 'Tofu / Soya'];
    final oilLevels = ['Less / Zero Oil', 'Normal Home-cooked', 'Extra Fried / Rich Gravy'];
    final sweetnessLevels = ['Sugar-Free / None', 'Mild Sugar', 'High Sugar / Jaggery'];

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune_rounded, size: 18, color: colorScheme.primary),
          ),
          title: const Text(
            'Reference & Recipe Details',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Specify filling, oil, or unseen ingredients for pinpoint diabetic accuracy',
            style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),

            // 1. Filling / Base Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 13, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Filling / Base Type:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: fillings.map((filling) {
                      final isSelected = _selectedFilling == filling;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(filling, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilling = filling);
                          },
                          selectedColor: colorScheme.primary.withValues(alpha: 0.18),
                          backgroundColor: Colors.transparent,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 2. Oil / Cooking Fat Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.opacity_rounded, size: 13, color: Colors.amber[800]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Oil / Cooking Fat Level:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: oilLevels.map((oil) {
                      final isSelected = _selectedOilLevel == oil;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(oil, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedOilLevel = oil);
                          },
                          selectedColor: Colors.amber.withValues(alpha: 0.22),
                          backgroundColor: Colors.transparent,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 3. Sweetness / Sugar Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cake_outlined, size: 13, color: Colors.pink[700]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Sweetness / Sugar Level:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sweetnessLevels.map((sweet) {
                      final isSelected = _selectedSweetness == sweet;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(sweet, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedSweetness = sweet);
                          },
                          selectedColor: Colors.pink.withValues(alpha: 0.18),
                          backgroundColor: Colors.transparent,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 4. Free-Text Notes Field
            TextField(
              controller: _notesController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Any other details? (e.g. cooked in olive oil, no potato, extra ghee)',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 5. Re-analyze Button with Loading State
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isReanalyzing ? null : _reanalyzeWithReferenceDetails,
                icon: _isReanalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _isReanalyzing ? 'Recalculating Nutrition...' : 'Re-analyze with Reference Details',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssumptionsCard(ColorScheme colorScheme, Map<String, dynamic> food) {
    final assumptions = food['assumptions_made']?.toString() ?? 'Calculated using standard clinical preparation ratios.';
    final confidence = food['confidence_score']?.toString() ?? 'High';

    Color confColor = Colors.green[700]!;
    if (confidence.toLowerCase() == 'low') {
      confColor = Colors.orange[800]!;
    } else if (confidence.toLowerCase() == 'medium') {
      confColor = Colors.blue[700]!;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'AI Clinical Estimation Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: confColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 10, color: confColor),
                    const SizedBox(width: 3),
                    Text(
                      'Confidence: $confidence',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: confColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            assumptions,
            style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant, height: 1.35),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(dynamic conf) {
    final s = conf?.toString().toLowerCase() ?? 'high';
    if (s.contains('low')) return Colors.orange[800]!;
    if (s.contains('med')) return Colors.blue[700]!;
    return const Color(0xFF2E7D32);
  }

  Widget _buildPortionSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              const Text(
                'Serving Size:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [0.5, 1.0, 1.5, 2.0].map((multiplier) {
                  final isSelected = _portionMultiplier == multiplier;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => setState(() => _portionMultiplier = multiplier),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${multiplier}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogMealSection(ColorScheme colorScheme, double carbs) {
    final mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Log Meal To:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: mealTypes.map((type) {
                    final isSelected = _selectedMealType == type;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(type, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedMealType = type);
                        },
                        selectedColor: colorScheme.secondary.withValues(alpha: 0.2),
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLogging ? null : _logMealToCareManager,
          icon: _isLogging 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.bookmark_add_rounded, size: 20),
          label: Text(
            _isLogging ? 'Logging...' : 'Log ${carbs.toStringAsFixed(0)}g Carbs to $_selectedMealType',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'none':
      case 'low':
        return Colors.green[700]!;
      case 'med':
      case 'medium':
        return Colors.orange[800]!;
      case 'high':
        return Colors.red[700]!;
      case 'very high':
      case 'extreme':
        return const Color(0xFFB71C1C);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBanner(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapSuggestion(ColorScheme colorScheme, String swap) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Clinical Smart Swap & Advice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            swap,
            style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'How Plate Scanning Works',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Snap or select a clear photo of your food plate or bowl.'),
          _buildInstructionStep('2', 'AI & ML Vision automatically identifies dishes and portion weight.'),
          _buildInstructionStep('3', 'View instant Carbs, Net Carbs, Calories, Glycemic Index & Spike Risk.'),
          _buildInstructionStep('4', 'Adjust portion size and log directly to your daily diabetes tracker.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showFoodCorrectionDialog,
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Search Food Database Directly', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
