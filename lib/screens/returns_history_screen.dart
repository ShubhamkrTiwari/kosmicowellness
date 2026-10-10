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
        ApiService.getUserOrders(token, page: 1, limit: 50),
      ]);

      final refundResult = results[0];
      final returnResult = results[1];
      final ordersResult = results[2];
      
      if (mounted) {
        setState(() {
          if (refundResult['success']) {
            _refunds = refundResult['data'] ?? [];
          }
          if (returnResult['success']) {
            _returns = returnResult['data'] ?? [];
          }
          // Merge refunds processed directly via Razorpay (e.g. from the
          // Razorpay dashboard / payment gateway) that are recorded on the
          // order itself, so they also appear in the Refunds tab.
          if (ordersResult['success']) {
            _refunds = [
              ..._refunds,
              ..._extractRazorpayOrderRefunds(ordersResult['data'], _refunds),
            ];
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

  /// Extracts refunds that were processed directly through Razorpay (from the
  /// Razorpay dashboard or a gateway webhook) and recorded on the order,
  /// rather than through a refund request. Orders already covered by an
  /// existing refund request are skipped to avoid duplicates.
  List<dynamic> _extractRazorpayOrderRefunds(dynamic rawData, List<dynamic> existingRefunds) {
    List orders = [];
    if (rawData is List) {
      orders = rawData;
    } else if (rawData is Map) {
      orders = rawData['orders'] ?? rawData['data'] ?? [];
    }

    // Order IDs already covered by refund requests -> avoid duplicates
    final Set<String> covered = existingRefunds.map((r) {
      final o = r['order'];
      return (o is Map ? (o['orderId'] ?? o['_id'] ?? o['id']) : (r['orderId'] ?? ''))?.toString() ?? '';
    }).where((id) => id.isNotEmpty).toSet();

    final List<dynamic> orderRefunds = [];
    for (final o in orders) {
      if (o is! Map) continue;

      final String status = (o['status'] ?? o['orderStatus'] ?? o['paymentStatus'] ?? '').toString().toLowerCase();
      final String paymentMethod = (o['paymentMethodId'] ?? o['paymentMethod'] ?? '').toString().toLowerCase();
      final dynamic refundId = o['refundId'] ?? o['razorpayRefundId'] ?? o['refund_id'];
      final dynamic refundAmount = o['refundAmount'] ?? o['refund_amount'];
      final bool isRazorpayOrder = paymentMethod.contains('razorpay') || paymentMethod.contains('online') || paymentMethod.contains('prepaid');
      final bool isRefunded = status.contains('refund') ||
          (status == 'returned' && isRazorpayOrder) ||
          refundId != null ||
          refundAmount != null ||
          o['isRefunded'] == true ||
          o['refunded'] == true;

      if (!isRefunded) continue;

      final String orderId = (o['orderId'] ?? o['_id'] ?? o['id'] ?? '').toString();
      if (orderId.isEmpty || covered.contains(orderId)) continue;
      covered.add(orderId);

      orderRefunds.add({
        'status': 'Refunded',
        'createdAt': o['refundedAt'] ?? o['updatedAt'] ?? o['createdAt'],
        'reason': o['returnReason'] ?? o['cancelReason'] ?? o['reason'] ?? 'Refunded via Razorpay',
        'refundAmount': refundAmount ?? o['amount'] ?? o['totalPrice'],
        'refundId': refundId,
        'razorpayPaymentId': o['razorpayPaymentId'] ?? o['paymentId'] ?? o['razorpay_payment_id'],
        'order': {
          'orderId': orderId,
          '_id': o['_id'] ?? orderId,
          'status': o['status'],
          'total': o['amount'] ?? o['totalPrice'],
          'createdAt': o['createdAt'],
        },
      });
    }
    return orderRefunds;
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
    final isRefundType = type == 'refund';
    final dynamic refundAmount = item['refundAmount'] ?? item['amount'];
    final String paymentId = (item['razorpayPaymentId'] ?? item['paymentId'] ?? '').toString();
    final String refundId = (item['refundId'] ?? item['razorpayRefundId'] ?? '').toString();

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
              if (isRefundType && refundAmount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.currency_rupee, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Refund Amount: \u20b9${_formatAmount(refundAmount)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green[700]),
                    ),
                    if (paymentId.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'via Razorpay',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (isRefundType && paymentId.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Razorpay Payment ID: $paymentId',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
              if (isRefundType && refundId.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Refund ID: $refundId',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
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
    final String lower = status.toLowerCase();
    Color color = Colors.orange;
    if (lower == 'approved' ||
        lower == 'processed' ||
        lower == 'replaced' ||
        lower == 'refunded' ||
        lower == 'completed' ||
        lower == 'credited') {
      color = Colors.green;
    } else if (lower == 'rejected') {
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

  String _formatAmount(dynamic amount) {
    final double? value = amount is num ? amount.toDouble() : double.tryParse(amount.toString());
    if (value == null) return amount.toString();
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }
}
