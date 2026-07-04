import 'package:flutter/material.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'Ayurvedic Hair Oil',
      'price': 499,
      'quantity': 1,
      'icon': '🌿',
    },
    {
      'name': 'Active Protein Powder',
      'price': 1299,
      'quantity': 1,
      'icon': '💪',
    },
  ];

  List<Map<String, dynamic>> get items => _items;

  void addItem(Map<String, dynamic> item) {
    // Standardize product name (handle both 'name' and 'items' keys)
    final String name = (item['name'] ?? item['items'] ?? 'Unknown Product').toString();
    
    // Standardize price
    int price = 0;
    if (item['price'] is int) {
      price = item['price'];
    } else if (item['price'] is String) {
      price = int.parse(item['price'].replaceAll('₹', '').replaceAll(',', '').trim());
    }

    final String icon = (item['icon'] ?? '🌿').toString();

    // Check if item already exists
    int index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      _items[index]['quantity']++;
    } else {
      _items.add({
        'name': name,
        'price': price,
        'quantity': 1,
        'icon': icon,
      });
    }
  }

  void removeItem(int index) {
    if (_items[index]['quantity'] > 1) {
      _items[index]['quantity']--;
    } else {
      _items.removeAt(index);
    }
  }

  void incrementItem(int index) {
    _items[index]['quantity']++;
  }

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }
}
