import 'package:flutter/material.dart';
import '../managers/payment_manager.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? editMethod;
  const PaymentScreen({super.key, this.editMethod});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String _selectedMethod;
  late bool _isDefault;
  bool _isSavingLocal = false;

  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _upiIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final method = widget.editMethod;
    if (method != null) {
      _selectedMethod = method['type'] == 'BANK_ACCOUNT' ? 'Bank' : 'UPI';
      _isDefault = method['isDefault'] == true;
      
      if (_selectedMethod == 'Bank') {
        _holderNameController.text = method['accountHolderName'] ?? '';
        _bankNameController.text = method['bankName'] ?? '';
        _bankAccountController.text = method['accountNumber'] ?? '';
        _ifscController.text = method['ifscCode'] ?? '';
      } else {
        _holderNameController.text = method['displayName'] ?? '';
        _upiIdController.text = method['upiId'] ?? '';
      }
    } else {
      _selectedMethod = 'Bank';
      _isDefault = false;
    }
  }

  @override
  void dispose() {
    _bankAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _holderNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _savePaymentMethod() async {
    if (_isSavingLocal) return;

    Map<String, dynamic> method;
    if (_selectedMethod == 'Bank') {
      if (_bankAccountController.text.trim().isEmpty || 
          _ifscController.text.trim().isEmpty || 
          _holderNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
      method = {
        "type": "BANK_ACCOUNT",
        "accountHolderName": _holderNameController.text.trim(),
        "bankName": _bankNameController.text.trim(),
        "accountNumber": _bankAccountController.text.trim(),
        "ifscCode": _ifscController.text.trim(),
        "isDefault": _isDefault,
      };
    } else {
      if (_upiIdController.text.trim().isEmpty || _holderNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
      method = {
        "type": "UPI",
        "upiId": _upiIdController.text.trim(),
        "upild": _upiIdController.text.trim(), // Send both for compatibility
        "displayName": _holderNameController.text.trim(),
        "isDefault": _isDefault,
      };
    }

    setState(() => _isSavingLocal = true);

    try {
      bool success;
      if (widget.editMethod != null) {
        final id = widget.editMethod!['_id'] ?? widget.editMethod!['id'];
        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Payment Method ID not found.'), backgroundColor: Colors.red),
          );
          setState(() => _isSavingLocal = false);
          return;
        }
        success = await PaymentManager().updatePaymentMethodById(id.toString(), method);
      } else {
        success = await PaymentManager().savePaymentMethod(method);
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editMethod != null ? 'Details Updated Successfully' : 'Payment Details Saved Successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final errorMsg = PaymentManager().lastError ?? 'Failed to save details. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingLocal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editMethod != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Payment Method' : 'Add Payment Method', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            if (!isEditing) ...[
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
                      logo: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/2830/2830284.png', // Professional Bank/Building Icon
                        height: 32,
                        width: 32,
                        color: _selectedMethod == 'Bank' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.account_balance, 
                          size: 32,
                          color: _selectedMethod == 'Bank' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      isSelected: _selectedMethod == 'Bank',
                      onTap: _isSavingLocal ? () {} : () => setState(() => _selectedMethod = 'Bank'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeCard(
                      title: 'UPI ID',
                      logo: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/UPI-Logo-vector.svg/640px-UPI-Logo-vector.svg.png', // Official UPI Logo
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.qr_code_scanner, 
                          size: 32,
                          color: _selectedMethod == 'UPI' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      isSelected: _selectedMethod == 'UPI',
                      onTap: _isSavingLocal ? () {} : () => setState(() => _selectedMethod = 'UPI'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedMethod == 'Bank'
                  ? Column(
                      key: const ValueKey('BankFields'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Account Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        const SizedBox(height: 20),
                        _buildTextField(controller: _holderNameController, label: 'Account Holder Name', icon: Icons.person_outline, enabled: !_isSavingLocal),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _bankNameController, label: 'Bank Name', icon: Icons.business_outlined, enabled: !_isSavingLocal),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _bankAccountController, label: 'Account Number', icon: Icons.numbers_outlined, keyboardType: TextInputType.number, enabled: !_isSavingLocal),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _ifscController, label: 'IFSC Code', icon: Icons.code_outlined, capitalization: TextCapitalization.characters, enabled: !_isSavingLocal),
                      ],
                    )
                  : Column(
                      key: const ValueKey('UPIFields'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPI Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        const SizedBox(height: 20),
                        _buildTextField(controller: _holderNameController, label: 'Display Name', icon: Icons.person_outline, enabled: !_isSavingLocal),
                        const SizedBox(height: 16),
                        _buildTextField(controller: _upiIdController, label: 'UPI ID (e.g. name@bank)', icon: Icons.alternate_email_outlined, enabled: !_isSavingLocal),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
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
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Set as Default Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              value: _isDefault,
              onChanged: _isSavingLocal ? null : (val) => setState(() => _isDefault = val),
              activeThumbColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSavingLocal ? null : _savePaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSavingLocal 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Update Details' : 'Save Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required Widget logo,
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
              ? colorScheme.primary.withValues(alpha: 0.1) 
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: logo,
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
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      enabled: enabled,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 20, color: colorScheme.primary.withValues(alpha: 0.7)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
