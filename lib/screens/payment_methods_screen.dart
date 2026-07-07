import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _paymentMethods = [
    {
      'type': 'Bank',
      'number': 'A/C: ****4582',
      'expiry': 'IFSC: KOSM000123',
      'holder': 'Shubham Tiwari',
      'color': '0xFF1B264F', // Logo Navy
    },
    {
      'type': 'UPI',
      'number': 'shubham@okaxis',
      'expiry': '',
      'holder': 'Shubham Tiwari',
      'color': '0xFF00833E', // Logo Green
    },
  ];

  void _showPaymentBottomSheet({int? index}) {
    final isEditing = index != null;
    final method = isEditing ? _paymentMethods[index] : null;

    final typeController = TextEditingController(text: method?['type'] ?? 'Bank');
    final numberController = TextEditingController(text: method?['number'] ?? '');
    final expiryController = TextEditingController(text: method?['expiry'] ?? '');
    final holderController = TextEditingController(text: method?['holder'] ?? 'Shubham Tiwari');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(
                isEditing ? 'Update Method' : 'New Payment Method',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(holderController, 'Card Holder Name', Icons.person_outline),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: _inputDecoration('Method Type', Icons.category_outlined),
                items: ['Bank', 'UPI']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => typeController.text = val!),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                numberController, 
                typeController.text == 'Bank' ? 'Account Number' : 'UPI ID', 
                Icons.payment_outlined
              ),
              const SizedBox(height: 16),
              if (typeController.text == 'Bank')
                _buildModernTextField(expiryController, 'IFSC Code', Icons.account_balance_outlined),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final newData = {
                        'type': typeController.text,
                        'number': numberController.text,
                        'expiry': expiryController.text,
                        'holder': holderController.text,
                        'color': typeController.text == 'Visa' 
                            ? '0xFF1B264F' 
                            : typeController.text == 'Mastercard' 
                                ? '0xFF00833E' 
                                : '0xFF424242',
                      };
                      if (isEditing) {
                        _paymentMethods[index] = newData;
                      } else {
                        _paymentMethods.add(newData);
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(isEditing ? 'Update Method' : 'Save Method', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saved Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => _showPaymentBottomSheet(), child: Text('+ Add New', style: TextStyle(color: colorScheme.primary))),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_paymentMethods.length, (index) {
              return _buildPremiumPaymentCard(_paymentMethods[index], index, colorScheme);
            }),
            const SizedBox(height: 32),
            _buildSecurityInfo(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPaymentCard(Map<String, String> method, int index, ColorScheme colorScheme) {
    final bool isCard = method['type'] != 'UPI';
    final Color cardColor = Color(int.parse(method['color']!));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Abstract Background Shapes
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05)),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: CircleAvatar(radius: 80, backgroundColor: Colors.black.withValues(alpha: 0.05)),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          method['type']!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit Details'), onTap: () { Navigator.pop(context); _showPaymentBottomSheet(index: index); }),
                                ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Remove Method', style: TextStyle(color: Colors.red)), onTap: () { setState(() => _paymentMethods.removeAt(index)); Navigator.pop(context); }),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    method['number']!,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SAVED DETAILS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(method['holder']!.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      if (method['type'] == 'Bank')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('IFSC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(method['expiry']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: colorScheme.primary, size: 30),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('Your payment details are encrypted and stored securely.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
