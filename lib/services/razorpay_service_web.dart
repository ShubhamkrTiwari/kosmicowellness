import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as dart_js;

class RazorpayService {
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onFailure,
    required this.onExternalWallet,
  });

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
    String? orderId,
    List<Map<String, dynamic>>? items,
  }) {
    debugPrint('Razorpay Web: Opening checkout for amount: $amount');
    try {
      dart_js.context['onRazorpaySuccess'] = (paymentId, orderId, signature) {
        debugPrint('Razorpay Web Success: paymentId=$paymentId, orderId=$orderId, signature=$signature');
        onSuccess(PaymentSuccessResponse(
          paymentId?.toString(),
          orderId?.toString(),
          signature?.toString(),
          {},
        ));
      };

      dart_js.context['onRazorpayError'] = (message, code) {
        debugPrint('Razorpay Web Error: $message (code: $code)');
        onFailure(PaymentFailureResponse(
          code is int ? code : (int.tryParse(code?.toString() ?? '0') ?? 0),
          message?.toString() ?? 'Payment Failed',
          {},
        ));
      };

      final optionsMap = {
        'key': 'rzp_live_TcH3s5Qdh4ngAp',
        'amount': (amount * 100).toInt(),
        'currency': 'INR',
        'name': 'Kosmico Wellness Private Limited',
        'description': description,
        if (orderId != null) 'order_id': orderId,
        'prefill': {
          'contact': contact.isNotEmpty ? contact : '9999999999',
          'email': email.isNotEmpty ? email : 'test@example.com',
        },
      };

      dart_js.context.callMethod('openRazorpayCheckout', [jsonEncode(optionsMap)]);
    } catch (e) {
      onFailure(PaymentFailureResponse(1, e.toString(), {}));
    }
  }

  void dispose() {}
}
