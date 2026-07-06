import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/product_list_screen.dart';
import 'managers/cart_manager.dart';
import 'managers/wishlist_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kosmico Wellness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00833E), // Logo Green
          primary: const Color(0xFF00833E),
          secondary: const Color(0xFF1B264F), // Logo Navy Blue
          surface: const Color(0xFFF9F6F2), // Off-white/Cream
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: Color(0xFF00833E)),
          titleLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.w600),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedHomeCategory = 'All';
  final List<String> _homeCategories = ['All', 'Hair Care', 'Immunity', 'Diabetes', 'Detox'];

  final List<Map<String, String>> products = [
    {
      'name': 'Ayurvedic Hair Oil',
      'description': 'Traditional formula with bhringraj & amla for thick growth.',
      'price': '₹499',
      'icon': '🌿',
    },
    {
      'name': 'Active Protein Powder',
      'description': 'Herbal blend with ashwagandha for strength and vitality.',
      'price': '₹1,299',
      'icon': '💪',
    },
    {
      'name': 'Diabetes Care',
      'description': 'Natural support with karela & jamun for blood sugar.',
      'price': '₹350',
      'icon': '🩸',
    },
    {
      'name': 'Liver Care Capsules',
      'description': 'Detoxification and health with kutki & punarnava.',
      'price': '₹450',
      'icon': '✨',
    },
  ];

  Widget _buildHomeBody(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Space for floating nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
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
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover the healing power of Ayurveda',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
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

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(product: product),
                    ),
                  ).then((_) => setState(() {}));
                },
                child: Card(
                  elevation: 0,
                  color: Colors.white,
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
                                child: Hero(
                                  tag: 'product-${product['name']}',
                                  child: Text(
                                    product['icon']!,
                                    style: const TextStyle(fontSize: 48, decoration: TextDecoration.none),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      WishlistManager().toggleWishlist(product);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      WishlistManager().isWishlisted(product['name']!)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18,
                                      color: WishlistManager().isWishlisted(product['name']!)
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
                          product['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['description']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product['price']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                CartManager().addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product['name']} added to cart!'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                              },
                              child: Container(
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
          color: isSelected ? colorScheme.primary : Colors.white,
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
      extendBody: true,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
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
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Icon(Icons.notifications_none_outlined, color: colorScheme.primary, size: 20),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary, size: 20),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeBody(colorScheme),
            const ProductListScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFB6C4B6), // Soft light green border
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: Colors.grey.withValues(alpha: 0.6),
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category_outlined),
                activeIcon: Icon(Icons.category),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
