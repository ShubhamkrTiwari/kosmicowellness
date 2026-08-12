import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://3.7.180.215:5000';

Future<void> main() async {
  print('--- 1. Calling ApiService.getCategories() ---');
  final categoriesResponse = await http.get(
    Uri.parse('$baseUrl/api/categories/user/list'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );
  
  if (categoriesResponse.statusCode == 200) {
    final decoded = jsonDecode(categoriesResponse.body);
    final categories = (decoded is List) ? decoded : (decoded['data'] ?? []);
    print('Categories: ${categories.map((c) => "'${c['name']}' (len: ${c['name'].toString().length})").toList()}');
  } else {
    print('Error fetching categories: ${categoriesResponse.statusCode}');
  }

  print('\n--- 2. Calling ApiService.getProducts(limit: 50) ---');
  final productsResponse = await http.get(
    Uri.parse('$baseUrl/api/products/user/list?page=1&limit=50'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );

  if (productsResponse.statusCode == 200) {
    final decoded = jsonDecode(productsResponse.body);
    List products;
    if (decoded is List) {
      products = decoded;
    } else if (decoded is Map && decoded['data'] != null) {
      products = decoded['data'];
    } else {
      products = [];
    }
    
    print('Product Count: ${products.length}');
    if (products.isNotEmpty) {
      print('First product raw: ${products[0]}');
    }
    for (var p in products) {
      print('Name: ${p['name']}, Category: ${p['category']}');
    }
  } else {
    print('Error fetching products: ${productsResponse.statusCode}');
  }

  print('\n--- 3. Calling ApiService.getProducts(category: "Hair Care") ---');
  final hairCareResponse = await http.get(
    Uri.parse('$baseUrl/api/products/user/list?page=1&limit=50&category=${Uri.encodeComponent('Hair Care')}'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );

  if (hairCareResponse.statusCode == 200) {
    final decoded = jsonDecode(hairCareResponse.body);
    List products = (decoded is List) ? decoded : (decoded['data'] ?? []);
    print('Count for "Hair Care": ${products.length}');
  } else {
    print('Error fetching "Hair Care": ${hairCareResponse.statusCode}');
  }

  print('\n--- 4. Calling ApiService.getProducts(category: "hair care") ---');
  final hairCareLowerResponse = await http.get(
    Uri.parse('$baseUrl/api/products/user/list?page=1&limit=50&category=${Uri.encodeComponent('hair care')}'),
    headers: {'Accept': 'application/json', 'User-Agent': 'KosmicoApp/1.0'},
  );

  if (hairCareLowerResponse.statusCode == 200) {
    final decoded = jsonDecode(hairCareLowerResponse.body);
    List products = (decoded is List) ? decoded : (decoded['data'] ?? []);
    print('Count for "hair care": ${products.length}');
  } else {
    print('Error fetching "hair care": ${hairCareLowerResponse.statusCode}');
  }
}
