import 'package:flutter/material.dart';
import 'dart:async';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_consultant_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/product_list_screen.dart';
import 'managers/cart_manager.dart';
import 'managers/wishlist_manager.dart';
import 'managers/user_manager.dart';
import 'managers/theme_manager.dart';

import 'managers/notification_manager.dart';
import 'managers/payment_manager.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserManager().init();
  await ThemeManager().init();
  await NotificationManager().init();
  await PaymentManager().init();
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final bool isDark = ThemeManager().isDarkMode == true;
        return MaterialApp(
          title: 'Kosmico Wellness',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00833E),
              primary: const Color(0xFF00833E),
              secondary: const Color(0xFF1B264F),
              surface: const Color(0xFFF9F6F2),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: Color(0xFF00833E)),
              titleLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.w600),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00833E),
              brightness: Brightness.dark,
              primary: const Color(0xFF00833E),
              secondary: const Color(0xFF4CBB17),
              surface: const Color(0xFF262626), // Even lighter matte black/grey
              surfaceContainerHighest: const Color(0xFF333333), // Lighter Grey for cards
              onSurface: Colors.white,
              onSurfaceVariant: Colors.grey[400],
            ),
            scaffoldBackgroundColor: const Color(0xFF262626),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF262626),
              elevation: 0,
              centerTitle: true,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: Colors.white),
              titleLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _selectedHomeCategory = 'All';
  List<String> _homeCategories = ['All'];
  
  Map<String, dynamic>? _updateData;
  bool _showUpdateBanner = false;
  
  List<Map<String, dynamic>> _apiProducts = [];
  bool _isLoadingProducts = false;
  Timer? _refreshTimer;

  final GlobalKey<ProductListScreenState> _productListKey = GlobalKey<ProductListScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
    
    // Auto refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshAllData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('DEBUG: App resumed, auto-refreshing data...');
      _refreshAllData();
    }
  }

  List<Map<String, dynamic>> get _filteredHomeProducts {
    if (_selectedHomeCategory == 'All') {
      return _apiProducts;
    }
    return _apiProducts.where((product) {
      return product['category']?.toString().toLowerCase() == _selectedHomeCategory.toLowerCase();
    }).toList();
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _checkForUpdates(),
      _fetchCategories(),
      _fetchProducts(),
      NotificationManager().fetchFromApi(),
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
          _homeCategories = fetchedCategories;
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching categories: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final result = await ApiService.getProducts();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _apiProducts = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching products: $e');
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      print('DEBUG: Starting update check...');
      final result = await ApiService.getLatestUpdate();
      print('DEBUG: Update Check API Response -> $result');
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final updateInfo = data['update'];
        
        print('DEBUG: Extracted Update Info -> $updateInfo');
        
        if (updateInfo != null && (updateInfo['isUpdateAvailable'] == true || updateInfo['isUpdateAvailable'].toString() == 'true')) {
          if (mounted) {
            setState(() {
              _updateData = updateInfo;
              _showUpdateBanner = true;
            });
            print('DEBUG: State updated, banner should show');
            
            // Show a SnackBar to confirm we found it
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New Update Available: ${updateInfo['version']}'),
                backgroundColor: const Color(0xFF00833E),
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            _showUpdateDialog(updateInfo);
          }
        } else {
          print('DEBUG: isUpdateAvailable is false or null');
        }
      } else {
        print('DEBUG: API call failed or data is null. Message: ${result['message']}');
      }
    } catch (e) {
      print('DEBUG: Update Check Exception -> $e');
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.update, color: Color(0xFF00833E)),
            const SizedBox(width: 10),
            Text(updateInfo['title'] ?? 'Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version (${updateInfo['version']}) is available.', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Release Notes:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(updateInfo['releaseNotes'] ?? 'Bug fixes and improvements.', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Redirect to store
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00833E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update, color: colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _updateData?['title'] ?? 'New Update Available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version ${_updateData?['version'] ?? ''} is now available.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Redirect to Play Store / App Store
            },
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _showUpdateBanner = false),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshAllData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (_showUpdateBanner && _updateData != null)
            _buildUpdateBanner(colorScheme),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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

          // Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: const NetworkImage('https://images.unsplash.com/photo-1615485290382-441e4d0c9cb5?auto=format&fit=crop&q=80&w=800'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary.withValues(alpha: 0.8),
                  BlendMode.srcOver,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ancient Wisdom,\nModern Wellness',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover the healing power of Ayurveda',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          ),

          // Categories
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _homeCategories.length,
              itemBuilder: (context, index) {
                final category = _homeCategories[index];
                return _buildCategoryChip(
                  category,
                  _selectedHomeCategory == category,
                  colorScheme,
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Our Bestsellers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('View All', style: TextStyle(color: colorScheme.secondary)),
                ),
              ],
            ),
          ),

          _isLoadingProducts 
            ? const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ))
            : _filteredHomeProducts.isEmpty 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text('No products found in this category', style: TextStyle(color: Colors.grey[500])),
                  ),
                )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _filteredHomeProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredHomeProducts[index];
              final String name = (product['name'] ?? 'Product').toString();
              final String imageUrl = (product['image'] ?? '').toString();
              final String price = '₹${product['price'] ?? 0}';
              
              return GestureDetector(
                onTap: () {
                  // Standardize for details screen which might expect Map<String, String>
                  final detailsProduct = {
                    'name': name,
                    'description': (product['description'] ?? '').toString(),
                    'price': price,
                    'image': imageUrl,
                    'category': (product['category'] ?? '').toString(),
                    'icon': '🌿', // Fallback for UI that still uses icon
                  };

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(product: detailsProduct),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: imageUrl.isNotEmpty 
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa, size: 48, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.spa, size: 48, color: Colors.grey),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    WishlistManager().toggleWishlist(product);
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      WishlistManager().isWishlisted(name)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18,
                                      color: WishlistManager().isWishlisted(name)
                                          ? Colors.red
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (product['description'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                price,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            ListenableBuilder(
                              listenable: CartManager(),
                              builder: (context, _) {
                                final int q = CartManager().getProductQuantity(name);
                                return InkWell(
                                  onTap: () {
                                    CartManager().addItem(product);
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$name added to cart!'),
                                        duration: const Duration(milliseconds: 1500),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: colorScheme.primary,
                                        action: SnackBarAction(
                                          label: 'View',
                                          textColor: Colors.white,
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen())),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.add_shopping_cart_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      if (q > 0)
                                        Positioned(
                                          right: -6,
                                          top: -6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              q.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHomeCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.primary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/kosmicologo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.spa,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KOSMICO',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Wellness Journey',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            ListenableBuilder(
              listenable: NotificationManager(),
              builder: (context, _) {
                final int unreadCount = NotificationManager().unreadCount;
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                        ),
                        child: Icon(Icons.notifications_none_outlined, color: colorScheme.primary, size: 20),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                );
              },
            ),
          ListenableBuilder(
            listenable: CartManager(),
            builder: (context, _) {
              final int count = CartManager().itemCount;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary, size: 20),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Container(color: colorScheme.surface, child: _buildHomeBody(colorScheme)),
          Container(color: colorScheme.surface, child: ProductListScreen(key: _productListKey)),
          Container(color: colorScheme.surface, child: const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', colorScheme)),
            Expanded(child: _buildNavItem(1, Icons.category_outlined, Icons.category_rounded, 'Products', colorScheme)),
            Expanded(child: _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', colorScheme)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AiConsultantScreen()),
            );
          },
          backgroundColor: colorScheme.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.assistant, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, ColorScheme colorScheme) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedIndex = index;
          });
          
          // Specifically refresh ProductListScreen if switching to it
          if (index == 1) {
            _productListKey.currentState?.refreshData();
          }
        }
        // Refresh data when any tab is clicked (including current one)
        _refreshAllData();
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: isSelected ? 0.15 : 0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? Colors.white : Colors.grey[500],
                    size: 24,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedSlide(
                    offset: isSelected ? Offset.zero : const Offset(-0.3, 0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
