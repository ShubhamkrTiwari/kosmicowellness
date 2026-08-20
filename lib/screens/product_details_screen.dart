import 'package:flutter/material.dart';
import '../utils/keys.dart'; // Add this for scaffoldMessengerKey
import '../managers/cart_manager.dart';
import '../managers/language_manager.dart';
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
  void initState() {
    super.initState();
    final product = widget.product;
    final dynamic stockRaw = product['countInStock'] ?? product['stock'] ?? product['inventory'] ?? product['quantity'] ?? product['qty'];
    final int availableStock = stockRaw != null ? (int.tryParse(stockRaw.toString()) ?? 999) : 999;
    if (availableStock <= 0) {
      _quantity = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = widget.product;
    
    // Debug: Print full product JSON to help identify correct keys
    debugPrint('DEBUG: Product details JSON: $product');

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
                                // Feature Tags
                                if (product['name']?.toString().toLowerCase().contains('sweet monk') ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        _buildFeatureTag('Zero Calories', Icons.close, const Color(0xFFFF6B6B), colorScheme),
                                        const SizedBox(width: 8),
                                        _buildFeatureTag('100% Natural', Icons.eco, const Color(0xFF4CAF50), colorScheme),
                                      ],
                                    ),
                                  ),
                                Builder(
                                  builder: (context) {
                                    final String rawCat = product['category']?.toString() ?? 'wellness';
                                    String catDisplay = rawCat.replaceAll('_', ' ');
                                    if (catDisplay.toLowerCase().contains('essesntials')) {
                                      catDisplay = catDisplay.toLowerCase().replaceFirst('essesntials', 'essential');
                                    }
                                    catDisplay = catDisplay.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
                                    
                                    return Text(
                                      catDisplay.toUpperCase(),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                      ),
                                    );
                                  }
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product['name']!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Builder(
                            builder: (context) {
                              final dynamic ratingRaw = product['rating'] ?? product['avgRating'];
                              final double rating = double.tryParse(ratingRaw?.toString() ?? '') ?? 0.0;
                              
                              final dynamic reviewsRaw = product['reviews'] ?? product['numReviews'] ?? product['reviewsCount'];
                              int reviewCount = 0;
                              if (reviewsRaw is List) {
                                reviewCount = reviewsRaw.length;
                              } else if (reviewsRaw != null) {
                                reviewCount = int.tryParse(reviewsRaw.toString()) ?? 0;
                              }

                              // Use actual ratings from API
                              final String displayRating = rating.toStringAsFixed(1);
                              final String displayReviews = '($reviewCount)';

                              if (reviewCount == 0 && rating == 0) {
                                return const SizedBox.shrink(); // Hide rating if no reviews yet
                              }

                              return Container(
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
                                      displayRating,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayReviews,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '₹${(product['price'] ?? 0).toString().replaceAll('₹', '').trim()}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.secondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        LanguageManager().translate('ayurvedic_story'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (product['description'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildBenefitsGrid(colorScheme),
                      const SizedBox(height: 32),
                      _buildSpecsGrid(product, colorScheme),
                      const SizedBox(height: 32),
                      _buildKeyBenefits(product, colorScheme),
                      const SizedBox(height: 32),
                      _buildIngredients(product, colorScheme),
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

  Widget _buildSpecsGrid(Map<String, dynamic> product, ColorScheme colorScheme) {
    final lang = LanguageManager();
    // Robust key extraction to handle different naming conventions from API/Admin
    final String sku = (product['sku'] ?? product['product_id'] ?? product['SKU'] ?? 'N/A').toString();
    final String brand = (product['brand'] ?? product['manufacturer'] ?? product['vendor'] ?? 'Kosmico Wellness').toString();
    final dynamic stockRaw = product['countInStock'] ?? product['stock'] ?? product['inventory'] ?? product['quantity'] ?? product['qty'];
    final String shelfLife = (product['shelfLife'] ?? product['shelf_life'] ?? product['expiry'] ?? '24 months').toString();
    final String origin = (product['origin'] ?? product['madeIn'] ?? product['country'] ?? 'India').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.translate('brand'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(brand, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _specItem('SKU', sku, Icons.qr_code_scanner, colorScheme)),
                  Container(width: 1, height: 40, color: colorScheme.outline.withValues(alpha: 0.1)),
                  Expanded(
                    child: _specItem(
                      lang.translate('stock_status'), 
                      stockRaw != null ? '${lang.translate('in_stock')} ($stockRaw)' : lang.translate('in_stock'), 
                      Icons.inventory_2_outlined, 
                      colorScheme, 
                      valueColor: Colors.green
                    )
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              Row(
                children: [
                  Expanded(child: _specItem(lang.translate('shelf_life'), shelfLife, Icons.history_toggle_off_rounded, colorScheme)),
                  Container(width: 1, height: 40, color: colorScheme.outline.withValues(alpha: 0.1)),
                  Expanded(child: _specItem(lang.translate('made_in'), origin, Icons.public_rounded, colorScheme)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _specItem(String label, String value, IconData icon, ColorScheme colorScheme, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
      ],
    );
  }

  Widget _buildKeyBenefits(Map<String, dynamic> product, ColorScheme colorScheme) {
    // Try multiple possible keys from API
    final dynamic benefitsRaw = product['keyBenefits'] ?? product['benefits'] ?? product['key_benefits'];
    
    List<String> benefits = [];
    if (benefitsRaw is List) {
      benefits = benefitsRaw.map((e) => e.toString()).toList();
    } else if (benefitsRaw is String && benefitsRaw.isNotEmpty) {
      // If it's a comma-separated string or has newlines, split it
      if (benefitsRaw.contains('\n')) {
        benefits = benefitsRaw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (benefitsRaw.contains(',')) {
        benefits = benefitsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        benefits = [benefitsRaw];
      }
    }

    // Strictly hide if no data from admin
    if (benefits.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(LanguageManager().translate('key_benefits'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(benefit, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildIngredients(Map<String, dynamic> product, ColorScheme colorScheme) {
    // Try multiple possible keys from API
    final dynamic ingRaw = product['ingredients'] ?? product['key_ingredients'] ?? product['ingredientsList'];
    
    List<String> ingredients = [];
    if (ingRaw is List) {
      ingredients = ingRaw.map((e) => e.toString()).toList();
    } else if (ingRaw is String && ingRaw.isNotEmpty) {
      if (ingRaw.contains('\n')) {
        ingredients = ingRaw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (ingRaw.contains(',')) {
        ingredients = ingRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        ingredients = [ingRaw];
      }
    }

    // Strictly hide if no data from admin
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LanguageManager().translate('ingredients'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ingredients.map((ing) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌿', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(ing, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBenefitsGrid(ColorScheme colorScheme) {
    final lang = LanguageManager();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('product_highlights'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _highlightItem(Icons.eco_outlined, lang.translate('organic'), colorScheme)),
            Expanded(child: _highlightItem(Icons.science_outlined, lang.translate('lab_tested'), colorScheme)),
            Expanded(child: _highlightItem(Icons.auto_awesome_outlined, lang.translate('handmade'), colorScheme)),
            Expanded(child: _highlightItem(Icons.verified_outlined, lang.translate('authentic'), colorScheme)),
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
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFeatureTag(String text, IconData icon, Color iconColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(ColorScheme colorScheme) {
    final product = widget.product;
    final dynamic stockRaw = product['countInStock'] ?? product['stock'] ?? product['inventory'] ?? product['quantity'] ?? product['qty'];
    final int availableStock = stockRaw != null ? (int.tryParse(stockRaw.toString()) ?? 999) : 999;

    if (availableStock <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text(
              'Sorry, this item is currently Out of Stock',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Text(LanguageManager().translate('quantity'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                onPressed: () {
                  if (_quantity < availableStock) {
                    setState(() => _quantity++);
                  } else {
                    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Only $availableStock items available in stock.')),
                          ],
                        ),
                        backgroundColor: Colors.orange[800],
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.add, 
                  size: 20, 
                  color: _quantity >= availableStock ? colorScheme.onSurface.withValues(alpha: 0.3) : null
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(ColorScheme colorScheme, Map<String, dynamic> product) {
    final dynamic stockRaw = product['countInStock'] ?? product['stock'] ?? product['inventory'] ?? product['quantity'] ?? product['qty'];
    final int availableStock = stockRaw != null ? (int.tryParse(stockRaw.toString()) ?? 999) : 999;
    final bool isOutOfStock = availableStock <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                onPressed: isOutOfStock ? null : () {
                  final cart = CartManager();
                  if (cart.canAddMore(product, _quantity)) {
                    cart.addItem(product, qtyToAdd: _quantity);
                    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text('$_quantity x ${product['name']} added to cart!')),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colorScheme.primary,
                        duration: const Duration(milliseconds: 2000),
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } else {
                    final int inCart = cart.getProductQuantity(product['name'] ?? '');
                    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Stock Limit: Only ${availableStock - inCart} more can be added (You have $inCart in cart).',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isOutOfStock ? colorScheme.outline : colorScheme.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isOutOfStock ? LanguageManager().translate('out_of_stock') : LanguageManager().translate('add_to_cart'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : () {
                  final cart = CartManager();
                  if (_quantity <= availableStock) {
                    cart.clearCart(); 
                    cart.addItem(product, qtyToAdd: _quantity);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                  } else {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Only $availableStock items left in stock!'), 
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isOutOfStock ? LanguageManager().translate('out_of_stock') : LanguageManager().translate('buy_now'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
