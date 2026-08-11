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
  
  String _selectedTimeOfDay = 'Day';
  String _selectedReadingType = 'Post-Meal';
  String _selectedMealType = 'Lunch';

  bool _isSaving = false;

  @override
  void dispose() {
    _glucoseController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _saveEntries() async {
    setState(() => _isSaving = true);
    bool success = false;

    if (_glucoseController.text.isNotEmpty) {
      final val = double.tryParse(_glucoseController.text);
      if (val != null) {
        success = await CareManager().addGlucoseLog(val, _selectedTimeOfDay, _selectedReadingType);
      }
    }
    
    if (_carbsController.text.isNotEmpty) {
      final val = double.tryParse(_carbsController.text);
      if (val != null) {
        success = await CareManager().addMealLog(_selectedMealType, val);
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _glucoseController.clear();
        _carbsController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs synced with server successfully!'), backgroundColor: Colors.green),
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
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
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
}
