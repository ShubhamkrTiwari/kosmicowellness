import 'package:flutter/material.dart';
import '../managers/cart_manager.dart';
import '../managers/wishlist_manager.dart';
import 'checkout_screen.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = widget.product;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Premium App Bar
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.surface.withOpacity(0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      onPressed: () => Navigator.pop(context),
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: colorScheme.surface.withOpacity(0.9),
                      child: IconButton(
                        icon: Icon(
                          WishlistManager().isWishlisted(product['name']!)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                        ),
                        color: WishlistManager().isWishlisted(product['name']!)
                            ? Colors.red
                            : colorScheme.primary,
                        onPressed: () => setState(() => WishlistManager().toggleWishlist(product)),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.05),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'product-${product['name']}',
                        child: (product['image'] != null && product['image'].toString().isNotEmpty)
                            ? Image.network(
                                product['image'].toString(),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  product['icon'] ?? '🌿',
                                  style: const TextStyle(fontSize: 160, decoration: TextDecoration.none),
                                ),
                              )
                            : Text(
                                product['icon'] ?? '🌿',
                                style: const TextStyle(fontSize: 160, decoration: TextDecoration.none),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['category']?.toUpperCase() ?? 'WELLNESS',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product['name']!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  (product['rating'] ?? '4.9').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        (product['price'] ?? '₹0').toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'The Ayurvedic Story',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (product['description'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildBenefitsGrid(colorScheme),
                      const SizedBox(height: 32),
                      _buildQuantitySelector(colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomAction(colorScheme, product),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Highlights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _highlightItem(Icons.eco_outlined, 'Organic', colorScheme)),
            Expanded(child: _highlightItem(Icons.science_outlined, 'Lab Tested', colorScheme)),
            Expanded(child: _highlightItem(Icons.auto_awesome_outlined, 'Handmade', colorScheme)),
            Expanded(child: _highlightItem(Icons.verified_outlined, 'Authentic', colorScheme)),
          ],
        ),
      ],
    );
  }

  Widget _highlightItem(IconData icon, String label, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(ColorScheme colorScheme) {
    return Row(
      children: [
        const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                icon: const Icon(Icons.remove, size: 20),
              ),
              Text(
                _quantity.toString().padLeft(2, '0'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(ColorScheme colorScheme, Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: OutlinedButton(
                onPressed: () {
                  for (int i = 0; i < _quantity; i++) {
                    CartManager().addItem(product);
                  }
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $_quantity ${product['name']} to cart'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colorScheme.primary,
                      duration: const Duration(milliseconds: 1500),
                      action: SnackBarAction(
                        label: 'View',
                        textColor: Colors.white,
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen())),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // Direct Buy: Clear cart or just add this item and go to checkout
                  // For now, let's just add to cart and go to checkout
                  CartManager().clearCart(); // Clear old items for "Buy Now"
                  for (int i = 0; i < _quantity; i++) {
                    CartManager().addItem(product);
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
