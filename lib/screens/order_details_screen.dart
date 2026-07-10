import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, String> order;

  const OrderDetailsScreen({super.key, required this.order});

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
          'Order Details',
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
            // Order Tracking Stepper
            _buildSectionTitle('Track Order', colorScheme),
            const SizedBox(height: 16),
            _buildTrackingStepper(colorScheme),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Items', colorScheme),
            const SizedBox(height: 16),
            _buildItemCard(order, colorScheme),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Delivery Address', colorScheme),
            const SizedBox(height: 16),
            _buildAddressCard(colorScheme),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Payment Summary', colorScheme),
            const SizedBox(height: 16),
            _buildPaymentSummary(order['price']!, colorScheme),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.help_outline),
                label: const Text('Need Help?'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildTrackingStepper(ColorScheme colorScheme) {
    final steps = [
      {'title': 'Order Placed', 'date': '22 Oct, 10:30 AM', 'done': true},
      {'title': 'Packed', 'date': '23 Oct, 02:15 PM', 'done': true},
      {'title': 'In Transit', 'date': '24 Oct, 09:00 AM', 'done': true},
      {'title': 'Delivered', 'date': 'Expected by 26 Oct', 'done': false},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final bool isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: step['done'] as bool ? colorScheme.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: step['done'] as bool
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step['done'] as bool ? colorScheme.primary : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: step['done'] as bool ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Text(
                    step['date'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemCard(Map<String, String> order, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(order['icon']!, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['items']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Quantity: 1', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(
            order['price']!,
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shubham Tiwari', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '123 Ayurveda Street, Wellness District\nMumbai, Maharashtra 400001\n+91 98765 43210',
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(String price, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', price, false),
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery Fee', '₹40', false),
          const SizedBox(height: 8),
          _buildSummaryRow('Discount', '-₹40', true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildSummaryRow('Total Amount', price, false, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDiscount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : (isTotal ? Colors.black : Colors.black87),
          ),
        ),
      ],
    );
  }
}
