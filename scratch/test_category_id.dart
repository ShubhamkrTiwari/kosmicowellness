import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://3.7.180.215:5000';

Future<void> main() async {
  print('--- 1. Fetching Categories ---');
  final catResponse = await http.get(
    Uri.parse('$baseUrl/api/categories/user/list'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );
  
  if (catResponse.statusCode != 200) {
    print('Error fetching categories: ${catResponse.statusCode}');
    return;
  }
  
  final decodedCat = jsonDecode(catResponse.body);
  final List categories = (decodedCat is List) ? decodedCat : (decodedCat['data'] ?? []);
  
  if (categories.isEmpty) {
    print('No categories found.');
    return;
  }

  print('Available Categories:');
  for (var c in categories) {
    print('  - ${c['name']} (${c['_id']})');
  }
  
  // Find a category that actually has products by name first, then test ID vs Name
  var targetCategory;
  for (var c in categories) {
    final name = c['name'];
    final resp = await http.get(
      Uri.parse('$baseUrl/api/products/user/list?page=1&limit=5&category=${Uri.encodeComponent(name)}'),
      headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      final List products = (decoded is List) ? decoded : (decoded['data'] ?? []);
      if (products.isNotEmpty) {
        targetCategory = c;
        print('Found category with products: ${c['name']} (Count: ${products.length})');
        break;
      }
    }
  }

  if (targetCategory == null) {
    print('No category found with products by name. Checking by ID...');
    for (var c in categories) {
      final id = c['_id'];
      final resp = await http.get(
        Uri.parse('$baseUrl/api/products/user/list?page=1&limit=5&category=$id'),
        headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List products = (decoded is List) ? decoded : (decoded['data'] ?? []);
        if (products.isNotEmpty) {
          targetCategory = c;
          print('Found category with products by ID: ${c['name']} (ID: $id, Count: ${products.length})');
          break;
        }
      }
    }
  }

  if (targetCategory == null) {
    print('No products found for any category.');
    return;
  }
  
  final String categoryId = targetCategory['_id'];
  final String categoryName = targetCategory['name'];
  
  print('\nTesting Category: "$categoryName" (ID: $categoryId)');

  print('\n--- 2. Calling getProducts with ID ($categoryId) ---');
  final idResponse = await http.get(
    Uri.parse('$baseUrl/api/products/user/list?page=1&limit=50&category=$categoryId'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );

  int countById = 0;
  if (idResponse.statusCode == 200) {
    final decoded = jsonDecode(idResponse.body);
    final List products = (decoded is List) ? decoded : (decoded['data'] ?? []);
    countById = products.length;
    print('Products returned with ID: $countById');
  } else {
    print('Error with ID-based call: ${idResponse.statusCode}');
  }

  print('\n--- 3. Calling getProducts with Name ("$categoryName") ---');
  final nameResponse = await http.get(
    Uri.parse('$baseUrl/api/products/user/list?page=1&limit=50&category=${Uri.encodeComponent(categoryName)}'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );

  int countByName = 0;
  if (nameResponse.statusCode == 200) {
    final decoded = jsonDecode(nameResponse.body);
    final List products = (decoded is List) ? decoded : (decoded['data'] ?? []);
    countByName = products.length;
    print('Products returned with Name: $countByName');
  } else {
    print('Error with Name-based call: ${nameResponse.statusCode}');
  }

  print('\n--- Comparison ---');
  if (countById > 0 && countByName == 0) {
    print('REPORT: The ID-based call returns products while the name-based call returns zero.');
  } else if (countById == 0 && countByName > 0) {
    print('REPORT: The name-based call returns products while the ID-based call returns zero.');
  } else if (countById > 0 && countByName > 0) {
    print('REPORT: Both calls return products.');
    print('  ID count: $countById');
    print('  Name count: $countByName');
  } else {
    print('REPORT: Neither call returned products.');
  }
}
