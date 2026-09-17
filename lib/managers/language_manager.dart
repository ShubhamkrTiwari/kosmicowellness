import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager with ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  String _currentLanguage = 'en'; // 'en' for English, 'hi' for Hindi
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  String translate(String key) {
    final translation = _translations[_currentLanguage]?[key];
    return translation ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Kosmico Wellness',
      'home': 'Home',
      'products': 'Products',
      'care': 'Care',
      'profile': 'Profile',
      'bestsellers': 'Our Bestsellers',
      'categories': 'Categories',
      'view_all': 'View All',
      'search_hint': 'Search ayurvedic products...',
      'wellness_journey': 'Wellness Journey',
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi (हिंदी)',
      'logout': 'Logout',
      'dark_mode': 'Dark Mode',
      'help_center': 'Help Center',
      'my_orders': 'My Orders',
      'wishlist': 'Wishlist',
      'coupons': 'Coupons',
      'settings': 'Account Settings',
      'support': 'Support & Preferences',
      'about_kosmico': 'About Kosmico',
      'edit_profile': 'Edit Profile',
      'add_to_cart': 'Add',
      'product_specifications': 'Product Specifications',
      'wellness_catalog': 'Wellness Catalog',
      'ayurvedic_essentials': 'Handpicked Ayurvedic Essentials',
      'search_products': 'Search products...',
      'no_products': 'No products found',
      'added_to_cart': 'Added to cart',
      'view': 'View',
      'ayurvedic_story': 'The Ayurvedic Story',
      'ingredients': 'Ingredients',
      'key_benefits': 'Key Benefits',
      'product_highlights': 'Product Highlights',
      'quantity': 'Quantity',
      'buy_now': 'Buy Now',
      'out_of_stock': 'Out of Stock',
      'organic': 'Organic',
      'lab_tested': 'Lab Tested',
      'handmade': 'Handmade',
      'authentic': 'Authentic',
      'brand': 'Brand',
      'stock_status': 'Stock Status',
      'in_stock': 'In Stock',
      'shelf_life': 'Shelf Life',
      'made_in': 'Made In',
      'supplements': 'Supplements',
      'wellness': 'Wellness',
      'personal_care': 'Personal Care',
      'oils': 'Oils',
      'syrups': 'Syrups',
      'tablets': 'Tablets',
    },
    'hi': {
      'app_title': 'कॉस्मिको वेलनेस',
      'home': 'होम',
      'products': 'उत्पाद',
      'care': 'केयर',
      'profile': 'प्रोफ़ाइल',
      'bestsellers': 'हमारे बेस्टसेलर',
      'categories': 'श्रेणियाँ',
      'view_all': 'सभी देखें',
      'search_hint': 'आयुर्वेदिक उत्पाद खोजें...',
      'wellness_journey': 'वेलनेस यात्रा',
      'language': 'भाषा',
      'english': 'अंग्रेज़ी (English)',
      'hindi': 'हिंदी',
      'logout': 'लॉगआउट',
      'dark_mode': 'डार्क मोड',
      'help_center': 'हेल्प सेंटर',
      'my_orders': 'मेरे ऑर्डर',
      'wishlist': 'विशलिस्ट',
      'coupons': 'कूपन',
      'settings': 'खाता सेटिंग',
      'support': 'सहायता और प्राथमिकताएं',
      'about_kosmico': 'कॉस्मिको के बारे में',
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      'add_to_cart': 'जोड़ें',
      'product_specifications': 'उत्पाद विवरण',
      'wellness_catalog': 'वेलनेस कैटलॉग',
      'ayurvedic_essentials': 'चुनिंदा आयुर्वेदिक उत्पाद',
      'search_products': 'उत्पाद खोजें...',
      'no_products': 'कोई उत्पाद नहीं मिला',
      'added_to_cart': 'कार्ट में जोड़ा गया',
      'view': 'देखें',
      'ayurvedic_story': 'आयुर्वेदिक कहानी',
      'ingredients': 'सामग्री',
      'key_benefits': 'प्रमुख लाभ',
      'product_highlights': 'उत्पाद की विशेषताएं',
      'quantity': 'मात्रा',
      'buy_now': 'अभी खरीदें',
      'out_of_stock': 'स्टॉक में नहीं है',
      'organic': 'ऑर्गेनिक',
      'lab_tested': 'लैब टेस्टेड',
      'handmade': 'हैंडमेड',
      'authentic': 'प्रामाणिक',
      'brand': 'ब्रांड',
      'stock_status': 'स्टॉक स्थिति',
      'in_stock': 'स्टॉक में है',
      'shelf_life': 'शेल्फ लाइफ',
      'made_in': 'निर्मित',
      'supplements': 'सप्लीमेंट्स',
      'wellness': 'वेलनेस',
      'personal_care': 'पर्सनल केयर',
      'oils': 'तेल',
      'syrups': 'सिरप',
      'tablets': 'गोलियां',
    }
  };
}
