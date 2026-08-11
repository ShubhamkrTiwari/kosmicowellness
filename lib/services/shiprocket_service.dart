import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ShiprocketService {
  static const String baseUrl = 'https://apiv2.shiprocket.in/v1/external';
  
  // Credentials - IMPORTANT: Updated with your provided credentials
  static const String email = 'akshaykumar19262@gmail.com';
  static const String password = '@DpLgdQf9n^Dl6xHj1BtD0N4adb8YbW3';
  
  // Default Pickup Location Nickname (must match Shiprocket dashboard settings)
  static const String pickupLocation = 'Primary';
  
  // Default Pickup Pincode (Warehouse Location)
  static const String defaultPickupPincode = '110001'; // Default to Delhi/NCR area

  static String? _token;

  /// Authenticate with Shiprocket and get a JWT token
  static Future<String?> login() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        debugPrint('Shiprocket: Logged in successfully. Token length: ${_token?.length}');
        return _token;
      } else {
        debugPrint('Shiprocket Login Failed: Status ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Shiprocket Login Error: $e');
      return null;
    }
  }

  /// Check if a pincode is serviceable for delivery
  static Future<Map<String, dynamic>> checkServiceability({
    required String pickupPincode,
    required String deliveryPincode,
    required double weight, // in kg
    String courierId = '',
  }) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final queryParams = {
        'pickup_postcode': pickupPincode,
        'delivery_postcode': deliveryPincode,
        'weight': weight.toString(),
        'cod': '1', // Default to COD allowed check
      };

      final uri = Uri.parse('$baseUrl/courier/serviceability/').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Shiprocket Serviceability Status: ${response.statusCode}');
      debugPrint('Shiprocket Serviceability Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create a new Shiprocket order
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderDetails) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/create/adhoc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderDetails),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Track a shipment using AWB number
  static Future<Map<String, dynamic>> getTrackingDetails(String awbNumber) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courier/track/awb/$awbNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Assign AWB to a shipment
  static Future<Map<String, dynamic>> assignAwb({
    required int shipmentId,
    int? courierId,
  }) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courier/assign/awb'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shipment_id': shipmentId,
          if (courierId != null) 'courier_id': courierId,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Request pickup for shipments
  static Future<Map<String, dynamic>> generatePickup(List<int> shipmentIds) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courier/generate/pickup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'shipment_id': shipmentIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Generate manifest for shipments
  static Future<Map<String, dynamic>> generateManifest(List<int> shipmentIds) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manifests/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'shipment_id': shipmentIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get print URL for manifest
  static Future<Map<String, dynamic>> printManifest(List<int> orderIds) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manifests/print'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'order_ids': orderIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Generate label for shipments
  static Future<Map<String, dynamic>> generateLabel(List<int> shipmentIds) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courier/generate/label'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'shipment_id': shipmentIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get print URL for invoice
  static Future<Map<String, dynamic>> printInvoice(List<int> orderIds) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/print/invoice'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'order_ids': orderIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create a return order (reverse pickup)
  static Future<Map<String, dynamic>> createReturnOrder(Map<String, dynamic> returnDetails) async {
    final token = _token ?? await login();
    if (token == null) return {'success': false, 'message': 'Authentication failed'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/create/return'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(returnDetails),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
