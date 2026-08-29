import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_consultant_screen.dart';
import 'screens/care/care_dashboard_screen.dart';
import 'screens/care/scan_meal_module.dart';
import 'screens/care/today_module.dart';
import 'screens/notification_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/product_list_screen.dart';
import 'managers/cart_manager.dart';
import 'managers/wishlist_manager.dart';
import 'managers/language_manager.dart';
import 'managers/notification_manager.dart';
import 'managers/care_manager.dart';
import 'services/api_service.dart';
import 'widgets/banner_carousel.dart';
import 'utils/keys.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _selectedHomeCategory = 'All';
  List<Map<String, dynamic>> _homeCategories = [{'name': 'All', '_id': 'All'}];
  String _homeSearchQuery = '';
  
  Map<String, dynamic>? _updateData;
  bool _showUpdateBanner = false;
  
  List<Map<String, dynamic>> _apiProducts = [];
  bool _isLoadingProducts = false;
  Timer? _refreshTimer;

  final GlobalKey<ProductListScreenState> _productListKey = GlobalKey<ProductListScreenState>();
  final GlobalKey<CareDashboardScreenState> _careDashboardKey = GlobalKey<CareDashboardScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
    
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
      _refreshAllData();
    }
  }

  List<Map<String, dynamic>> get _filteredHomeProducts {
    List<Map<String, dynamic>> products = _apiProducts;
    
    if (_selectedHomeCategory != 'All') {
      products = products.where((product) {
        final String cat = (product['category'] ?? '').toString().toLowerCase();
        final String selected = _selectedHomeCategory.toLowerCase();
        if (cat == selected) return true;
        if (cat.contains(selected) || selected.contains(cat)) return true;
        return false;
      }).toList();
    }

    if (_homeSearchQuery.isNotEmpty) {
      products = products.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        return name.contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }

    return products;
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
        final List<Map<String, dynamic>> fetchedCategories = [{'name': 'All', '_id': 'All'}];
        for (var item in categoriesData) {
          if (item is Map<String, dynamic>) {
            fetchedCategories.add(item);
          }
        }
        setState(() {
          _homeCategories = fetchedCategories;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching categories: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      String? categoryId;
      if (_selectedHomeCategory != 'All') {
        final catObj = _homeCategories.firstWhere(
          (c) => c['name'] == _selectedHomeCategory,
          orElse: () => {},
        );
        categoryId = catObj['_id']?.toString() ?? catObj['id']?.toString();
      }

      final result = await ApiService.getProducts(category: categoryId ?? 'All');
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          final List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(result['data']);
          
          // Force "Sweet Monk" products to the very top
          products.sort((a, b) {
            final String nameA = (a['name'] ?? '').toString().toLowerCase();
            final String nameB = (b['name'] ?? '').toString().toLowerCase();
            final bool isA = nameA.contains('sweet monk');
            final bool isB = nameB.contains('sweet monk');
            
            if (isA && !isB) return -1;
            if (!isA && isB) return 1;
            return 0;
          });
          
          _apiProducts = products;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching products: $e');
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final result = await ApiService.getLatestUpdate();
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final updateInfo = data['update'];
        if (updateInfo != null && (updateInfo['isUpdateAvailable'] == true || updateInfo['isUpdateAvailable'].toString() == 'true')) {
          if (mounted) {
            setState(() {
              _updateData = updateInfo;
              _showUpdateBanner = true;
            });
            _showUpdateDialog(updateInfo);
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Update Check Exception -> $e');
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
            Text('Release Notes:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            Text(updateInfo['releaseNotes'] ?? 'Bug fixes and improvements.', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00833E), foregroundColor: Colors.white),
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
                Text(_updateData?['title'] ?? 'New Update Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Version ${_updateData?['version'] ?? ''} is now available.', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: Colors.white),
            child: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _showUpdateBanner = false)),
        ],
      ),
    );
  }

  // --- NAVIGATION ACTION HELPERS ---
  void _openPlateScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'AI Plate & Meal Scanner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: const ScanMealModule(),
        ),
      ),
    );
  }

  void _openSmartwatchSync() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeviceManagementSheet(manager: CareManager()),
    );
  }

  void _openAiConsultant() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AiConsultantScreen()),
    );
  }

  void _openCareTab(int tabIndex) {
    setState(() => _selectedIndex = 2);
    _careDashboardKey.currentState?.switchTab(tabIndex);
  }

  void _handleBannerTap(int index) {
    if (index == 0) {
      // Sweet monk banner -> Go to Products Tab
      setState(() => _selectedIndex = 1);
      _productListKey.currentState?.refreshData();
    } else if (index == 1) {
      // Scan plate banner -> Open Plate Scanner
      _openPlateScan();
    } else if (index == 2) {
      // Social/community banner -> Go to Care Community Tab
      _openCareTab(1);
    }
  }

  // --- HOME BODY ---
  Widget _buildHomeBody(ColorScheme colorScheme, LanguageManager lang) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F5E9), // Mint green ambient wash at top
            Color(0xFFF4FBF7), // Soft transition
            Colors.white,      // Clean pure white towards bottom
          ],
          stops: [0.0, 0.25, 0.7],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showUpdateBanner && _updateData != null) _buildUpdateBanner(colorScheme),

            // Top Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _homeSearchQuery = value),
                  decoration: InputDecoration(
                    hintText: lang.translate('search_hint'),
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // Top Auto-Sliding Banner Carousel (Product & Features running at the top)
            BannerCarousel(onBannerTap: _handleBannerTap),

            const SizedBox(height: 20),

            // ALL CLINICAL & CARE FEATURES (FRONT & CENTER)
            _buildFeatureHubSection(colorScheme),

            const SizedBox(height: 24),

            // Products Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('bestsellers'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Organic & clinically curated foods',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedIndex = 1);
                      _productListKey.currentState?.refreshData();
                    },
                    icon: const Icon(Icons.storefront_rounded, size: 16),
                    label: Text(lang.translate('view_all')),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Categories horizontal list
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _homeCategories.length,
                itemBuilder: (context, index) {
                  final catObj = _homeCategories[index];
                  final String name = catObj['name'] ?? 'All';
                  return _buildCategoryChip(name, _selectedHomeCategory == name, colorScheme, lang);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Products Grid
            _isLoadingProducts 
              ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
              : _filteredHomeProducts.isEmpty 
                ? Center(child: Padding(padding: const EdgeInsets.all(40.0), child: Text(lang.translate('no_products'), style: TextStyle(color: colorScheme.onSurfaceVariant))))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _filteredHomeProducts.length > 6 ? 6 : _filteredHomeProducts.length,
                    itemBuilder: (context, index) => _buildProductCard(_filteredHomeProducts[index], colorScheme, lang),
                  ),

            const SizedBox(height: 20),

            // "Explore Full Store" Bottom Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  _productListKey.currentState?.refreshData();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Explore Full Product Store',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'View all diabetic care foods, sweeteners & herbal supplements',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.primary),
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

  // --- SMART HEALTH & CARE SUITE (FEATURE HUB) ---
  Widget _buildFeatureHubSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FDF4), // Emerald white
            Colors.white,      // Pure white center
            Color(0xFFE8F5E9), // Mint green glow
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Health & Care Suite',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Clinical diabetes tools at your fingertips',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 2),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, color: colorScheme.primary, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Grid of Essential Health Features (Balanced Light Green + White Gradient)
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  title: 'Plate AI Scan',
                  subtitle: 'Carbs & GI from photo',
                  icon: Icons.document_scanner_rounded,
                  badge: '✨ AI Vision',
                  cardGradient: const [Color(0xFF34D399), Color(0xFFA7F3D0), Color(0xFFF0FDF4), Colors.white],
                  onTap: _openPlateScan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeatureCard(
                  title: 'Smartwatch Sync',
                  subtitle: 'Live BLE biometrics',
                  icon: Icons.watch_rounded,
                  badge: '⚡ Live Sync',
                  cardGradient: const [Color(0xFF2DD4BF), Color(0xFF99F6E4), Color(0xFFF0FDFA), Colors.white],
                  onTap: _openSmartwatchSync,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  title: 'Health Diary',
                  subtitle: 'Log glucose & water',
                  icon: Icons.monitor_heart_rounded,
                  badge: '📊 Daily Log',
                  cardGradient: const [Color(0xFF10B981), Color(0xFF6EE7B7), Color(0xFFECFDF5), Colors.white],
                  onTap: () => _openCareTab(3), // Tab 3 is Log Entry
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeatureCard(
                  title: 'Care Community',
                  subtitle: 'Doctor SOS & network',
                  icon: Icons.diversity_3_rounded,
                  badge: '🤝 Support',
                  cardGradient: const [Color(0xFF22C55E), Color(0xFF86EFAC), Color(0xFFF0FDF4), Colors.white],
                  onTap: () => _openCareTab(1), // Tab 1 is Community
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required List<Color> cardGradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardGradient,
            stops: const [0.0, 0.35, 0.75, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.28),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badge.contains('Live') || badge.contains('Active')) ...[
                        Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: -0.2,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: Color(0xFF059669),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected, ColorScheme colorScheme, LanguageManager lang) {
    String translatedLabel = category;
    if (category == 'All') translatedLabel = lang.translate('all');
    if (category == 'Sweet Monk') translatedLabel = 'Sweet Monk';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHomeCategory = category;
        });
        _fetchProducts();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          translatedLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.primary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, ColorScheme colorScheme, LanguageManager lang) {
    final String name = (product['name'] ?? 'Product').toString();
    final String imageUrl = (product['image'] ?? '').toString();
    final String price = '₹${(product['price'] ?? 0).toString().replaceAll('₹', '').trim()}';
    
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product))).then((_) { if (mounted) setState(() {}); }),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1))),
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
                      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: imageUrl.isNotEmpty 
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa, size: 48, color: Colors.grey)))
                        : const Icon(Icons.spa, size: 48, color: Colors.grey),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () { WishlistManager().toggleWishlist(product); setState(() {}); },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
                          child: Icon(WishlistManager().isWishlisted(name) ? Icons.favorite : Icons.favorite_border, size: 18, color: WishlistManager().isWishlisted(name) ? Colors.red : colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text((product['description'] ?? '').toString(), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(price, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.primary, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                  _buildAddToCartButton(product, colorScheme, lang),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(Map<String, dynamic> product, ColorScheme colorScheme, LanguageManager lang) {
    final String name = product['name'] ?? '';
    return ListenableBuilder(
      listenable: CartManager(),
      builder: (context, _) {
        final int q = CartManager().getProductQuantity(name);
        
        if (q > 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CartManager().decrementItemByName(name);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.remove, color: colorScheme.secondary, size: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  q.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (CartManager().canAddMore(product, 1)) {
                    CartManager().incrementItemByName(name);
                  } else {
                    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(content: Text(lang.translate('out_of_stock')), behavior: SnackBarBehavior.floating)
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          );
        }

        return ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (CartManager().canAddMore(product, 1)) {
              CartManager().addItem(product, qtyToAdd: 1);
            } else {
              scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text(lang.translate('out_of_stock')), behavior: SnackBarBehavior.floating)
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(lang.translate('add_to_cart').replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = LanguageManager();

    return ListenableBuilder(
      listenable: lang,
      builder: (context, _) {
        return PopScope(
          canPop: _selectedIndex == 0,
          onPopInvokedWithResult: (didPop, result) { if (!didPop && _selectedIndex != 0) setState(() => _selectedIndex = 0); },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: colorScheme.surface,
              title: Row(
                children: [
                  Image.asset('assets/images/kosmicologo.png', height: 30, errorBuilder: (c, e, s) => Icon(Icons.spa, color: colorScheme.primary)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KOSMICO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                      Text(lang.translate('wellness_journey'), style: TextStyle(fontSize: 10, color: colorScheme.secondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              actions: [
                _buildNotificationIcon(colorScheme),
                _buildCartIcon(colorScheme),
                const SizedBox(width: 8),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeBody(colorScheme, lang),
                ProductListScreen(key: _productListKey),
                CareDashboardScreen(key: _careDashboardKey),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(colorScheme, lang),
            floatingActionButton: FloatingActionButton(
              onPressed: _openAiConsultant,
              backgroundColor: colorScheme.secondary,
              child: const Icon(Icons.assistant, color: Colors.white),
            ),
          ),
        );
      }
    );
  }

  Widget _buildNotificationIcon(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: NotificationManager(),
      builder: (context, _) {
        final int unread = NotificationManager().unreadCount;
        return IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications_none_outlined, color: colorScheme.primary),
              if (unread > 0) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 14, minHeight: 14), child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center))),
            ],
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationScreen())),
        );
      },
    );
  }

  Widget _buildCartIcon(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: CartManager(),
      builder: (context, _) {
        final int count = CartManager().itemCount;
        return IconButton(
          icon: Stack(
            children: [
              Icon(Icons.shopping_bag_outlined, color: colorScheme.primary),
              if (count > 0) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 14, minHeight: 14), child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center))),
            ],
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen())),
        );
      },
    );
  }

  Widget _buildBottomNav(ColorScheme colorScheme, LanguageManager lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
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
          Expanded(child: _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, lang.translate('home'), colorScheme)),
          Expanded(child: _buildNavItem(1, Icons.category_outlined, Icons.category_rounded, lang.translate('products'), colorScheme)),
          Expanded(child: _buildNavItem(2, Icons.assistant_outlined, Icons.assistant, lang.translate('care'), colorScheme)),
          Expanded(child: _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, lang.translate('profile'), colorScheme)),
        ],
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

          if (index == 1) {
            _productListKey.currentState?.refreshData();
          }
        }
        _refreshAllData();
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? Colors.white : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    size: 22,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedSlide(
                    offset: isSelected ? Offset.zero : const Offset(-0.3, 0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
