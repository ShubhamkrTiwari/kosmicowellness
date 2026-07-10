import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import '../managers/cart_manager.dart';
import '../managers/wishlist_manager.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<String> _categories = ['All', 'Hair Care', 'Skin Care', 'Nutrition', 'Digestion'];

  final List<Map<String, String>> products = [
    {
      'name': 'Ayurvedic Hair Oil',
      'description': 'Traditional formula with bhringraj & amla for thick growth.',
      'price': '₹499',
      'icon': '🌿',
      'category': 'Hair Care',
      'rating': '4.8',
      'reviews': '1.2k',
    },
    {
      'name': 'Active Protein Powder',
      'description': 'Herbal blend with ashwagandha for strength and vitality.',
      'price': '₹1,299',
      'icon': '💪',
      'category': 'Nutrition',
      'rating': '4.9',
      'reviews': '850',
    },
    {
      'name': 'Diabetes Care',
      'description': 'Natural support with karela & jamun for blood sugar.',
      'price': '₹350',
      'icon': '🩸',
      'category': 'Nutrition',
      'rating': '4.7',
      'reviews': '2.4k',
    },
    {
      'name': 'Liver Care Capsules',
      'description': 'Detoxification and health with kutki & punarnava.',
      'price': '₹450',
      'icon': '✨',
      'category': 'Digestion',
      'rating': '4.6',
      'reviews': '500',
    },
    {
      'name': 'Amla Juice',
      'description': 'Pure organic amla juice for immunity and digestion.',
      'price': '₹299',
      'icon': '🥤',
      'category': 'Digestion',
      'rating': '4.8',
      'reviews': '3.1k',
    },
    {
      'name': 'Face Glow Cream',
      'description': 'Saffron and turmeric based natural skin brightening.',
      'price': '₹599',
      'icon': '🧴',
      'category': 'Skin Care',
      'rating': '4.5',
      'reviews': '1.5k',
    },
  ];

  List<Map<String, String>> get _filteredProducts {
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product['category'] == _selectedCategory;
      final matchesSearch = product['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredList = _filteredProducts;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Scrolling Header
            SliverToBoxAdapter(
              child: _buildHeader(colorScheme),
            ),
            // Search Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(colorScheme),
            ),
            // Categories
            SliverToBoxAdapter(
              child: _buildCategories(colorScheme),
            ),
            // The List of Products
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              sliver: filteredList.isEmpty 
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No products found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildProductListItem(filteredList[index], colorScheme);
                      },
                      childCount: filteredList.length,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wellness Catalog',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Handpicked Ayurvedic Essentials',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: colorScheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategories(ColorScheme colorScheme) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected
                      ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(Map<String, String> product, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product-${product['name']}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  product['icon']!,
                  style: const TextStyle(fontSize: 45, decoration: TextDecoration.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product['category']!.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(
                        WishlistManager().isWishlisted(product['name']!)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: WishlistManager().isWishlisted(product['name']!)
                            ? Colors.red
                            : Colors.grey[300],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        product['rating']!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${product['reviews']})',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['price']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          color: colorScheme.primary,
                        ),
                      ),
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          final quantity = CartManager().getProductQuantity(product['name']!);
                          return ElevatedButton(
                            onPressed: () {
                              CartManager().addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to cart'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: colorScheme.primary,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              minimumSize: const Size(60, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              quantity > 0 ? 'Add ($quantity)' : 'Add',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
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
}
