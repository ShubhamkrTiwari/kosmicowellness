import 'package:flutter/material.dart';

class ProductPriceDisplay extends StatelessWidget {
  // Ye values aapko backend API se milengi
  final double sellingPrice; 
  final double originalPrice;
  final int discountPercentage; 

  const ProductPriceDisplay({
    super.key,
    required this.sellingPrice,
    required this.originalPrice,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    bool hasDiscount = originalPrice > sellingPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. Selling Price (Prominent Bold Text)
        Text(
          '₹${sellingPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(width: 8),

        // Agar original price zyada hai, tabhi MRP aur discount badge dikhayein
        if (hasDiscount) ...[
          // 2. Original Price (Muted & Strike-through)
          Text(
            '₹${originalPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough, // Katti hui line
            ),
          ),
          
          const SizedBox(width: 8),

          // 3. Discount Offer Badge (Green Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50, // Halka green background
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              '$discountPercentage% OFF',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700, // Dark green text
              ),
            ),
          ),
        ],
      ],
    );
  }
}
