import 'package:flutter/material.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';
import 'order_details_screen.dart';

class ReturnsHistoryScreen extends StatefulWidget {
  const ReturnsHistoryScreen({super.key});

  @override
  State<ReturnsHistoryScreen> createState() => _ReturnsHistoryScreenState();
}

class _ReturnsHistoryScreenState extends State<ReturnsHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _refunds = [];
  List<dynamic> _returns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final token = UserManager().token;
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Execute in parallel for better performance
      final results = await Future.wait([
        ApiService.getMyRefunds(token),
        ApiService.getMyReturns(token),
      ]);

      final refundResult = results[0];
      final returnResult = results[1];
      
      if (mounted) {
        setState(() {
          if (refundResult['success']) {
            _refunds = refundResult['data'] ?? [];
          }
          if (returnResult['success']) {
            _returns = returnResult['data'] ?? [];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching returns/refunds: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Returns & Refunds', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Refunds'),
            Tab(text: 'Replacements'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_refunds, 'refund', colorScheme),
              _buildList(_returns, 'replacement', colorScheme),
            ],
          ),
    );
  }

  Widget _buildList(List<dynamic> items, String type, ColorScheme colorScheme) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No active ${type == 'refund' ? 'refunds' : 'replacements'} found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildItemCard(item, type, colorScheme);
        },
      ),
    );
  }

  Widget _buildItemCard(dynamic item, String type, ColorScheme colorScheme) {
    final status = item['status']?.toString() ?? 'Pending';
    final date = item['createdAt']?.toString().split('T').first ?? 'N/A';
    final orderId = item['order']?['orderId'] ?? item['orderId'] ?? 'ID: Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      borderOnForeground: true,
      child: InkWell(
        onTap: () {
          if (item['order'] != null) {
            // Map the order data to match what OrderDetailsScreen expects
            final orderData = {
              'id': item['order']['_id'] ?? item['order']['id'],
              'status': item['order']['status'],
              'price': '₹${item['order']['total'] ?? item['order']['totalPrice'] ?? 0}',
              'date': item['order']['createdAt']?.toString().split('T').first,
              'full_order': item['order'],
            };
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: orderData)),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #$orderId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  _buildStatusChip(status, colorScheme),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Requested on: $date',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: ${item['reason'] ?? 'No reason provided'}',
                style: const TextStyle(fontSize: 14),
              ),
              if (item['adminComment'] != null && item['adminComment'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Comment:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['adminComment'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme colorScheme) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'processed' || status.toLowerCase() == 'replaced') {
      color = Colors.green;
    } else if (status.toLowerCase() == 'rejected') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
