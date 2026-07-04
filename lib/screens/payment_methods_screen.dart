import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _paymentMethods = [
    {
      'type': 'Visa',
      'number': '**** **** **** 4582',
      'expiry': '09/26',
      'color': '0xFF1A237E',
    },
    {
      'type': 'Mastercard',
      'number': '**** **** **** 9210',
      'expiry': '12/25',
      'color': '0xFF37474F',
    },
    {
      'type': 'UPI',
      'number': 'shubham@okaxis',
      'expiry': '',
      'color': '0xFF2E7D32',
    },
  ];

  void _showPaymentBottomSheet({int? index}) {
    final isEditing = index != null;
    final method = isEditing ? _paymentMethods[index] : null;

    final typeController = TextEditingController(text: method?['type'] ?? 'Visa');
    final numberController = TextEditingController(text: method?['number'] ?? '');
    final expiryController = TextEditingController(text: method?['expiry'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Payment Method' : 'Add Payment Method',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: typeController.text,
              decoration: _inputDecoration('Method Type'),
              items: ['Visa', 'Mastercard', 'UPI']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => typeController.text = val!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              decoration: _inputDecoration('Card Number / UPI ID'),
            ),
            const SizedBox(height: 16),
            if (typeController.text != 'UPI')
              TextField(
                controller: expiryController,
                decoration: _inputDecoration('Expiry (MM/YY)'),
              ),
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
                      'color': typeController.text == 'Visa' 
                          ? '0xFF1A237E' 
                          : typeController.text == 'Mastercard' 
                              ? '0xFF37474F' 
                              : '0xFF2E7D32',
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
                ),
                child: Text(isEditing ? 'Update Method' : 'Save Method'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
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
        title: Text(
          'Payment Methods',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Saved Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_paymentMethods.length, (index) {
              return _buildPaymentCard(_paymentMethods[index], index, colorScheme);
            }),
            const SizedBox(height: 24),
            _buildAddMethodButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, String> method, int index, ColorScheme colorScheme) {
    final bool isCard = method['type'] != 'UPI';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(method['color']!)),
            Color(int.parse(method['color']!)).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(method['color']!)).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              method['type'] == 'Visa' ? Icons.credit_card : Icons.account_balance_wallet,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      method['type']!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showPaymentBottomSheet(index: index);
                        } else if (value == 'delete') {
                          setState(() => _paymentMethods.removeAt(index));
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  method['number']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),
                if (isCard)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HOLDER NAME', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text('SHUBHAM TIWARI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPIRY', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text(method['expiry']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                else
                  const Text('UPI ID Linked', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMethodButton(ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _showPaymentBottomSheet(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Add New Payment Method',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
