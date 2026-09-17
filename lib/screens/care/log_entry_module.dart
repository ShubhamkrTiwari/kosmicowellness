import 'package:flutter/material.dart';
import '../../managers/care_manager.dart';

class LogEntryModule extends StatefulWidget {
  const LogEntryModule({super.key});

  @override
  State<LogEntryModule> createState() => _LogEntryModuleState();
}

class _LogEntryModuleState extends State<LogEntryModule> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _insulinController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();
  
  String _selectedTimeOfDay = 'Day';
  String _selectedReadingType = 'Post-Meal';
  String _selectedMealType = 'Lunch';
  int _selectedStressLevel = 0;
  int _selectedEnergyLevel = 0;

  bool _isSaving = false;

  @override
  void dispose() {
    _glucoseController.dispose();
    _carbsController.dispose();
    _waterController.dispose();
    _insulinController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  Future<void> _saveEntries() async {
    setState(() => _isSaving = true);
    final manager = CareManager();
    bool anySuccess = false;

    if (_glucoseController.text.isNotEmpty) {
      final val = double.tryParse(_glucoseController.text);
      if (val != null) {
        anySuccess = await manager.addGlucoseLog(val, _selectedTimeOfDay, _selectedReadingType);
      }
    }
    
    if (_carbsController.text.isNotEmpty) {
      final val = double.tryParse(_carbsController.text);
      if (val != null) {
        anySuccess = await manager.addMealLog(_selectedMealType, val);
      }
    }

    if (_waterController.text.isNotEmpty) {
      final val = int.tryParse(_waterController.text);
      if (val != null) {
        await manager.addWater(val);
        anySuccess = true;
      }
    }

    if (_selectedStressLevel > 0) {
      await manager.setStressLevel(_selectedStressLevel);
      anySuccess = true;
    }

    if (_selectedEnergyLevel > 0) {
      await manager.setEnergyLevel(_selectedEnergyLevel);
      anySuccess = true;
    }

    if (_insulinController.text.isNotEmpty) {
      final val = double.tryParse(_insulinController.text);
      if (val != null) {
        await manager.addInsulinLog(val, _selectedTimeOfDay);
        anySuccess = true;
      }
    }

    if (_medicationController.text.isNotEmpty) {
      await manager.addMedicationLog('Medication', _medicationController.text);
      anySuccess = true;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (anySuccess) {
        _glucoseController.clear();
        _carbsController.clear();
        _waterController.clear();
        _insulinController.clear();
        _medicationController.clear();
        setState(() {
          _selectedStressLevel = 0;
          _selectedEnergyLevel = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health logs updated successfully!'), backgroundColor: Colors.green),
        );
      } else if (_glucoseController.text.isEmpty && _carbsController.text.isEmpty && _waterController.text.isEmpty && _selectedStressLevel == 0 && _insulinController.text.isEmpty && _medicationController.text.isEmpty && _selectedEnergyLevel == 0) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one log.'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync logs. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          
          _buildLogCategory('Glucose Reading', [
            _buildLogItem('Glucose', 'mg/dL', Icons.bloodtype, Colors.red, colorScheme, _glucoseController),
            const SizedBox(height: 8),
            _buildLogItem('Insulin', 'units', Icons.colorize, Colors.purple, colorScheme, _insulinController),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDropdown('Time of Day', ['Dawn', 'Day', 'Dusk', 'Night'], _selectedTimeOfDay, (v) => setState(() => _selectedTimeOfDay = v!))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Type', ['Fasting', 'Post-Meal', 'Random'], _selectedReadingType, (v) => setState(() => _selectedReadingType = v!))),
              ],
            ),
          ], colorScheme),
          
          const SizedBox(height: 24),
          
          _buildLogCategory('Meal Log', [
            _buildLogItem('Carbs', 'grams', Icons.restaurant, Colors.orange, colorScheme, _carbsController),
            const SizedBox(height: 8),
            _buildDropdown('Meal Type', ['Breakfast', 'Lunch', 'Dinner', 'Snack'], _selectedMealType, (v) => setState(() => _selectedMealType = v!)),
          ], colorScheme),

          const SizedBox(height: 24),
          
          _buildLogCategory('Medication & Lifestyle', [
            _buildLogItem('Medication', 'dose', Icons.medication, Colors.teal, colorScheme, _medicationController),
            const SizedBox(height: 12),
            _buildLogItem('Water', 'ml', Icons.water_drop, Colors.blue, colorScheme, _waterController),
            const SizedBox(height: 16),
            const Text('Energy Level', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildEmojiSelector(5, _selectedEnergyLevel, (l) => setState(() => _selectedEnergyLevel = l), _getEnergyEmoji, colorScheme),
            const SizedBox(height: 16),
            const Text('Stress Level', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildEmojiSelector(5, _selectedStressLevel, (l) => setState(() => _selectedStressLevel = l), _getStressEmoji, colorScheme),
          ], colorScheme),

          const SizedBox(height: 32),
          _buildRecentLogs(colorScheme),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveEntries,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sync to Dashboard'),
            ),
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

  Widget _buildLogCategory(String title, List<Widget> items, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildLogItem(String label, String unit, IconData icon, Color color, ColorScheme colorScheme, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label, 
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '0',
                suffixText: unit,
                suffixStyle: const TextStyle(fontSize: 10),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
                border: InputBorder.none,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiSelector(int count, int selectedValue, Function(int) onTap, String Function(int) getEmoji, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (index) {
        final int l = index + 1;
        final bool isSelected = selectedValue == l;
        return GestureDetector(
          onTap: () => onTap(l),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Text(
              getEmoji(l),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRecentLogs(ColorScheme colorScheme) {
    final manager = CareManager();
    final glucoseLogs = manager.glucoseCurve;
    
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (glucoseLogs.isEmpty)
            const Text('No recent logs found.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...glucoseLogs.reversed.take(3).map((log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Glucose: ${log['level']} mg/dL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${log['timeOfDay']} • ${log['logTime']?.toString().split('T').last.substring(0, 5) ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (log['notes']?.toString().contains('Insulin') ?? false)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Insulin Logged', style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _getEnergyEmoji(int level) {
    switch (level) {
      case 1: return '😴';
      case 2: return '🥱';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '⚡';
      default: return '❓';
    }
  }

  String _getStressEmoji(int level) {
    switch (level) {
      case 1: return '😊';
      case 2: return '🙂';
      case 3: return '😐';
      case 4: return '😟';
      case 5: return '😫';
      default: return '❓';
    }
  }
}
