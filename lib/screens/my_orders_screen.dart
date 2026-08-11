import 'package:flutter/material.dart';
import 'order_details_screen.dart';
import 'cart_screen.dart';
import '../managers/cart_manager.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';
import '../widgets/rating_dialog.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = false;
  
  // Pagination State
  int _activePage = 1;
  int _completedPage = 1;
  bool _hasMoreActive = true;
  bool _hasMoreCompleted = true;
  bool _isFetchingMore = false;
  final int _pageSize = 10;

  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activeScrollController.addListener(() => _onScroll(true));
    _completedScrollController.addListener(() => _onScroll(false));
    _fetchOrders(isInitial: true);
  }

  void _onScroll(bool isActive) {
    final controller = isActive ? _activeScrollController : _completedScrollController;
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore) {
        if (isActive && _hasMoreActive) {
          _fetchMoreOrders(true);
        } else if (!isActive && _hasMoreCompleted) {
          _fetchMoreOrders(false);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeScrollController.dispose();
    _completedScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({bool isInitial = true}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _activePage = 1;
        _completedPage = 1;
        _hasMoreActive = true;
        _hasMoreCompleted = true;
      });
    }

    final token = UserManager().token;
    if (token != null) {
      // For initial fetch, we'll try to get the first page of everything
      // In a real paginated API, you might fetch only for the active tab
      final result = await ApiService.getUserOrders(token, page: 1, limit: 50); // Fetch a larger initial batch
      debugPrint('DEBUG: MyOrders API Response: $result');
      
      if (result['success'] && result['data'] != null) {
        final dynamic rawData = result['data'];
        List allOrders = [];
        if (rawData is List) {
          allOrders = rawData;
        } else if (rawData is Map) {
          allOrders = rawData['orders'] ?? rawData['data'] ?? [];
        }
        
        setState(() {
          final List filteredOrders = allOrders.where((o) {
            final String s = (o['status'] ?? o['paymentStatus'] ?? o['orderStatus'] ?? '').toString().toLowerCase();
            final String method = (o['paymentMethodId'] ?? o['paymentMethod'] ?? '').toString().toLowerCase();
            if (s == 'created' || s == 'failed' || s == 'attempted') return false;
            if (method.contains('razorpay') && s == 'pending') return false;
            return true;
          }).toList();

          _activeOrders = filteredOrders.where((o) {
            final String s = (o['status'] ?? o['paymentStatus'] ?? o['orderStatus'] ?? '').toString().toLowerCase();
            return s != 'delivered' && s != 'cancelled' && o['isCancelled'] != true;
          }).map((o) => _mapOrder(o)).toList().cast<Map<String, dynamic>>();

          _completedOrders = filteredOrders.where((o) {
            final String s = (o['status'] ?? o['paymentStatus'] ?? o['orderStatus'] ?? '').toString().toLowerCase();
            return s == 'delivered' || s == 'cancelled' || o['isCancelled'] == true;
          }).map((o) => _mapOrder(o)).toList().cast<Map<String, dynamic>>();
          
          // Heuristic: if we got less than requested, maybe no more
          _hasMoreActive = _activeOrders.length >= 10; 
          _hasMoreCompleted = _completedOrders.length >= 10;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMoreOrders(bool isActive) async {
    setState(() => _isFetchingMore = true);
    final token = UserManager().token;
    final int pageToFetch = isActive ? _activePage + 1 : _completedPage + 1;

    if (token != null) {
      final result = await ApiService.getUserOrders(token, page: pageToFetch, limit: _pageSize);
      
      if (result['success'] && result['data'] != null) {
        final dynamic rawData = result['data'];
        List allOrders = [];
        if (rawData is List) allOrders = rawData;
        else if (rawData is Map) allOrders = rawData['orders'] ?? rawData['data'] ?? [];

        final List mapped = allOrders.map((o) => _mapOrder(o)).toList();
        
        setState(() {
          if (isActive) {
            final List<Map<String, dynamic>> newActive = mapped.where((o) {
              final String s = o['status'].toString().toLowerCase();
              return s != 'delivered' && s != 'cancelled';
            }).cast<Map<String, dynamic>>().toList();
            
            _activeOrders.addAll(newActive);
            _activePage++;
            _hasMoreActive = allOrders.length == _pageSize;
          } else {
            final List<Map<String, dynamic>> newCompleted = mapped.where((o) {
              final String s = o['status'].toString().toLowerCase();
              return s == 'delivered' || s == 'cancelled';
            }).cast<Map<String, dynamic>>().toList();
            
            _completedOrders.addAll(newCompleted);
            _completedPage++;
            _hasMoreCompleted = allOrders.length == _pageSize;
          }
        });
      }
    }
    setState(() => _isFetchingMore = false);
  }

  String _getItemName(dynamic item) {
    if (item == null) return 'Wellness Product';
    return (item['name'] ?? 
            item['productName'] ?? 
            item['itemName'] ?? 
            item['title'] ?? 
            item['product']?['name'] ?? 
            item['product']?['title'] ?? 
            'Wellness Product').toString();
  }

  String? _getItemImage(dynamic item) {
    if (item == null) return null;
    String? img = (item['image'] ?? 
                   item['imageUrl'] ?? 
                   item['productImage'] ?? 
                   item['thumbnail'] ?? 
                   item['product']?['image'] ?? 
                   item['product']?['imageUrl'])?.toString();
    
    if (img != null && img.isNotEmpty && !img.startsWith('http')) {
      String cleanBase = ApiService.baseUrl.endsWith('/') 
          ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1) 
          : ApiService.baseUrl;
      if (!img.startsWith('/')) img = '/$img';
      img = '$cleanBase$img';
    }
    return img;
  }

  Map<String, dynamic> _mapOrder(dynamic o) {
    if (o == null) return {};

    // Try to find items list
    List items = [];
    if (o['items'] is List) items = o['items'];
    else if (o['products'] is List) items = o['products'];
    else if (o['orderItems'] is List) items = o['orderItems'];
    
    // Try to find an image anywhere in the object
    String? imageUrl = _getItemImage(o);
    if ((imageUrl == null || imageUrl.isEmpty) && items.isNotEmpty) {
      imageUrl = _getItemImage(items[0]);
    }

    // Comprehensive Status Detection
    // Check multiple fields: status, orderStatus, paymentStatus, deliveryStatus
    String rawStatus = (o['status'] ?? o['orderStatus'] ?? o['paymentStatus'] ?? o['deliveryStatus'] ?? 'Pending').toString();
    
    // Check for cancellation flags (boolean or string)
    bool isCancelled = o['isCancelled'] == true || 
                       o['cancelled'] == true || 
                       rawStatus.toLowerCase() == 'cancelled' ||
                       rawStatus.toLowerCase() == 'cancel';

    String displayStatus = isCancelled ? 'Cancelled' : rawStatus;

    // Detect Payment Mode
    String method = (o['paymentMethodId'] ?? o['paymentMethod'] ?? '').toString().toLowerCase();
    String paymentMode = method.contains('razorpay') || method.contains('online') || method.contains('prepaid') 
        ? 'Online' 
        : 'COD';

    return {
      'id': (o['_id'] ?? o['id'] ?? 'N/A').toString(),
      'date': (o['createdAt'] ?? o['date'] ?? '').toString().split('T').first,
      'status': displayStatus,
      'payment_mode': paymentMode,
      'price': '₹${o['amount'] ?? o['totalPrice'] ?? 0}',
      'items_text': items.isNotEmpty 
          ? "${_getItemName(items[0])}${items.length > 1 ? ' + ${items.length - 1} more' : ''}"
          : (o['orderName'] ?? o['title'] ?? _getItemName(o)).toString(),
      'item_count': items.isNotEmpty ? items.length : (o['totalItems'] ?? 1),
      'icon': '📦',
      'image': imageUrl,
      'full_order': o,
    };
  }

  Future<void> _fetchOrderDetails(String orderId) async {
    // This helper can be used to fetch full details if the list is missing items
    final token = UserManager().token;
    if (token != null) {
      final result = await ApiService.trackOrder(orderId, token);
      if (result['success'] && result['data'] != null) {
         // If trackOrder returns item details, we could update the local state here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Orders',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrders(colorScheme),
          _buildCompletedOrders(colorScheme),
        ],
      ),
    );
  }

  Widget _buildActiveOrders(ColorScheme colorScheme) {
    if (_isLoading && _activeOrders.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_activeOrders.isEmpty) return _buildEmptyState('No active orders');

    return RefreshIndicator(
      onRefresh: () => _fetchOrders(isInitial: true),
      child: ListView.builder(
        controller: _activeScrollController,
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _activeOrders.length + (_hasMoreActive ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _activeOrders.length) {
            return _isFetchingMore 
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
          }
          return _buildOrderCard(_activeOrders[index], colorScheme, true);
        },
      ),
    );
  }

  Widget _buildCompletedOrders(ColorScheme colorScheme) {
    if (_isLoading && _completedOrders.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_completedOrders.isEmpty) return _buildEmptyState('No completed orders');

    return RefreshIndicator(
      onRefresh: () => _fetchOrders(isInitial: true),
      child: ListView.builder(
        controller: _completedScrollController,
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _completedOrders.length + (_hasMoreCompleted ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _completedOrders.length) {
            return _isFetchingMore 
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
          }
          return _buildOrderCard(_completedOrders[index], colorScheme, false);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = UserManager().token;
    if (token != null) {
      final result = await ApiService.cancelOrder(orderId, token);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to cancel order'), backgroundColor: Colors.red),
          );
        }
        _fetchOrders(); // Always refresh to get latest status
      }
    }
    setState(() => _isLoading = false);
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ColorScheme colorScheme, bool isActive) {
    final String imageUrl = (order['image'] ?? '').toString();
    final String status = (order['status'] ?? '').toString().toLowerCase();
    final bool canCancel = status != 'delivered' && status != 'cancelled';
    final String orderId = (order['id'] ?? '').toString();
    final String icon = (order['icon'] ?? '📦').toString();
    final String itemsText = (order['items_text'] ?? 'Wellness Product').toString();
    final String date = (order['date'] ?? '').toString();
    final String price = (order['price'] ?? '').toString();
    final int itemCount = order['item_count'] is int ? order['item_count'] : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                child: Text(
                  'Order #$orderId',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'cancelled' 
                          ? Colors.red.withValues(alpha: 0.1)
                          : (isActive ? colorScheme.secondary.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order['status'].toString(),
                      style: TextStyle(
                        color: status == 'cancelled'
                            ? Colors.red
                            : (isActive ? colorScheme.secondary : Colors.green),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Payment Mode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (order['payment_mode'] == 'Online' ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (order['payment_mode'] == 'Online' ? Colors.green : Colors.blue).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      (order['payment_mode'] ?? 'COD').toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: order['payment_mode'] == 'Online' ? Colors.green[700] : Colors.blue[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(icon, style: const TextStyle(fontSize: 28)),
                        ),
                      )
                    : Text(icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemsText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ordered on $date',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$itemCount Item${itemCount > 1 ? 's' : ''}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelOrder(orderId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    if (!isActive && status == 'delivered') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => RatingDialog(order: order),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Rate', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isActive) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsScreen(order: order),
                              ),
                            ).then((cancelled) {
                              if (cancelled == true) _fetchOrders();
                            });
                          } else {
                            // Reorder Action: Add items from the original order back to cart
                            final List items = order['full_order']?['items'] ?? 
                                               order['full_order']?['products'] ?? 
                                               order['full_order']?['orderItems'] ?? [];
                            
                            if (items.isNotEmpty) {
                              for (var item in items) {
                                CartManager().addItem(item);
                              }
                            } else {
                              // Fallback: Add the mapped order if items list is missing (unlikely)
                              CartManager().addItem(order);
                            }

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    const Expanded(child: Text('Items added to cart!')),
                                  ],
                                ),
                                backgroundColor: colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 1500),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                action: SnackBarAction(
                                  label: 'View',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const CartScreen()),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isActive ? 'Track Order' : 'Reorder'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
