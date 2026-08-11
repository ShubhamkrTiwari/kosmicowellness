import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onFailure,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet(response);
  }

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
    String? orderId,
    List<Map<String, dynamic>>? items,
  }) {
    debugPrint('Razorpay: Opening checkout for amount: $amount');
    debugPrint('Razorpay: Contact: $contact, Email: $email, Order ID: $orderId');

    var options = {
      'key': 'rzp_test_TJE6HyUpcQM08b',
      'key_id': 'rzp_test_TJE6HyUpcQM08b',
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Kosmico Wellness Private Limited',
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact.isNotEmpty ? contact : '9999999999',
        'email': email.isNotEmpty ? email : 'test@example.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    if (orderId != null) {
      options['order_id'] = orderId;
    }

    if (items != null && items.isNotEmpty) {
      Map<String, String> notes = {};
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final String name = item['name'] ?? 'Product';
        final int qty = item['qty'] ?? 1;
        notes['item_${i + 1}'] = '$name (x$qty)';
      }
      options['notes'] = notes;
    }

    try {
      debugPrint('Razorpay: Calling _razorpay.open with options: $options');
      _razorpay.open(options);
      debugPrint('Razorpay: _razorpay.open called successfully');
    } catch (e) {
      debugPrint('Razorpay: Error opening checkout: $e');
      if (e.toString().contains('MissingPluginException')) {
        onFailure(PaymentFailureResponse(2, 'Razorpay not supported on this platform (Web/Desktop)', {}));
      } else {
        onFailure(PaymentFailureResponse(3, e.toString(), {}));
      }
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
