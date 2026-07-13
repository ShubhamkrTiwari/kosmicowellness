import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_manager.dart';

class PaymentManager extends ChangeNotifier {
  static final PaymentManager _instance = PaymentManager._internal();
  factory PaymentManager() => _instance;
  PaymentManager._internal();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  final List<Map<String, dynamic>> _paymentMethods = [];

  List<Map<String, dynamic>> get paymentMethods => List.unmodifiable(_paymentMethods);

  Future<void> fetchPaymentMethods() async {
    final token = UserManager().token;
    if (token == null) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await ApiService.getPaymentMethods(token);
      print('DEBUG: Fetch Payment Methods Response -> $response');
      
      if (response['success'] == true) {
        final dynamic data = response['data'];
        List<Map<String, dynamic>> fetchedList = [];
        
        if (data is Map && data['savedPaymentMethods'] is List) {
          fetchedList = List<Map<String, dynamic>>.from(data['savedPaymentMethods']);
        } else if (data is List) {
          fetchedList = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          final list = data['methods'] ?? data['data'] ?? data['paymentMethods'];
          if (list is List) {
            fetchedList = List<Map<String, dynamic>>.from(list);
          }
        }
        
        _paymentMethods.clear();
        _paymentMethods.addAll(fetchedList);
      } else {
        // If it's a 404, we don't treat it as a visible error to the user
        // but we also don't clear the list if it already has data from a POST response
        if (response['message']?.contains('404') != true) {
          _lastError = response['message'];
        }
      }
    } catch (e) {
      print('DEBUG: Manager Fetch Error -> $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePaymentMethod(Map<String, dynamic> method) async {
    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final token = UserManager().token;
      if (token == null) {
        _lastError = "Authentication token missing. Please login again.";
        return false;
      }

      final response = await ApiService.savePaymentMethod(method, token);
      
      if (response['success'] == true) {
        final data = response['data'];
        
        // IMPORTANT: Use the list returned by the POST request since GET is 404
        if (data != null && data['savedPaymentMethods'] is List) {
          _paymentMethods.clear();
          _paymentMethods.addAll(List<Map<String, dynamic>>.from(data['savedPaymentMethods']));
          print('DEBUG: Updated list from POST response. Count: ${_paymentMethods.length}');
        } else {
          // Fallback: manually add if list not returned
          if (method['isDefault'] == true) _resetDefaults();
          _paymentMethods.add(Map<String, dynamic>.from(data ?? method));
        }
        
        notifyListeners();
        return true;
      } else {
        _lastError = response['message'] ?? "Failed to save payment details.";
        return false;
      }
    } catch (e) {
      print('DEBUG: Manager Save Error -> $e');
      _lastError = "Connection error: $e";
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updatePaymentMethodById(String id, Map<String, dynamic> method) async {
    if (id == "null" || id.isEmpty) {
      _lastError = "Invalid Payment Method ID";
      return false;
    }

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final token = UserManager().token;
      if (token == null) return false;

      final response = await ApiService.updatePaymentMethod(id, method, token);
      
      if (response['success'] == true) {
        // Try to update from response list if available
        final data = response['data'];
        if (data != null && data['savedPaymentMethods'] is List) {
          _paymentMethods.clear();
          _paymentMethods.addAll(List<Map<String, dynamic>>.from(data['savedPaymentMethods']));
        } else {
          // Manual update
          final index = _paymentMethods.indexWhere((m) => m['_id'].toString() == id || m['id'].toString() == id);
          if (index != -1) {
            if (method['isDefault'] == true) _resetDefaults();
            _paymentMethods[index] = Map<String, dynamic>.from(data ?? method);
          }
        }
        notifyListeners();
        return true;
      } else {
        _lastError = response['message'];
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deletePaymentMethodById(String id) async {
    if (id == "null" || id.isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final token = UserManager().token;
      if (token == null) return false;

      final response = await ApiService.deletePaymentMethod(id, token);
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data != null && data['savedPaymentMethods'] is List) {
          _paymentMethods.clear();
          _paymentMethods.addAll(List<Map<String, dynamic>>.from(data['savedPaymentMethods']));
        } else {
          _paymentMethods.removeWhere((m) => m['_id'].toString() == id || m['id'].toString() == id);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void removePaymentMethod(int index) {
    if (index >= 0 && index < _paymentMethods.length) {
      final method = _paymentMethods[index];
      final id = method['_id'] ?? method['id'];
      if (id != null) {
        deletePaymentMethodById(id.toString());
      } else {
        _paymentMethods.removeAt(index);
        notifyListeners();
      }
    }
  }

  void updatePaymentMethod(int index, Map<String, dynamic> method) {
    if (index >= 0 && index < _paymentMethods.length) {
      final existingMethod = _paymentMethods[index];
      final id = existingMethod['_id'] ?? existingMethod['id'];
      if (id != null) {
        updatePaymentMethodById(id.toString(), method);
      }
    }
  }

  void _resetDefaults() {
    for (int i = 0; i < _paymentMethods.length; i++) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(_paymentMethods[i]);
      m['isDefault'] = false;
      _paymentMethods[i] = m;
    }
  }

  Future<void> init() async {
    await fetchPaymentMethods();
  }
}
