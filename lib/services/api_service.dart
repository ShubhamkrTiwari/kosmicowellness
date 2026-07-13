import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {

  static const String baseUrl = 'http://3.7.180.215';
  
  static Future<Map<String, dynamic>> updateProfileWithImage({
    required String name,
    required String phoneNumber,
    XFile? imageFile,
    required String token,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/auth/profile');
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
      print('API Error: $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/register');
      print('DEBUG: Requesting Register -> $url');
      
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
      
      print('DEBUG: Response received. Status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      print('DEBUG: Register Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> login(String email) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');
      print('DEBUG: Requesting Login -> $url');
      
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
      
      print('DEBUG: Response received. Status: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      print('DEBUG: Login Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> verifySignup(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup-verify'),
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
        Uri.parse('$baseUrl/api/auth/login-verify'),
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
        Uri.parse('$baseUrl/api/auth/resend-otp'),
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
        Uri.parse('$baseUrl/api/address'),
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
        Uri.parse('$baseUrl/api/address'),
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
        Uri.parse('$baseUrl/api/address/$addressId'),
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
        Uri.parse('$baseUrl/api/address/set-default/$addressId'),
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
        Uri.parse('$baseUrl/api/address/$addressId'),
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
        Uri.parse('$baseUrl/api/payment/saved-methods'),
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
      final url = Uri.parse('$baseUrl/api/payment/save-method');
      print('DEBUG: Requesting Save Payment Method -> $url');
      print('DEBUG: Body -> ${jsonEncode(methodData)}');

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
      
      print('DEBUG: Response Status: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');
      
      return _processResponse(response);
    } catch (e) {
      print('DEBUG: Save Payment Method Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updatePaymentMethod(String methodId, Map<String, dynamic> methodData, String token) async {
    try {
      final url = Uri.parse('$baseUrl/api/payment/save-method/$methodId');
      print('DEBUG: Requesting Update Payment Method -> $url');
      print('DEBUG: Body -> ${jsonEncode(methodData)}');

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

      print('DEBUG: Response Status: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('DEBUG: Update Payment Method Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deletePaymentMethod(String methodId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/api/payment/save-method/$methodId');
      print('DEBUG: Requesting Delete Payment Method -> $url');

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'KosmicoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('DEBUG: Response Status: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('DEBUG: Delete Payment Method Error -> $e');
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String paymentMethodId,
    required double totalPrice,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/orders/place');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items,
          'addressId': addressId,
          'paymentMethodId': paymentMethodId,
          'totalPrice': totalPrice,
        }),
      );
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
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return {'success': true, 'data': data};
      } else {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return {
          'success': false, 
          'message': (data != null && data['message'] != null) ? data['message'] : 'Something went wrong'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'message': 'Server Error (${response.statusCode}).'
      };
    }
  }
}
