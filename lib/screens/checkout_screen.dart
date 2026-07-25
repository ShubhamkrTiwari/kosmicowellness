import 'package:flutter/material.dart';
import '../managers/cart_manager.dart';
import '../managers/payment_manager.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';
import 'shipping_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'coupons_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedPaymentMethod;
  Map<String, dynamic>? _appliedCoupon;
  double _discountAmount = 0.0;
  bool _isLoading = false;
  bool _isPlacingOrder = false;

  double get _finalTotal => CartManager().totalPrice - _discountAmount;

  Future<void> _applyCouponCode(String code) async {
    setState(() => _isLoading = true);
    final token = UserManager().token;
    if (token != null) {
      final result = await ApiService.applyCoupon(
        code: code,
        orderAmount: CartManager().totalPrice,
        token: token,
      );

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _discountAmount = (data['discountAmount'] ?? 0.0).toDouble();
          _appliedCoupon = data['couponDetails'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Coupon applied!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Invalid coupon'), backgroundColor: Colors.red),
          );
        }
        setState(() {
          _appliedCoupon = null;
          _discountAmount = 0.0;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final token = UserManager().token;
    if (token != null) {
      // Load addresses
      final addressResult = await ApiService.getAddresses(token);
      if (addressResult['success'] && addressResult['data'] is List && (addressResult['data'] as List).isNotEmpty) {
        final List rawAddresses = addressResult['data'];
        final List<Map<String, String>> addresses = rawAddresses.map((addr) => {
          'id': addr['_id']?.toString() ?? addr['id']?.toString() ?? '',
          'label': addr['addressLabel']?.toString() ?? 'Home',
          'name': addr['fullName']?.toString() ?? '',
          'address': addr['streetAddress']?.toString() ?? '',
          'city': addr['city']?.toString() ?? '',
          'pincode': addr['pincode']?.toString() ?? '',
          'phone': addr['phoneNumber']?.toString() ?? '',
          'isDefault': addr['isDefault']?.toString() ?? 'false',
        }).toList();

        // Try to find default address
        _selectedAddress = addresses.firstWhere(
          (addr) => addr['isDefault'] == 'true',
          orElse: () => addresses.first,
        );
      }

      // Load payment methods
      await PaymentManager().fetchPaymentMethods();
      final methods = PaymentManager().paymentMethods;
      if (methods.isNotEmpty) {
        _selectedPaymentMethod = methods.firstWhere(
          (m) => m['isDefault'] == true || m['isDefault'].toString() == 'true',
          orElse: () => methods.first,
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a shipping address')));
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment method')));
      return;
    }

    setState(() => _isPlacingOrder = true);
    final token = UserManager().token;
    if (token != null) {
      final cartItems = CartManager().items;
      final addressId = _selectedAddress!['_id']?.toString() ?? _selectedAddress!['id']?.toString() ?? '';
      final paymentMethodId = _selectedPaymentMethod!['_id']?.toString() ?? _selectedPaymentMethod!['id']?.toString() ?? '';
      
      final result = await ApiService.placeOrder(
        items: cartItems,
        addressId: addressId,
        paymentMethodId: paymentMethodId,
        totalPrice: _finalTotal,
        token: token,
        couponCode: _appliedCoupon?['code'],
      );

      if (result['success']) {
        // Success!
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to place order')));
        }
      }
    }
    setState(() => _isPlacingOrder = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Order Placed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your order has been placed successfully.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Clear cart and go home
                  CartManager().clearCart();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartManager = CartManager();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Shipping Address', () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ShippingAddressesScreen(isSelectionMode: true))
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() => _selectedAddress = result);
                  }
                }),
                _buildAddressCard(colorScheme),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Payment Method', () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PaymentMethodsScreen(isSelectionMode: true))
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() => _selectedPaymentMethod = result);
                  }
                }),
                _buildPaymentCard(colorScheme),
                const SizedBox(height: 24),

                _buildSectionHeader('Apply Coupon', () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CouponsScreen(isSelectionMode: true))
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    _applyCouponCode(result['code']);
                  }
                }),
                _buildCouponCard(colorScheme),
                const SizedBox(height: 24),

                const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildOrderSummary(cartManager, colorScheme),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isPlacingOrder 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Place Order - ₹${_finalTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onEdit, child: const Text('Change')),
      ],
    );
  }

  Widget _buildAddressCard(ColorScheme colorScheme) {
    if (_selectedAddress == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_location_alt_outlined, color: Colors.grey),
            SizedBox(width: 12),
            Text('No address selected', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_selectedAddress!['label'] ?? 'Home', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              if (_selectedAddress!['isDefault'] == 'true')
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(_selectedAddress!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${_selectedAddress!['address']}, ${_selectedAddress!['city']} - ${_selectedAddress!['pincode']}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(_selectedAddress!['phone'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(ColorScheme colorScheme) {
    if (_selectedPaymentMethod == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.payment_outlined, color: Colors.grey),
            SizedBox(width: 12),
            Text('No payment method selected', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final bool isBank = _selectedPaymentMethod!['type'] == 'BANK_ACCOUNT';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isBank ? const Color(0xFF1B264F) : const Color(0xFF00833E)).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isBank ? const Color(0xFF1B264F) : const Color(0xFF00833E)).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isBank ? const Color(0xFF1B264F) : const Color(0xFF00833E)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isBank ? Icons.account_balance : Icons.vibration, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBank ? 'Bank Account' : 'UPI ID', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isBank 
                    ? (_selectedPaymentMethod!['accountNumber']?.toString() ?? 'XXXX') 
                    : (_selectedPaymentMethod!['upiId'] ?? _selectedPaymentMethod!['upild'] ?? '').toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildCouponCard(ColorScheme colorScheme) {
    if (_appliedCoupon == null) {
      return InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CouponsScreen(isSelectionMode: true))
          );
          if (result != null && result is Map<String, dynamic>) {
            _applyCouponCode(result['code']);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Select a coupon code', style: TextStyle(color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    final String title = _appliedCoupon!['title'] ?? 'OFFER';
    final String code = _appliedCoupon!['code'] ?? '';
    final String type = _appliedCoupon!['discountType'] ?? 'fixed';
    Color couponColor = colorScheme.primary;
    if (type == 'percentage') couponColor = const Color(0xFF00833E);
    if (type == 'fixed') couponColor = const Color(0xFF1B264F);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couponColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couponColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: couponColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: couponColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _appliedCoupon = null;
              _discountAmount = 0.0;
            }),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartManager cartManager, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ...cartManager.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text('${item['quantity']}x ', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                Text('₹${((item['price'] as int) * (item['quantity'] as int))}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: Colors.grey)),
              Text('₹${cartManager.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Coupon Discount', style: TextStyle(color: Colors.grey)),
                Text('- ₹${_discountAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
              Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '₹${_finalTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)
              ),
            ],
          ),
        ],
      ),
    );
  }
}
