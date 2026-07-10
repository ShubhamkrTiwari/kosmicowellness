import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Bank'; // 'Bank' or 'UPI'

  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _upiIdController = TextEditingController();

  @override
  void dispose() {
    _bankAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _holderNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Type',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    title: 'Bank Account',
                    icon: Icons.account_balance_outlined,
                    isSelected: _selectedMethod == 'Bank',
                    onTap: () => setState(() => _selectedMethod = 'Bank'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTypeCard(
                    title: 'UPI ID',
                    icon: Icons.vibration_outlined,
                    isSelected: _selectedMethod == 'UPI',
                    onTap: () => setState(() => _selectedMethod = 'UPI'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedMethod == 'Bank'
                  ? Column(
                      key: const ValueKey('BankFields'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Account Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        const SizedBox(height: 20),
                        _buildTextField(controller: _holderNameController, label: 'Account Holder Name', icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _bankNameController, label: 'Bank Name', icon: Icons.business_outlined),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _bankAccountController, label: 'Account Number', icon: Icons.numbers_outlined, keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _ifscController, label: 'IFSC Code', icon: Icons.code_outlined, capitalization: TextCapitalization.characters),
                      ],
                    )
                  : Column(
                      key: const ValueKey('UPIFields'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPI Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        const SizedBox(height: 20),
                        _buildTextField(controller: _holderNameController, label: 'Display Name', icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _upiIdController, label: 'UPI ID (e.g. name@bank)', icon: Icons.alternate_email_outlined),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: isDark ? Colors.amber[200] : Colors.amber.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ensure your UPI ID is correct to avoid payment failures.',
                                  style: TextStyle(
                                    color: isDark ? Colors.amber[100] : Colors.amber.shade900, 
                                    fontSize: 12
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Payment Details Saved Successfully'),
                      backgroundColor: colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1) 
              : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 20, color: colorScheme.primary.withOpacity(0.7)),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
