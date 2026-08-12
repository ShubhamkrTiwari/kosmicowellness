import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/maintenance_screen.dart';

class ApiService {

  static const String baseUrl = 'http://3.7.180.215:5000';

  // Helper to ensure clean URLs without double slashes
  static Uri _getUri(String path) {
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }
  
  static Future<Map<String, dynamic>> updateProfileWithImage({
    required String name,
    required String phoneNumber,
    XFile? imageFile,
    required String token,
  }) async {
    try {
      var uri = _getUri('/api/auth/profile');
      var request = http.MultipartRequest('PUT', uri);
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      request.fields['name'] = name;
      request.fields['phoneNumber'] = phoneNumber;

      if (imageFile != null) {
        Uint8List imageBytes = await imageFile.readAsBytes();

        // Determine the mime type based on file extension
        String ext = imageFile.name.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg'; // Default
        if (ext == 'png') mimeType = 'image/png';
        if (ext == 'gif') mimeType = 'image/gif';
        if (ext == 'webp') mimeType = 'image/webp';

        var multipartFile = http.MultipartFile.fromBytes(
          'profilePicture', 
          imageBytes,
          filename: imageFile.name,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      debugPrint('API Error: $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email) async {
    try {
      final url = _getUri('/api/auth/register');
      debugPrint('DEBUG: Requesting Register -> $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'KosmicoApp/1.0', // Added to avoid bot detection
          'Connection': 'keep-alive',
        },
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(const Duration(seconds: 95));
      
      debugPrint('DEBUG: Response received. Status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      debugPrint('DEBUG: Register Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> login(String email) async {
    try {
      final url = _getUri('/api/auth/login');
      debugPrint('DEBUG: Requesting Login -> $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'KosmicoApp/1.0',
          'Connection': 'keep-alive',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(const Duration(seconds: 95));
      
      debugPrint('DEBUG: Response received. Status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      debugPrint('DEBUG: Login Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> verifySignup(String email, String otp) async {
    try {
      final response = await http.post(
        _getUri('/api/auth/signup-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 90));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> verifyLogin(String email, String otp) async {
    try {
      final response = await http.post(
        _getUri('/api/auth/login-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 90));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await http.post(
        _getUri('/api/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> saveAddress({
    required String addressLabel,
    required String fullName,
    required String streetAddress,
    required String city,
    required String pincode,
    required String phoneNumber,
    required String token,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'addressLabel': addressLabel,
          'fullName': fullName,
          'streetAddress': streetAddress,
          'city': city,
          'pincode': pincode,
          'phoneNumber': phoneNumber,
          'isDefault': isDefault,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getAddresses(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/address'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String addressLabel,
    required String fullName,
    required String streetAddress,
    required String city,
    required String pincode,
    required String phoneNumber,
    required String token,
    bool? isDefault,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'addressLabel': addressLabel,
        'fullName': fullName,
        'streetAddress': streetAddress,
        'city': city,
        'pincode': pincode,
        'phoneNumber': phoneNumber,
      };
      if (isDefault != null) body['isDefault'] = isDefault;

      final response = await http.put(
        _getUri('/api/address/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> setDefaultAddress(String addressId, String token) async {
    try {
      final response = await http.put(
        _getUri('/api/address/set-default/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteAddress(String addressId, String token) async {
    try {
      final response = await http.delete(
        _getUri('/api/address/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getPaymentMethods(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/payment/saved-methods'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'User-Agent': 'KosmicoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> savePaymentMethod(Map<String, dynamic> methodData, String token) async {
    try {
      final url = _getUri('/api/payment/save-method');
      debugPrint('DEBUG: Requesting Save Payment Method -> $url');
      debugPrint('DEBUG: Body -> ${jsonEncode(methodData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'KosmicoApp/1.0',
        },
        body: jsonEncode(methodData),
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('DEBUG: Response Status: ${response.statusCode}');
      debugPrint('DEBUG: Response Body: ${response.body}');
      
      return _processResponse(response);
    } catch (e) {
      debugPrint('DEBUG: Save Payment Method Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updatePaymentMethod(String methodId, Map<String, dynamic> methodData, String token) async {
    try {
      final url = _getUri('/api/payment/save-method/$methodId');
      debugPrint('DEBUG: Requesting Update Payment Method -> $url');
      debugPrint('DEBUG: Body -> ${jsonEncode(methodData)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'KosmicoApp/1.0',
        },
        body: jsonEncode(methodData),
      ).timeout(const Duration(seconds: 30));

      debugPrint('DEBUG: Response Status: ${response.statusCode}');
      debugPrint('DEBUG: Response Body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('DEBUG: Update Payment Method Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deletePaymentMethod(String methodId, String token) async {
    try {
      final url = _getUri('/api/payment/save-method/$methodId');
      debugPrint('DEBUG: Requesting Delete Payment Method -> $url');

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'KosmicoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('DEBUG: Response Status: ${response.statusCode}');
      debugPrint('DEBUG: Response Body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('DEBUG: Delete Payment Method Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getNotifications(String token, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        _getUri('/api/notifications?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> markNotificationRead(String notificationId, String token) async {
    try {
      final response = await http.put(
        _getUri('/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String notificationId, String token) async {
    try {
      // If notificationId is already a full URL (which seems to be happening), use it directly
      // otherwise construct the URI
      Uri uri;
      if (notificationId.startsWith('http')) {
        uri = Uri.parse(notificationId);
      } else {
        uri = _getUri('/api/notifications/$notificationId');
      }
      
      debugPrint('DEBUG: Requesting DELETE -> $uri');
      
      final response = await http.delete(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'KosmicoApp/1.0',
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('DEBUG: DELETE Status -> ${response.statusCode}');
      debugPrint('DEBUG: DELETE Body -> ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('DEBUG: DELETE Exception -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> clearAllNotifications(String token) async {
    try {
      final response = await http.delete(
        _getUri('/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getCoupons(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/coupons'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> applyCoupon({
    required String code,
    required double orderAmount,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/coupons/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': code,
          'orderAmount': orderAmount,
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> addToWishlist(String productId, String token) async {
    try {
      final response = await http.post(
        _getUri('/api/wishlist/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': productId,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> removeFromWishlist(String productId, String token) async {
    try {
      final response = await http.post(
        _getUri('/api/wishlist/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': productId,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getWishlist(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/wishlist'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> placeCodOrder({
    required double amount,
    required String addressId,
    required List<Map<String, dynamic>> items,
    required String token,
    String? couponCode,
    double? discountAmount,
    double? deliveryFee,
    double? gstCharge,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/payment/cod'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'deliveryAddressId': addressId,
          'items': items,
          if (couponCode != null) 'couponCode': couponCode,
          if (discountAmount != null) 'discountAmount': discountAmount,
          if (deliveryFee != null) 'deliveryFee': deliveryFee,
          if (gstCharge != null) 'gstCharge': gstCharge,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String addressId,
    required List<Map<String, dynamic>> items,
    required String token,
    String? couponCode,
    double? discountAmount,
    double? deliveryFee,
    double? gstCharge,
  }) async {
    try {
      final url = _getUri('/api/payment/razorpay/create');
      final body = jsonEncode({
        'amount': amount,
        'deliveryAddressId': addressId,
        'items': items,
        if (couponCode != null) 'couponCode': couponCode,
        if (discountAmount != null) 'discountAmount': discountAmount,
        if (deliveryFee != null) 'deliveryFee': deliveryFee,
        if (gstCharge != null) 'gstCharge': gstCharge,
      });
      
      debugPrint('API: Creating Razorpay Order at $url');
      debugPrint('API: Request Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      debugPrint('API: Razorpay Response Status: ${response.statusCode}');
      debugPrint('API: Razorpay Response Body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('API: Razorpay Order Creation Error: $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> cancelPendingRazorpayOrder({
    required String razorpayOrderId,
    required String token,
  }) async {
    try {
      final url = _getUri('/api/payment/razorpay/cancel-pending');
      final body = jsonEncode({
        'razorpay_order_id': razorpayOrderId,
      });

      debugPrint('API: Cancelling Pending Razorpay Order at $url');
      debugPrint('API: Request Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 20));

      debugPrint('API: Razorpay Cancellation Response Status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      debugPrint('API: Razorpay Cancellation Error: $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String paymentMethodId,
    required double totalPrice,
    required String token,
    String? couponCode,
    String? razorpayPaymentId,
  }) async {
    final body = {
      'items': items,
      'addressId': addressId,
      'paymentMethodId': paymentMethodId,
      'totalPrice': totalPrice,
    };
    if (couponCode != null) body['couponCode'] = couponCode;
    if (razorpayPaymentId != null) body['razorpayPaymentId'] = razorpayPaymentId;

    // List of potential endpoints to try
    final endpoints = [
      '/api/orders/place',
      '/api/orders',
      '/api/order/place',
      '/api/order',
      '/api/user/orders/place',
      '/api/orders/create',
      '/api/order/create',
      '/api/user/order/place',
      '/api/user/orders/create',
      '/api/user/order/create',
      '/api/orders/user/place',
      '/api/orders/user/create',
      '/api/v1/orders/place',
      '/api/v1/order/place',
      '/api/order/add',
      '/api/orders/add',
      '/api/order/checkout',
      '/api/orders/checkout',
      '/api/order/place-order',
      '/api/orders/place-order',
    ];

    for (String path in endpoints) {
      try {
        final url = _getUri(path);
        debugPrint('DEBUG: Attempting Place Order to $url');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));

        debugPrint('DEBUG: $path response: ${response.statusCode}');
        
        if (response.statusCode != 404) {
          debugPrint('DEBUG: Found working or erroring endpoint at $path (not 404)');
          return _processResponse(response);
        }
      } catch (e) {
        debugPrint('DEBUG: Error trying $path: $e');
      }
    }

    return {'success': false, 'message': 'Could not find order placement endpoint (404 on all attempts)'};
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/payment/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getUserOrders(String token, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        _getUri('/api/payment/myorders?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> trackOrder(String orderId, String token) async {
    try {
      final response = await http.get(
        _getUri('/api/order/track/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(String orderId, String token) async {
    try {
      final response = await http.post(
        _getUri('/api/order/cancel/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> returnOrder(String orderId, String reason, String token) async {
    try {
      final response = await http.post(
        _getUri('/api/order/return/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Refund Module (Paise wapas chahiye)
  static Future<Map<String, dynamic>> initiateRefund({
    required String orderId,
    required String reason,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/refund/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderId': orderId,
          'reason': reason,
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getMyRefunds(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/refund/my-refunds'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Return / Replacement Module (Product exchange karna hai)
  static Future<Map<String, dynamic>> initiateReplacement({
    required String orderId,
    required String reason,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/return/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderId': orderId,
          'reason': reason,
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getMyReturns(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/return/my-returns'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> estimateDelivery({
    required String deliveryPincode,
    required double weight,
    required String paymentMethod,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/shiprocket/estimate-delivery'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'deliveryPincode': deliveryPincode,
          'weight': weight,
          'paymentMethod': paymentMethod,
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> submitProductReview({
    required String productId,
    required double rating,
    String? comment,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/products/$productId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // GlucoRhythm Module
  static Future<Map<String, dynamic>> logGlucoseReading({
    required double level,
    required String timeOfDay,
    required String readingType,
    String? notes,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/gluco/reading'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'glucoseLevel': level,
          'timeOfDay': timeOfDay,
          'readingTime': DateTime.now().toIso8601String(),
          'readingType': readingType,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> logMeal({
    required String mealType,
    required double carbs,
    required String token,
  }) async {
    try {
      final response = await http.post(
        _getUri('/api/gluco/meal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mealType': mealType,
          'carbs': carbs,
          'logTime': DateTime.now().toIso8601String(),
          'status': 'Logged',
        }),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getGlucoDashboard(String token) async {
    try {
      final response = await http.get(
        _getUri('/api/gluco/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> removeProfilePicture(String token) async {
    try {
      final response = await http.delete(
        _getUri('/api/auth/remove-profile-picture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 12,
    String? category,
    String? search,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      String query = 'page=$page&limit=$limit';
      if (category != null && category != 'All') {
        query += '&category=${Uri.encodeComponent(category)}';
      }
      if (search != null && search.isNotEmpty) query += '&search=${Uri.encodeComponent(search)}';
      if (sortBy != null) query += '&sortBy=${Uri.encodeComponent(sortBy)}';
      if (minPrice != null) query += '&minPrice=$minPrice';
      if (maxPrice != null) query += '&maxPrice=$maxPrice';
      if (minRating != null) query += '&minRating=$minRating';

      final response = await http.get(
        _getUri('/api/products/user/list?$query'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'KosmicoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(
        _getUri('/api/categories/user/list'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'KosmicoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getLatestUpdate() async {
    try {
      final response = await http.get(_getUri('/api/system/updates/latest')).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<void> wakeUpServer() async {
    try {
      // Just a simple GET request to wake up the Render free tier server
      http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<bool> checkMaintenanceMode() async {
    try {
      final response = await http.get(_getUri('/api/system/status')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isMaintenanceMode'] == true;
      }
      return false;
    } catch (e) {
      // If server is unreachable, we treat it as maintenance/down
      if (e is SocketException) return true;
      return false;
    }
  }

  static Map<String, dynamic> _handleError(dynamic e) {
    if (e is SocketException) {
      return {
        'success': false, 
        'message': 'Server unreachable. Please check your internet or if the server is down.'
      };
    } else if (e is http.ClientException) {
      return {
        'success': false,
        'message': 'Network error. Please try again.'
      };
    } else if (e.toString().contains('TimeoutException')) {
      return {
        'success': false,
        'message': 'Server is taking longer than usual to start. We are waking it up! Please wait 10 seconds and try again.'
      };
    }
    return {'success': false, 'message': 'Connection error: $e'};
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      // Global Maintenance Check (Blocking all actions)
      if (response.statusCode == 503) {
        _redirectToMaintenance();
        return {'success': false, 'message': 'System Under Maintenance'};
      }

      final String body = response.body;
      final bool hasBody = body.isNotEmpty && body != 'undefined' && body != 'null';

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        final data = hasBody ? jsonDecode(body) : null;
        
        // Check if the response itself contains maintenance flag
        if (data is Map && data['isMaintenanceMode'] == true) {
          _redirectToMaintenance();
        }

        return {'success': true, 'data': data};
      } else {
        final data = hasBody ? jsonDecode(body) : null;
        return {
          'success': false, 
          'message': (data != null && data is Map && data['message'] != null) ? data['message'] : 'Something went wrong'
        };
      }
    } catch (e) {
      debugPrint('ApiService ProcessResponse Error: $e');
      return {
        'success': false, 
        'message': 'Server Error (${response.statusCode}).'
      };
    }
  }

  static void _redirectToMaintenance() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
        (route) => false, // Remove all previous routes to block back button
      );
    }
  }
}
