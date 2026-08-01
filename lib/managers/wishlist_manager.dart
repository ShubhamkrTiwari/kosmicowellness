import 'package:flutter/material.dart';

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void toggleWishlist(Map<String, dynamic> item) {
    final String name = (item['name'] ?? item['items'] ?? 'Unknown Product').toString();
    int index = _items.indexWhere((element) => element['name'] == name);
    
    if (index != -1) {
      _items.removeAt(index);
    } else {
      _items.add({
        'id': item['_id']?.toString() ?? item['id']?.toString() ?? '',
        'name': name,
        'price': item['price'] is int ? item['price'] : int.parse(item['price'].toString().replaceAll('₹', '').replaceAll(',', '').trim()),
        'icon': (item['icon'] ?? '🌿').toString(),
        'image': (item['image'] ?? '').toString(),
        'description': (item['description'] ?? '').toString(),
      });
    }
    notifyListeners();
  }

  bool isWishlisted(String name) {
    return _items.any((element) => element['name'] == name);
  }
}
