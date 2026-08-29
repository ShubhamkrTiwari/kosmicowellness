import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../managers/cart_manager.dart';
import '../managers/payment_manager.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';
import '../services/razorpay_service.dart';
import '../services/shiprocket_service.dart';
import 'shipping_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'coupons_screen.dart';
import 'my_orders_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';

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
  double _deliveryFee = 0.0;
  double _gstAmount = 0.0;
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  bool _isCOD = false;
  String? _expectedDeliveryDate;
  bool _isEstimatingDelivery = false;
  late RazorpayService _razorpayService;
  String? _currentRazorpayOrderId;

  double get _finalTotal => CartManager().totalPrice - _discountAmount + _deliveryFee + _gstAmount;

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
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpayService = RazorpayService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _currentRazorpayOrderId = null;
    _finalizeOrder(response.paymentId);
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    setState(() => _isPlacingOrder = false);
    
    // Call backend to cancel pending order if we have the order ID
    if (_currentRazorpayOrderId != null) {
      final token = UserManager().token;
      if (token != null) {
        ApiService.cancelPendingRazorpayOrder(
          razorpayOrderId: _currentRazorpayOrderId!,
          token: token,
        );
      }
      _currentRazorpayOrderId = null;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? 'Unknown Error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  Future<void> _fetchDeliveryEstimation() async {
    if (_selectedAddress == null || _selectedAddress!['pincode'] == null || _selectedAddress!['pincode'].toString().isEmpty) {
      debugPrint('Checkout: Pincode missing, skipping estimation');
      return;
    }
    
    final token = UserManager().token;
    if (token == null) return;

    setState(() {
      _isEstimatingDelivery = true;
      _expectedDeliveryDate = null;
    });

    try {
      final pincode = _selectedAddress!['pincode'].toString();
      debugPrint('Checkout: Fetching delivery estimation for $pincode via Backend');
      
      final result = await ApiService.estimateDelivery(
        deliveryPincode: pincode,
        weight: 0.5,
        paymentMethod: _isCOD ? 'COD' : 'Prepaid',
        token: token,
      );

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final String? etd = data['estimatedDeliveryDate']?.toString();
        final double fee = (data['deliveryFee'] ?? 0.0).toDouble();
        final double gst = (data['gstCharge'] ?? data['gstAmount'] ?? data['gst'] ?? 0.0).toDouble();
        
        if (etd != null) {
          setState(() {
            _expectedDeliveryDate = etd;
            _deliveryFee = fee;
            _gstAmount = gst;
          });
          debugPrint('Checkout: Estimated delivery date: $_expectedDeliveryDate, Fee: $_deliveryFee, GST: $_gstAmount');
        } else {
          debugPrint('Checkout: No estimatedDeliveryDate found in backend response');
          setState(() {
            _expectedDeliveryDate = 'Date unavailable';
            _deliveryFee = fee;
            _gstAmount = gst;
          });
        }
      } else {
        debugPrint('Checkout: Backend estimation returned failure: ${result['message']}');
        setState(() {
          _expectedDeliveryDate = 'Delivery check failed';
          _deliveryFee = 0.0;
          _gstAmount = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Checkout: Backend Estimation Error: $e');
      setState(() => _expectedDeliveryDate = 'Error checking delivery');
    } finally {
      if (mounted) setState(() => _isEstimatingDelivery = false);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      final token = UserManager().token;
      if (token != null) {
        debugPrint('Checkout: Loading initial data...');
        
        // Load addresses
        final addressResult = await ApiService.getAddresses(token).timeout(const Duration(seconds: 15));
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

          setState(() {
            _selectedAddress = addresses.firstWhere(
              (addr) => addr['isDefault'] == 'true',
              orElse: () => addresses.first,
            );
          });
          debugPrint('Checkout: Addresses loaded');
          
          // Fetch delivery estimation for initial address
          _fetchDeliveryEstimation();
        }

        // Load payment methods
        debugPrint('Checkout: Loading payment methods...');
        await PaymentManager().fetchPaymentMethods().timeout(const Duration(seconds: 15));
        final methods = PaymentManager().paymentMethods;
        if (methods.isNotEmpty) {
          setState(() {
            _selectedPaymentMethod = methods.firstWhere(
              (m) => m['isDefault'] == true || m['isDefault'].toString() == 'true',
              orElse: () => methods.first,
            );
          });
          debugPrint('Checkout: Payment methods loaded');
        }
      }
    } catch (e) {
      debugPrint('Checkout Error during load: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load checkout data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) {
      debugPrint('Checkout: _placeOrder already in progress, ignoring duplicate call');
      return;
    }
    debugPrint('Checkout: _placeOrder called');
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a shipping address')));
      return;
    }
    if (!_isCOD && _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an online payment method')));
      return;
    }

    if (!_isCOD && kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Razorpay is not supported on Web. Please use the Android app.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isPlacingOrder = true);
      final token = UserManager().token;
      if (token == null) {
        setState(() => _isPlacingOrder = false);
        return;
      }
      final addressId = _selectedAddress!['_id']?.toString() ?? _selectedAddress!['id']?.toString() ?? '';
      
      // Validate items have IDs before proceeding
      final List<Map<String, dynamic>> items = CartManager().items;
      if (items.any((item) => (item['id'] ?? '').toString().isEmpty)) {
        setState(() => _isPlacingOrder = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Some items in your cart are invalid. Please clear your cart and re-add items.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Format items for backend: expect "product" (id) and "qty"
      final apiItems = items.map((item) => {
        'product': item['id'],
        'qty': item['quantity'],
        'price': item['price'],
        'name': item['name'],
      }).toList();

      if (_isCOD) {
        debugPrint('Checkout: Calling /api/payment/cod with fee: $_deliveryFee, GST: $_gstAmount');
        final result = await ApiService.placeCodOrder(
          amount: _finalTotal,
          addressId: addressId,
          items: apiItems,
          token: token,
          couponCode: _appliedCoupon?['code'],
          discountAmount: _discountAmount,
          deliveryFee: _deliveryFee,
          gstCharge: _gstAmount,
        );
        _handleOrderResponse(result);
      } else {
        debugPrint('Checkout: Calling /api/payment/razorpay/create with fee: $_deliveryFee, GST: $_gstAmount');
        final result = await ApiService.createRazorpayOrder(
          amount: _finalTotal,
          addressId: addressId,
          items: apiItems,
          token: token,
          couponCode: _appliedCoupon?['code'],
          discountAmount: _discountAmount,
          deliveryFee: _deliveryFee,
          gstCharge: _gstAmount,
        );

        if (result['success'] && result['data'] != null) {
          debugPrint('Checkout: API Response Data: ${result['data']}');
          final razorpayOrderId = result['data']['id'] ?? 
                                  result['data']['orderId'] ?? 
                                  result['data']['razorpay_order_id'] ??
                                  result['data']['order']?['id'] ??
                                  result['data']['order']?['_id'] ??
                                  result['data']['order']?['orderId'];
          debugPrint('Checkout: Extracted Razorpay Order ID: $razorpayOrderId');
          
          if (razorpayOrderId == null) {
            debugPrint('Checkout: Error - Razorpay Order ID is null in response');
            setState(() => _isPlacingOrder = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Server error: Order ID not generated'), backgroundColor: Colors.red),
              );
            }
            return;
          }
          
          setState(() => _isPlacingOrder = false); // Reset before opening UI
          _currentRazorpayOrderId = razorpayOrderId;
          
          _razorpayService.openCheckout(
            amount: _finalTotal,
            contact: UserManager().userPhone ?? '9999999999',
            email: UserManager().userEmail ?? 'test@example.com',
            description: 'Order Payment for Kosmico Wellness Private Limited',
            orderId: razorpayOrderId,
            items: apiItems,
          );
        } else {
          debugPrint('Checkout: Razorpay creation failed: ${result['message']}');
          setState(() => _isPlacingOrder = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to initiate payment'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Checkout: Error in _placeOrder: $e');
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleOrderResponse(Map<String, dynamic> result) {
    if (result['success']) {
      // Step 3: Sync with Shiprocket Dashboard
      final orderId = result['data']?['order']?['_id']?.toString() ?? 
                      result['data']?['orderId']?.toString() ?? 
                      'KOSMICO_${DateTime.now().millisecondsSinceEpoch}';
      _syncOrderToShiprocket(orderId, null);

      // Success!
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to place order')));
      }
    }
    setState(() => _isPlacingOrder = false);
  }

  Future<void> _finalizeOrder(String? razorpayPaymentId) async {
    // This is now used after Razorpay success
    final token = UserManager().token;
    if (token != null) {
      // For online orders, we still call the backend to finalize/verify
      // In some backends, payment verification is a separate step.
      // For now, I'll assume we still need to call placeOrder with the payment ID
      // or a verification endpoint if provided.
      
      final cartItems = CartManager().items;
      final addressId = _selectedAddress!['_id']?.toString() ?? _selectedAddress!['id']?.toString() ?? '';
      final paymentMethodId = _selectedPaymentMethod?['_id']?.toString() ?? _selectedPaymentMethod?['id']?.toString() ?? 'RAZORPAY';
      
      // Format items for backend
      final apiItems = CartManager().items.map((item) => {
        'product': item['id'],
        'qty': item['quantity'],
        'price': item['price'],
        'name': item['name'],
      }).toList();
      
      final result = await ApiService.placeOrder(
        items: apiItems,
        addressId: addressId,
        paymentMethodId: paymentMethodId,
        totalPrice: _finalTotal,
        token: token,
        couponCode: _appliedCoupon?['code'],
        razorpayPaymentId: razorpayPaymentId,
      );

      _handleOrderResponse(result);
    } else {
      setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _syncOrderToShiprocket(String orderId, String? paymentId) async {
    try {
      final user = UserManager();
      final cart = CartManager();
      
      // Split name into first and last for Shiprocket
      List<String> nameParts = (_selectedAddress?['name'] ?? user.userName ?? 'Customer').toString().split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

      final Map<String, dynamic> shiprocketData = {
        'order_id': orderId,
        'order_date': DateTime.now().toString().split('.').first, // YYYY-MM-DD HH:mm:ss
        'pickup_location': ShiprocketService.pickupLocation,
        'billing_customer_name': firstName,
        'billing_last_name': lastName,
        'billing_address': _selectedAddress?['address'] ?? 'No Address',
        'billing_city': _selectedAddress?['city'] ?? 'City',
        'billing_pincode': _selectedAddress?['pincode'] ?? '',
        'billing_state': 'Maharashtra', // Fallback as app doesn't have state field
        'billing_country': 'India',
        'billing_email': user.userEmail ?? 'test@example.com',
        'billing_phone': _selectedAddress?['phone'] ?? user.userPhone ?? '',
        'shipping_is_billing': true,
        'order_items': cart.items.map((item) => {
          'name': item['name'],
          'sku': item['name'].toString().replaceAll(' ', '_'),
          'units': item['quantity'],
          'selling_price': item['price'],
          'discount': '',
          'tax': '',
          'hsn': '',
        }).toList(),
        'payment_method': _isCOD ? 'COD' : 'Prepaid',
        'sub_total': _finalTotal,
        'length': 10,
        'breadth': 10,
        'height': 10,
        'weight': 0.5,
      };

      debugPrint('Shiprocket: Syncing order $orderId...');
      final response = await ShiprocketService.createOrder(shiprocketData);
      
      if (response['success'] == true) {
        debugPrint('Shiprocket: Order synced successfully!');
        
        // Step 5: Automatically Assign AWB (Optional but recommended for automation)
        final shipmentId = response['data']?['shipment_id'];
        if (shipmentId != null) {
          debugPrint('Shiprocket: Assigning AWB for shipment $shipmentId...');
          final awbResponse = await ShiprocketService.assignAwb(shipmentId: shipmentId);
          if (awbResponse['success'] == true) {
            debugPrint('Shiprocket: AWB Assigned successfully: ${awbResponse['data']?['response']?['data']?['awb_code']}');
          } else {
            debugPrint('Shiprocket: AWB Assignment failed: ${awbResponse['message']}');
          }
        }
      } else {
        debugPrint('Shiprocket Sync Failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Shiprocket Sync Exception: $e');
    }
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      CartManager().clearCart();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Home'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      CartManager().clearCart();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const MyOrdersScreen())
                      );
                    },
                    child: const Text('My Orders'),
                  ),
                ),
              ],
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
                    setState(() {
                      _selectedAddress = result;
                      _expectedDeliveryDate = null; // Clear old date
                    });
                    _fetchDeliveryEstimation(); // Fetch for new address
                  }
                }),
                _buildAddressCard(colorScheme),
                const SizedBox(height: 24),
                
                const Text('Payment Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeChip('Online', !_isCOD, Icons.payment, colorScheme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeChip('Cash on Delivery', _isCOD, Icons.delivery_dining, colorScheme),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (!_isCOD) ...[
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
                ],

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
              : Text('Place Order - ₹${_finalTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
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

  Widget _buildModeChip(String label, bool isSelected, IconData icon, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        final bool newIsCOD = label == 'Cash on Delivery';
        if (newIsCOD != _isCOD) {
          setState(() => _isCOD = newIsCOD);
          _fetchDeliveryEstimation(); // Re-fetch estimation when payment mode changes
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(ColorScheme colorScheme) {
    if (_selectedAddress == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.add_location_alt_rounded, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Text('No address selected', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final String label = _selectedAddress!['label'] ?? 'Home';
    final IconData labelIcon = label.toLowerCase().contains('home') ? Icons.home_rounded : Icons.business_rounded;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10, top: -10,
              child: Icon(labelIcon, size: 60, color: colorScheme.primary.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                        child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedAddress!['isDefault'] == 'true')
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_selectedAddress!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('${_selectedAddress!['address']}, ${_selectedAddress!['city']} - ${_selectedAddress!['pincode']}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(_selectedAddress!['phone'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Divider(height: 24, thickness: 0.5),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_rounded, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEstimatingDelivery ? 'Calculating delivery date...' : (_expectedDeliveryDate != null ? 'Expected: $_expectedDeliveryDate' : 'Checking availability...'),
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildPaymentCard(ColorScheme colorScheme) {
    if (_selectedPaymentMethod == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colorScheme.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.payment_rounded, color: colorScheme.secondary, size: 20),
            ),
            const SizedBox(width: 16),
            Text('Select payment method', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final bool isBank = _selectedPaymentMethod!['type'] == 'BANK_ACCOUNT';
    final Color cardColor = isBank ? const Color(0xFF1B264F) : const Color(0xFF00833E);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: CircleAvatar(radius: 50, backgroundColor: Colors.white.withValues(alpha: 0.05))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(isBank ? 'BANK' : 'UPI', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBank ? (_selectedPaymentMethod!['accountNumber']?.toString() ?? 'XXXX') : (_selectedPaymentMethod!['upiId'] ?? '').toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (isBank ? (_selectedPaymentMethod!['accountHolderName'] ?? 'NAME') : (_selectedPaymentMethod!['displayName'] ?? 'NAME')).toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Expanded(
                child: Text(
                  'Select a coupon code', 
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
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
                Expanded(
                  child: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('₹${((item['price'] as int) * (item['quantity'] as int))}', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              Text('₹${cartManager.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5)),
            ],
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupon Discount', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                Text('- ₹${_discountAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              _isEstimatingDelivery 
                ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _deliveryFee > 0 ? '₹${_deliveryFee.toStringAsFixed(0)}' : 'FREE', 
                    style: TextStyle(
                      color: _deliveryFee > 0 ? colorScheme.onSurface : Colors.green, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    )
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GST', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              _isEstimatingDelivery 
                ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _gstAmount > 0 ? '₹${_gstAmount.toStringAsFixed(0)}' : '₹0', 
                    style: TextStyle(
                      color: colorScheme.onSurface, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    )
                  ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '₹${_finalTotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary, letterSpacing: 0.5)
              ),
            ],
          ),
        ],
      ),
    );
  }
}
