import 'package:flutter/material.dart';
import 'notification_manager.dart';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + ((item['quantity'] ?? 0) as int));

  void addItem(Map<String, dynamic> item, {int qtyToAdd = 1}) {
    // Standardize product name (handle both 'name' and 'items' keys)
    final String name = (item['name'] ?? item['items'] ?? 'Unknown Product').toString();
    final String id = (item['_id'] ?? item['id'] ?? '').toString();
    
    if (id.isEmpty) {
      debugPrint('WARNING: Adding item to cart without a valid ID: $name');
    }

    // Standardize price
    int price = 0;
    if (item['price'] is int) {
      price = item['price'];
    } else if (item['price'] is String) {
      price = int.parse(item['price'].toString().replaceAll('₹', '').replaceAll(',', '').trim());
    }

    final String icon = (item['icon'] ?? '🌿').toString();
    final String image = (item['image'] ?? '').toString();

    // Stock handling
    final dynamic stockRaw = item['countInStock'] ?? item['stock'] ?? item['inventory'] ?? item['quantity'] ?? item['qty'];
    final int availableStock = stockRaw != null ? (int.tryParse(stockRaw.toString()) ?? 999) : 999;

    // Check if item already exists
    int index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      final int currentQty = (_items[index]['quantity'] ?? 0) as int;
      if (currentQty + qtyToAdd <= availableStock) {
        _items[index]['quantity'] = currentQty + qtyToAdd;
      } else {
        _items[index]['quantity'] = availableStock;
      }
    } else {
      _items.add({
        'id': id,
        'name': name,
        'price': price,
        'quantity': qtyToAdd > availableStock ? availableStock : qtyToAdd,
        'icon': icon,
        'image': image,
        'stock': availableStock, // Save for cart screen checks
      });
    }

    notifyListeners();
  }

  bool canAddMore(Map<String, dynamic> item, int qtyRequested) {
    final String name = (item['name'] ?? item['items'] ?? '').toString();
    final dynamic stockRaw = item['countInStock'] ?? item['stock'] ?? item['inventory'] ?? item['quantity'] ?? item['qty'];
    final int availableStock = stockRaw != null ? (int.tryParse(stockRaw.toString()) ?? 999) : 999;

    int inCart = 0;
    int index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      inCart = (_items[index]['quantity'] ?? 0) as int;
    }

    return (inCart + qtyRequested) <= availableStock;
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
      final int availableStock = (_items[index]['stock'] ?? 999) as int;
      final int currentQty = (_items[index]['quantity'] ?? 0) as int;
      
      if (currentQty < availableStock) {
        _items[index]['quantity'] = currentQty + 1;
        notifyListeners();
      }
    }
  }

  void incrementItemByName(String name) {
    final index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      incrementItem(index);
    }
  }

  void decrementItemByName(String name) {
    final index = _items.indexWhere((element) => element['name'] == name);
    if (index != -1) {
      removeItem(index);
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

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
