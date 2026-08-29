import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../managers/language_manager.dart';
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
  List<Map<String, dynamic>> _categories = [{'name': 'All', '_id': 'All'}];

  late FilterOptions _filterOptions;

  List<Map<String, dynamic>> _apiProducts = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 12;
  
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();

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
    
    _scrollController.addListener(_onScroll);
    
    _fetchCategories();
    _fetchProducts(isInitial: true);
    
    // Auto refresh every 5 minutes while on this screen
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _fetchCategories();
        _fetchProducts(isInitial: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore && _hasMore) {
        _fetchProducts(isInitial: false);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchCategories(),
      _fetchProducts(isInitial: true),
    ]);
  }

  Future<void> _fetchCategories() async {
    try {
      final result = await ApiService.getCategories();
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> categoriesData = result['data'];
        final List<Map<String, dynamic>> fetchedCategories = [{'name': 'All', '_id': 'All'}];
        for (var item in categoriesData) {
          if (item is Map<String, dynamic>) {
            fetchedCategories.add(item);
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

  Future<void> _fetchProducts({bool isInitial = true}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      // Find the ID for the selected category name
      String? categoryId;
      if (_selectedCategory != 'All') {
        final catObj = _categories.firstWhere(
          (c) => c['name'] == _selectedCategory,
          orElse: () => {},
        );
        categoryId = catObj['_id']?.toString() ?? catObj['id']?.toString();
      }

      final result = await ApiService.getProducts(
        page: isInitial ? 1 : _currentPage + 1,
        limit: _pageSize,
        category: categoryId ?? 'All',
        search: _searchQuery,
        sortBy: _filterOptions.sortBy,
        minPrice: _filterOptions.minPrice,
        maxPrice: _filterOptions.maxPrice,
        minRating: _filterOptions.minRating,
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> fetchedData = result['data'];
        final List<Map<String, dynamic>> newProducts = List<Map<String, dynamic>>.from(fetchedData);

        setState(() {
          if (isInitial) {
            _apiProducts = newProducts;
            _currentPage = 1;
          } else {
            _apiProducts.addAll(newProducts);
            _currentPage++;
          }
          
          // Force "Sweet Monk" products to the very top across all pages
          _apiProducts.sort((a, b) {
            final String nameA = (a['name'] ?? '').toString().toLowerCase();
            final String nameB = (b['name'] ?? '').toString().toLowerCase();
            final bool isA = nameA.contains('sweet monk');
            final bool isB = nameB.contains('sweet monk');
            
            if (isA && !isB) return -1;
            if (!isA && isB) return 1;
            return 0;
          });
          
          _hasMore = newProducts.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching products: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> products = _apiProducts;

    // Double check filtering locally to ensure UI consistency
    if (_selectedCategory != 'All') {
      products = products.where((product) {
        final String cat = (product['category'] ?? '').toString().toLowerCase();
        final String selected = _selectedCategory.toLowerCase();
        
        // Exact match
        if (cat == selected) return true;
        
        // Handle plural/singular mismatches (e.g., Herbals vs Herbal, Oils vs Oil)
        if (cat.contains(selected) || selected.contains(cat)) return true;
        
        // Handle common typos (Essesntials vs Essential)
        if ((selected.contains('essential') || selected.contains('essesntial')) && 
            (cat.contains('essential') || cat.contains('essesntial'))) return true;
        
        return false;
      }).toList();
    }

    // Immediate search filtering while debounce is active
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = LanguageManager();

    return ListenableBuilder(
      listenable: lang,
      builder: (context, _) {
        final filteredList = _filteredProducts;
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              child: CustomScrollView(
                controller: _scrollController,
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
                                    Icon(Icons.search_off, size: 60, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    Text(lang.translate('no_products'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == filteredList.length) {
                                  return _isFetchingMore 
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: Center(child: CircularProgressIndicator()),
                                      )
                                    : const SizedBox.shrink();
                                }
                                return _buildProductListItem(filteredList[index], colorScheme);
                              },
                              childCount: filteredList.length + (_hasMore ? 1 : 0),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final lang = LanguageManager();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('wellness_catalog'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lang.translate('ayurvedic_essentials'),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final lang = LanguageManager();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                // Debounce search for pagination
                _refreshTimer?.cancel();
                _refreshTimer = Timer(const Duration(milliseconds: 600), () {
                  _fetchProducts(isInitial: true);
                });
              },
              decoration: InputDecoration(
                hintText: lang.translate('search_products'),
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
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
                  _fetchProducts(isInitial: true);
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
          final catObj = _categories[index];
          final String name = catObj['name'] ?? 'All';
          final isSelected = _selectedCategory == name;
          
          String displayName = name.replaceAll('_', ' ');
          if (displayName.toLowerCase().contains('essesntials')) {
            displayName = displayName.toLowerCase().replaceFirst('essesntials', 'essential');
          }
          // Capitalize words
          displayName = displayName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
          
          if (name == 'All') displayName = LanguageManager().currentLanguage == 'hi' ? 'सभी' : 'All';

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = name;
                  _fetchProducts(isInitial: true);
                });
              },
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
                  displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
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
    final String rawPrice = (product['price'] ?? 0).toString().replaceAll('₹', '').trim();
    final String price = '₹$rawPrice';
    final dynamic ratingRaw = product['rating'] ?? product['avgRating'];
    final double ratingVal = double.tryParse(ratingRaw?.toString() ?? '') ?? 0.0;
    final String rating = ratingVal.toStringAsFixed(1);

    final dynamic reviewsRaw = product['numReviews'] ?? product['reviews'];
    int reviewCount = 0;
    if (reviewsRaw is List) {
      reviewCount = reviewsRaw.length;
    } else if (reviewsRaw != null) {
      reviewCount = int.tryParse(reviewsRaw.toString()) ?? 0;
    }
    final String reviews = reviewCount.toString();

    final bool hasNoReviews = ratingVal == 0 && reviewCount == 0;

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
                          child: Builder(
                            builder: (context) {
                              final String rawCat = product['category']?.toString() ?? 'wellness';
                              String catDisplay = LanguageManager().translate(rawCat.toLowerCase().replaceAll(' ', '_'));
                              if (catDisplay == rawCat.toLowerCase().replaceAll(' ', '_')) {
                                catDisplay = rawCat.replaceAll('_', ' ');
                                if (catDisplay.toLowerCase().contains('essesntials')) {
                                  catDisplay = catDisplay.toLowerCase().replaceFirst('essesntials', 'essential');
                                }
                                catDisplay = catDisplay.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
                              }
                              return Text(
                                catDisplay.toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.secondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            }
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
                  if (!hasNoReviews)
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
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
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
                            letterSpacing: 0.5,
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
                          
                          if (quantity > 0) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    CartManager().decrementItemByName(name);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
                                    ),
                                    child: Icon(Icons.remove, color: colorScheme.secondary, size: 16),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 32),
                                  alignment: Alignment.center,
                                  child: Text(
                                    quantity.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (CartManager().canAddMore(product, 1)) {
                                      CartManager().incrementItemByName(name);
                                    } else {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(LanguageManager().translate('out_of_stock')), behavior: SnackBarBehavior.floating)
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            );
                          }

                          return ElevatedButton(
                            onPressed: () {
                              CartManager().addItem(product);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(LanguageManager().translate('added_to_cart')),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: colorScheme.primary,
                                  duration: const Duration(milliseconds: 1500),
                                  action: SnackBarAction(
                                    label: LanguageManager().translate('view'),
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
                              LanguageManager().translate('add_to_cart').toUpperCase(),
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
