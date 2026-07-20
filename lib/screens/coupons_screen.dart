import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final List<Map<String, dynamic>> _coupons = [
    {
      'code': 'KOSMICO20',
      'discount': '20% OFF',
      'description': 'Valid on all Ayurvedic Oils and Hair Care products.',
      'expiry': 'Valid till 30 Oct, 2023',
      'color': const Color(0xFF00833E),
      'icon': Icons.eco_outlined,
    },
    {
      'code': 'WELLNESS500',
      'discount': '₹500 OFF',
      'description': 'Flat discount on orders above ₹2,499.',
      'expiry': 'Valid till 15 Nov, 2023',
      'color': const Color(0xFF1B264F),
      'icon': Icons.spa_outlined,
    },
    {
      'code': 'FIRSTORDER',
      'discount': 'FREE GIFT',
      'description': 'Get a free Ashwagandha pack on your first purchase.',
      'expiry': 'One time use only',
      'color': const Color(0xFF4CBB17),
      'icon': Icons.card_giftcard_outlined,
    },
  ];

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Coupons', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _coupons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: colorScheme.primary.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('No coupons available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return _buildCouponCard(coupon, colorScheme);
              },
            ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Section (Color bar)
              Container(
                width: 12,
                color: coupon['color'],
              ),
              
              // Middle Section (Details)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(coupon['icon'], color: coupon['color'], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              coupon['discount'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: coupon['color'],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coupon['description'],
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                coupon['code'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              coupon['expiry'],
                              textAlign: TextAlign.end,
                              style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Right Section (Copy Button)
              InkWell(
                onTap: () => _copyCode(coupon['code']),
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: coupon['color'].withValues(alpha: 0.05),
                    border: Border(left: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, color: coupon['color'], size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'COPY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: coupon['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
