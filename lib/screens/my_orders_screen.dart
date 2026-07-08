import 'package:flutter/material.dart';
import 'order_details_screen.dart';
import 'cart_screen.dart';
import '../managers/cart_manager.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          unselectedLabelColor: Colors.grey,
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
    final orders = [
      {
        'id': 'KSM987654',
        'date': 'Oct 24, 2023',
        'status': 'In Transit',
        'price': '₹499',
        'items': 'Ayurvedic Hair Oil',
        'icon': '🌿',
      },
      {
        'id': 'KSM987655',
        'date': 'Oct 23, 2023',
        'status': 'Processing',
        'price': '1,299',
        'items': 'Active Protein Powder',
        'icon': '💪',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], colorScheme, true);
      },
    );
  }

  Widget _buildCompletedOrders(ColorScheme colorScheme) {
    final orders = [
      {
        'id': 'KSM987600',
        'date': 'Oct 15, 2023',
        'status': 'Delivered',
        'price': '₹350',
        'items': 'Diabetes Care Supplement',
        'icon': '🩸',
      },
      {
        'id': 'KSM987590',
        'date': 'Oct 10, 2023',
        'status': 'Delivered',
        'price': '₹450',
        'items': 'Liver Care Capsules',
        'icon': '✨',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], colorScheme, false);
      },
    );
  }

  Widget _buildOrderCard(Map<String, String> order, ColorScheme colorScheme, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
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
              Text(
                'Order #${order['id']}',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.secondary.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order['status']!,
                  style: TextStyle(
                    color: isActive ? colorScheme.secondary : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                child: Text(order['icon']!, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['items']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ordered on ${order['date']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order['price']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('1 Item', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isActive) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(order: order),
                    ),
                  );
                } else {
                  // Reorder Action
                  CartManager().addItem(order);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('${order['items']} added to cart!'),
                        ],
                      ),
                      backgroundColor: colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      action: SnackBarAction(
                        label: 'View Cart',
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
    );
  }
}
