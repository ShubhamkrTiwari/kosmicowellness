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
    debugPrint('Razorpay Mobile: Opening checkout for amount: $amount');
    var options = {
      'key': 'rzp_live_TcH3s5Qdh4ngAp',
      'key_id': 'rzp_live_TcH3s5Qdh4ngAp',
      'amount': (amount * 100).toInt(),
      'name': 'Kosmico Wellness Private Limited',
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact.isNotEmpty ? contact : '9999999999',
        'email': email.isNotEmpty ? email : 'test@example.com'
      },
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
      _razorpay.open(options);
    } catch (e) {
      onFailure(PaymentFailureResponse(3, e.toString(), {}));
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
