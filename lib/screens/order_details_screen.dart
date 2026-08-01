import 'package:flutter/material.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';
import '../services/shiprocket_service.dart';
import '../widgets/rating_dialog.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _trackingData;
  bool _isLoadingTracking = false;

  @override
  void initState() {
    super.initState();
    _fetchTrackingDetails();
  }

  Future<void> _fetchTrackingDetails() async {
    final orderId = widget.order['id'];
    if (orderId == null || orderId == 'N/A') return;

    setState(() => _isLoadingTracking = true);
    final token = UserManager().token;
    if (token != null) {
      final result = await ApiService.trackOrder(orderId, token);
      if (result['success'] && result['data'] != null) {
        setState(() {
          _trackingData = result['data']['trackingData']?['tracking_data'];
        });
      }

      // Fallback to Estimation API if Shiprocket ETD is missing and not delivered/cancelled
      final status = widget.order['status']?.toString().toLowerCase();
      if ((_trackingData == null || _trackingData!['etd'] == null) && 
          status != 'delivered' && status != 'cancelled' && status != 'returned') {
        await _fetchEstimationFallback(token);
      }
    }
    if (mounted) setState(() => _isLoadingTracking = false);
  }

  Future<void> _fetchEstimationFallback(String token) async {
    try {
      final fullOrder = widget.order['full_order'] ?? {};
      final address = fullOrder['deliveryAddress'] ?? fullOrder['shippingAddress'] ?? fullOrder['address'] ?? {};
      final pincode = address['pincode']?.toString();
      
      if (pincode == null || pincode.isEmpty) return;

      final paymentMethod = widget.order['payment_mode'] == 'Online' ? 'Prepaid' : 'COD';

      final estResult = await ApiService.estimateDelivery(
        deliveryPincode: pincode,
        weight: 0.5,
        paymentMethod: paymentMethod,
        token: token,
      );

      if (estResult['success'] && estResult['data'] != null) {
        final etd = estResult['data']['estimatedDeliveryDate'];
        if (etd != null) {
          setState(() {
            _trackingData ??= {};
            _trackingData!['etd'] = etd;
            _trackingData!['is_estimated_fallback'] = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Tracking Estimation Fallback Error: $e');
    }
  }

  Future<void> _cancelOrder() async {
    final orderId = widget.order['id'];
    if (orderId == null || orderId == 'N/A') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, Keep Order')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingTracking = true);
    final token = UserManager().token;
    if (token != null) {
      final result = await ApiService.cancelOrder(orderId, token);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Go back to list and trigger refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to cancel order'), backgroundColor: Colors.red),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoadingTracking = false);
  }

  Future<void> _initiateReturnFlow() async {
    final orderId = widget.order['id'];
    if (orderId == null || orderId == 'N/A') return;

    final type = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Options'),
        content: const Text('How would you like to proceed with your return?'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, 'refund'),
                  child: const Text('Refund (Money Back)'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, 'replacement'),
                  child: const Text('Replacement (Exchange)'),
                ),
              ),
            ],
          )
        ],
      ),
    );

    if (type == null) return;

    String? selectedReason;
    final List<String> reasons = type == 'refund' 
      ? ['Defective product', 'Damaged during delivery', 'Quality not good', 'Other']
      : ['Wrong Size', 'Wrong Color', 'Defective Item', 'Other'];

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'refund' ? 'Initiate Refund' : 'Initiate Replacement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please select a reason:'),
            const SizedBox(height: 16),
            ...reasons.map((r) => ListTile(
              title: Text(r, style: const TextStyle(fontSize: 14)),
              onTap: () => Navigator.pop(context, r),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );

    if (reason == null) return;

    setState(() => _isLoadingTracking = true);
    final token = UserManager().token;
    if (token != null) {
      Map<String, dynamic> result;
      if (type == 'refund') {
        result = await ApiService.initiateRefund(orderId: orderId, reason: reason, token: token);
      } else {
        result = await ApiService.initiateReplacement(orderId: orderId, reason: reason, token: token);
      }
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${type == 'refund' ? 'Refund' : 'Replacement'} request submitted successfully'), 
              backgroundColor: Colors.green
            ),
          );
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Action failed'), backgroundColor: Colors.red),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoadingTracking = false);
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
          'Order Details',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTrackingDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Tracking Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Track Order', colorScheme),
                  if (_trackingData?['etd'] != null)
                    Text(
                      'Expected: ${_trackingData!['etd']}',
                      style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoadingTracking 
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : _buildTrackingStepper(colorScheme),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Items', colorScheme),
              const SizedBox(height: 16),
              ..._buildItemsList(widget.order, colorScheme),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Delivery Address', colorScheme),
              const SizedBox(height: 16),
              _buildAddressCard(colorScheme),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Payment Summary', colorScheme),
              const SizedBox(height: 16),
              _buildPaymentSummary(widget.order['price']!, colorScheme),
              
              const SizedBox(height: 40),
            // Show Cancel button if not delivered/cancelled
            if (widget.order['status']?.toString().toLowerCase() != 'delivered' && 
                widget.order['status']?.toString().toLowerCase() != 'cancelled' &&
                widget.order['status']?.toString().toLowerCase() != 'returned')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingTracking ? null : _cancelOrder,
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            
            // Show Return button ONLY if delivered
            if (widget.order['status']?.toString().toLowerCase() == 'delivered') ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => RatingDialog(order: widget.order),
                      );
                    },
                    icon: const Icon(Icons.star_outline, color: Colors.white),
                    label: const Text('Rate Products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingTracking ? null : _initiateReturnFlow,
                    icon: const Icon(Icons.assignment_return_outlined, color: Colors.white),
                    label: const Text('Return / Refund'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Need Help?'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildTrackingStepper(ColorScheme colorScheme) {
    List<dynamic> activities = _trackingData?['shipment_track_activities'] ?? [];
    
    // Fallback steps if no real tracking activities yet
    if (activities.isEmpty) {
      final status = widget.order['status']?.toString().toLowerCase() ?? 'pending';
      final String etdText = _trackingData?['etd'] ?? 'Expected soon';
      
      return Column(
        children: [
          _buildStep('Order Placed', widget.order['date'] ?? '', true, false, colorScheme),
          _buildStep('Processing', 'In progress', status != 'pending', false, colorScheme),
          _buildStep('In Transit', 'Pending', status == 'shipped' || status == 'in transit', false, colorScheme),
          _buildStep('Delivered', etdText, status == 'delivered', true, colorScheme),
        ],
      );
    }

    // Map Shiprocket activities to stepper
    return Column(
      children: List.generate(activities.length, (index) {
        final activity = activities[index];
        final bool isLast = index == activities.length - 1;
        return _buildStep(
          activity['activity'] ?? activity['status'] ?? 'Update',
          '${activity['date']} - ${activity['location']}',
          true,
          isLast,
          colorScheme,
        );
      }),
    );
  }

  Widget _buildStep(String title, String date, bool done, bool isLast, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? colorScheme.primary : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: done ? colorScheme.primary : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: done ? Colors.black87 : Colors.grey,
                ),
              ),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItemsList(Map<String, dynamic> order, ColorScheme colorScheme) {
    final List items = order['full_order']?['items'] ?? order['full_order']?['products'] ?? order['full_order']?['orderItems'] ?? [];
    if (items.isEmpty) {
      return [_buildItemCard(
        order['items_text'] ?? order['items'] ?? 'Wellness Product', 
        order['price'] ?? '0', 
        '📦', 
        colorScheme,
        imageUrl: order['image'],
      )];
    }

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildItemCard(
          _getItemName(item),
          '₹${item['price'] ?? 0}',
          '📦',
          colorScheme,
          quantity: item['quantity']?.toString() ?? '1',
          imageUrl: _getItemImage(item),
        ),
      );
    }).toList();
  }

  Widget _buildItemCard(String name, String price, String icon, ColorScheme colorScheme, {String quantity = '1', String? imageUrl}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: imageUrl != null && imageUrl.isNotEmpty
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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Quantity: $quantity', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ColorScheme colorScheme) {
    final fullOrder = widget.order['full_order'] ?? {};
    final address = fullOrder['deliveryAddress'] ?? fullOrder['shippingAddress'] ?? fullOrder['address'] ?? {};
    
    String name = address['fullName']?.toString() ?? 'Customer';
    String street = address['streetAddress']?.toString() ?? address['address']?.toString() ?? 'No address provided';
    String city = address['city']?.toString() ?? '';
    String pincode = address['pincode']?.toString() ?? '';
    String phone = address['phoneNumber']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '$street\n$city - $pincode\n$phone',
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(String totalPrice, ColorScheme colorScheme) {
    final fullOrder = widget.order['full_order'] ?? {};
    final double total = (fullOrder['amount'] ?? fullOrder['totalPrice'] ?? 0).toDouble();
    final double discount = (fullOrder['discountAmount'] ?? 0).toDouble();
    final double subtotal = total + discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Payment Mode', widget.order['payment_mode'] ?? 'N/A', false, colorScheme),
          const SizedBox(height: 8),
          _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}', false, colorScheme),
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery Fee', 'FREE', false, colorScheme),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Discount', '-₹${discount.toStringAsFixed(0)}', true, colorScheme),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildSummaryRow('Total Amount', '₹${total.toStringAsFixed(0)}', false, colorScheme, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDiscount, ColorScheme colorScheme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : (isTotal ? colorScheme.primary : Colors.black87),
          ),
        ),
      ],
    );
  }
}
