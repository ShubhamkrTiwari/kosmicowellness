import 'package:flutter/material.dart';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + ((item['quantity'] ?? 0) as int));

  void addItem(Map<String, dynamic> item) {
    // Standardize product name (handle both 'name' and 'items' keys)
    final String name = (item['name'] ?? item['items'] ?? 'Unknown Product').toString();
    
    // Standardize price
    int price = 0;
    if (item['price'] is int) {
      price = item['price'];
    } else if (item['price'] is String) {
      price = int.parse(item['price'].toString().replaceAll('₹', '').replaceAll(',', '').trim());
    }

    final String icon = (item['icon'] ?? '🌿').toString();

    // Check if item already exists
    int index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 0) + 1;
    } else {
      _items.add({
        'name': name,
        'price': price,
        'quantity': 1,
        'icon': icon,
      });
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      if ((_items[index]['quantity'] ?? 0) > 1) {
        _items[index]['quantity'] = (_items[index]['quantity'] ?? 0) - 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void deleteItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void incrementItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 0) + 1;
      notifyListeners();
    }
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (((item['price'] ?? 0) as int) * ((item['quantity'] ?? 0) as int)));
  }

  int getProductQuantity(String name) {
    final index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      final q = _items[index]['quantity'];
      return q is int ? q : 0;
    }
    return 0;
  }
}
