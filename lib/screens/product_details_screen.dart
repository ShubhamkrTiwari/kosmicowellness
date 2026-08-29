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
                          colorScheme.primaryContainer.withValues(alpha: 0.1),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'product-${product['name']}',
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: (product['image'] != null && product['image'].toString().isNotEmpty)
                              ? Image.network(
                                  product['image'].toString(),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    product['icon'] ?? '🌿',
                                    style: const TextStyle(fontSize: 140, decoration: TextDecoration.none),
                                  ),
                                )
                              : Text(
                                  product['icon'] ?? '🌿',
                                  style: const TextStyle(fontSize: 140, decoration: TextDecoration.none),
                                ),
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
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        catDisplay.toUpperCase(),
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    );
                                  }
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  product['name']!,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    height: 1.2,
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
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayRating,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayReviews,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            (product['price'] ?? 0).toString().replaceAll('₹', '').trim(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LanguageManager().translate('inclusive_of_taxes').replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildDescriptionCard(product, colorScheme),
                      const SizedBox(height: 24),
                      _buildBenefitsGrid(colorScheme),
                      const SizedBox(height: 24),
                      _buildSpecsGrid(product, colorScheme),
                      const SizedBox(height: 24),
                      _buildKeyBenefits(product, colorScheme),
                      const SizedBox(height: 24),
                      _buildIngredients(product, colorScheme),
                      const SizedBox(height: 24),
                      _buildTrustBadges(colorScheme),
                      const SizedBox(height: 24),
                      _buildQuantitySelector(colorScheme),
                      const SizedBox(height: 40),
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

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme, {Color? iconColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(Map<String, dynamic> product, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            LanguageManager().translate('ayurvedic_story').replaceAll('_', ' ').toUpperCase(), 
            Icons.history_edu_rounded, 
            colorScheme
          ),
          const SizedBox(height: 16),
          Text(
            (product['description'] ?? '').toString(),
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(Map<String, dynamic> product, ColorScheme colorScheme) {
    final lang = LanguageManager();
    final String sku = (product['sku'] ?? product['product_id'] ?? product['SKU'] ?? 'N/A').toString();
    final String brand = (product['brand'] ?? product['manufacturer'] ?? product['vendor'] ?? 'Kosmico Wellness').toString();
    final dynamic stockRaw = product['countInStock'] ?? product['stock'] ?? product['inventory'] ?? product['quantity'] ?? product['qty'];
    final String shelfLife = (product['shelfLife'] ?? product['shelf_life'] ?? product['expiry'] ?? '24 months').toString();
    final String origin = (product['origin'] ?? product['madeIn'] ?? product['country'] ?? 'India').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(lang.translate('product_specifications').replaceAll('_', ' ').toUpperCase(), Icons.info_outline_rounded, colorScheme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _specRow('Brand', brand, Icons.business_rounded, colorScheme),
              const Divider(height: 24, thickness: 0.5),
              _specRow('SKU ID', sku, Icons.qr_code_2_rounded, colorScheme),
              const Divider(height: 24, thickness: 0.5),
              _specRow('Shelf Life', shelfLife, Icons.timer_outlined, colorScheme),
              const Divider(height: 24, thickness: 0.5),
              _specRow('Origin', origin, Icons.location_on_outlined, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _specRow(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label, 
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildKeyBenefits(Map<String, dynamic> product, ColorScheme colorScheme) {
    final dynamic benefitsRaw = product['keyBenefits'] ?? product['benefits'] ?? product['key_benefits'];
    
    List<String> benefits = [];
    if (benefitsRaw is List) {
      benefits = benefitsRaw.map((e) => e.toString()).toList();
    } else if (benefitsRaw is String && benefitsRaw.isNotEmpty) {
      if (benefitsRaw.contains('\n')) {
        benefits = benefitsRaw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (benefitsRaw.contains(',')) {
        benefits = benefitsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        benefits = [benefitsRaw];
      }
    }

    if (benefits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LanguageManager().translate('key_benefits').replaceAll('_', ' ').toUpperCase(), Icons.auto_awesome_rounded, colorScheme),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary.withValues(alpha: 0.08), colorScheme.primary.withValues(alpha: 0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.verified_rounded, color: colorScheme.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredients(Map<String, dynamic> product, ColorScheme colorScheme) {
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

    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LanguageManager().translate('ingredients').replaceAll('_', ' ').toUpperCase(), Icons.eco_rounded, colorScheme, iconColor: const Color(0xFF4CAF50)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ingredients.map((ing) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Text(
                    ing, 
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    )
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsGrid(ColorScheme colorScheme) {
    final lang = LanguageManager();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(lang.translate('product_highlights').replaceAll('_', ' ').toUpperCase(), Icons.star_outline_rounded, colorScheme),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _highlightCard(Icons.eco_outlined, lang.translate('organic'), colorScheme),
            _highlightCard(Icons.science_outlined, lang.translate('lab_tested'), colorScheme),
            _highlightCard(Icons.auto_awesome_outlined, lang.translate('handmade'), colorScheme),
            _highlightCard(Icons.verified_outlined, lang.translate('authentic'), colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _highlightCard(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w700, 
                color: colorScheme.onSurface.withValues(alpha: 0.8)
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _trustBadge(Icons.verified_user_rounded, 'Certified', colorScheme),
          _trustBadge(Icons.health_and_safety_rounded, 'Non-GMO', colorScheme),
          _trustBadge(Icons.biotech_rounded, 'Lab Tested', colorScheme),
          _trustBadge(Icons.nature_people_rounded, 'Ethical', colorScheme),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary.withValues(alpha: 0.4), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTag(String text, IconData icon, Color iconColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
            SizedBox(width: 12),
            Text(
              'Currently Out of Stock',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageManager().translate('quantity'), 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)
              ),
              Text(
                'Select units',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                  icon: Icon(Icons.remove_circle_outline_rounded, size: 24, color: colorScheme.primary),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  alignment: Alignment.center,
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
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
                    Icons.add_circle_outline_rounded, 
                    size: 24, 
                    color: _quantity >= availableStock ? colorScheme.onSurface.withValues(alpha: 0.2) : colorScheme.primary
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(ColorScheme colorScheme, Map<String, dynamic> product) {
    final dynamic stockRaw = product['countInStock'] ?? product['stock'] ?? product['inventory'] ?? product['quantity'] ?? product['qty'];
    final int availableStock = stockRaw != null ? (int.tryParse(stockRaw.toString()) ?? 999) : 999;
    final bool isOutOfStock = availableStock <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isOutOfStock ? LanguageManager().translate('out_of_stock') : LanguageManager().translate('add_to_cart').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.1),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isOutOfStock)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isOutOfStock ? LanguageManager().translate('out_of_stock') : LanguageManager().translate('buy_now').toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1),
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
