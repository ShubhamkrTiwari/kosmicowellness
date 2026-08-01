import 'dart:async';

import 'package:flutter/material.dart';
import '../managers/notification_manager.dart';
import '../models/filter_options.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import '../managers/cart_manager.dart';
import '../managers/wishlist_manager.dart';
import '../services/api_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => ProductListScreenState();
}

class ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<String> _categories = ['All'];

  late FilterOptions _filterOptions;

  List<Map<String, dynamic>> _apiProducts = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  void refreshData() {
    _refreshAll();
  }

  @override
  void initState() {
    super.initState();
    _filterOptions = FilterOptions(
      sortBy: 'Popularity',
      minPrice: 0,
      maxPrice: 5000,
      minRating: 0,
    );
    _fetchCategories();
    _fetchProducts();
    
    // Auto refresh every 5 minutes while on this screen
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _fetchCategories();
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchCategories(),
      _fetchProducts(),
    ]);
  }

  Future<void> _fetchCategories() async {
    try {
      final result = await ApiService.getCategories();
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> categoriesData = result['data'];
        final List<String> fetchedCategories = ['All'];
        for (var item in categoriesData) {
          if (item['name'] != null) {
            fetchedCategories.add(item['name'].toString());
          }
        }
        setState(() {
          _categories = fetchedCategories;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching categories: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getProducts();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _apiProducts = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> products = _apiProducts.where((product) {
      final matchesCategory = _selectedCategory == 'All' || 
          (product['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase());
      
      final matchesSearch = (product['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final double price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
      final matchesPrice = price >= _filterOptions.minPrice && price <= _filterOptions.maxPrice;
      
      final double rating = double.tryParse(product['rating']?.toString() ?? '0') ?? 0;
      final matchesRating = rating >= _filterOptions.minRating;

      return matchesCategory && matchesSearch && matchesPrice && matchesRating;
    }).toList();

    // Sorting
    if (_filterOptions.sortBy == 'Price: Low to High') {
      products.sort((a, b) => (double.tryParse(a['price']?.toString() ?? '0') ?? 0)
          .compareTo(double.tryParse(b['price']?.toString() ?? '0') ?? 0));
    } else if (_filterOptions.sortBy == 'Price: High to Low') {
      products.sort((a, b) => (double.tryParse(b['price']?.toString() ?? '0') ?? 0)
          .compareTo(double.tryParse(a['price']?.toString() ?? '0') ?? 0));
    } else if (_filterOptions.sortBy == 'Newest') {
      // Assuming _id exists as is common in Mongo-based APIs
      products.sort((a, b) => (b['_id']?.toString() ?? '').compareTo(a['_id']?.toString() ?? ''));
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredList = _filteredProducts;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Scrolling Header
              SliverToBoxAdapter(
                child: _buildHeader(colorScheme),
              ),
              // Search Bar & Filter Button
              SliverToBoxAdapter(
                child: _buildSearchBar(colorScheme),
              ),
              // Categories
              SliverToBoxAdapter(
                child: _buildCategories(colorScheme),
              ),
              // The List of Products
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                sliver: _isLoading && filteredList.isEmpty
                  ? const SliverToBoxAdapter(child: Center(child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(),
                    )))
                  : filteredList.isEmpty 
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
      child: Row(
        children: [
          Expanded(
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
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final FilterOptions? result = await showModalBottomSheet<FilterOptions>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FilterBottomSheet(initialOptions: _filterOptions),
              );
              
              if (result != null) {
                setState(() {
                  _filterOptions = result;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _filterOptions.minPrice > 0 || _filterOptions.sortBy != 'Popularity' || _filterOptions.minRating > 0
                  ? colorScheme.primary 
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.tune,
                color: _filterOptions.minPrice > 0 || _filterOptions.sortBy != 'Popularity' || _filterOptions.minRating > 0
                  ? Colors.white
                  : colorScheme.primary,
              ),
            ),
          ),
        ],
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
                  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected
                      ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
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

  Widget _buildProductListItem(Map<String, dynamic> product, ColorScheme colorScheme) {
    final String name = (product['name'] ?? 'Product').toString();
    final String imageUrl = (product['image'] ?? '').toString();
    final String price = '₹${product['price'] ?? 0}';
    final String rating = (product['rating'] ?? '0.0').toString();
    final String reviews = (product['numReviews'] ?? '0').toString();

    return GestureDetector(
      onTap: () {
        // Standardize for details screen
        final detailsProduct = {
          '_id': product['_id']?.toString() ?? product['id']?.toString() ?? '',
          'name': name,
          'description': (product['description'] ?? '').toString(),
          'price': price,
          'image': imageUrl,
          'category': (product['category'] ?? '').toString(),
          'icon': '🌿',
          'rating': rating,
          'reviews': reviews,
        };

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: detailsProduct),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product-$name',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: imageUrl.isNotEmpty 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa, size: 45, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.spa, size: 45, color: Colors.grey),
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
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (product['category'] ?? 'Wellness').toString().toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        WishlistManager().isWishlisted(name)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: WishlistManager().isWishlisted(name)
                            ? Colors.red
                            : Colors.grey[300],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
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
                        rating,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' ($reviews)',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          price,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            color: colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          final quantity = CartManager().getProductQuantity(name);
                          return ElevatedButton(
                            onPressed: () {
                              CartManager().addItem(product);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to cart'),
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
