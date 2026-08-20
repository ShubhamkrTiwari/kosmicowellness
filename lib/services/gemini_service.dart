import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/keys.dart';

class GeminiResponse {
  final Map<String, dynamic>? data;
  final String? errorMessage;

  GeminiResponse({this.data, this.errorMessage});
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // MODELS AS OF AUGUST 2026 (Refined for maximum connectivity)
  final List<String> _models = [
    'gemini-1.5-flash',      // Most compatible & fast
    'gemini-1.5-pro',         // High intelligence
    'gemini-2.0-flash',       // Next gen (Stable in 2026)
    'gemini-1.0-pro',        // Ultra-stable Legacy
  ];

  Future<GeminiResponse> analyzeFoodImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      for (var model in _models) {
        for (var version in ['v2', 'v1beta', 'v1']) {
          try {
            final url = 'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$GEMINI_API_KEY';
            
            final response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "contents": [{
                  "parts": [
                    {"text": "You are a professional clinical nutritionist. Analyze this food plate with 100% accuracy. Do NOT use generic data. Identify exact Indian dishes (e.g., distinguish between Roti, Butter Roti, Paratha, etc.). Calculate precise nutritional values based on portion sizes visible. Return ONLY raw JSON: {name, carbs, netCarbs, gi, gl, spikeRisk, swap}"},
                    {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
                  ]
                }],
                "generationConfig": {"response_mime_type": "application/json"}
              }),
            ).timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) {
              final Map<String, dynamic> responseData = jsonDecode(response.body);
              final String? textResponse = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (textResponse != null) return GeminiResponse(data: jsonDecode(textResponse.trim()));
            }
          } catch (_) {}
        }
      }
      return GeminiResponse(errorMessage: 'AI Scanner currently unavailable.');
    } catch (e) {
      return GeminiResponse(errorMessage: 'Scanner Error: $e');
    }
  }

  Future<GeminiResponse> analyzeFoodByName(String foodName) async {
    try {
      final prompt = "As a nutritionist, provide nutritional data for '$foodName'. Return ONLY raw JSON: {name, carbs, netCarbs, gi, gl, spikeRisk, swap}";
      
      for (var model in _models) {
        for (var version in ['v2', 'v1beta', 'v1']) { // Added v2 for 2026 support
          try {
            final url = 'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$GEMINI_API_KEY';
            final response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"response_mime_type": "application/json"}
              }),
            ).timeout(const Duration(seconds: 15));

            if (response.statusCode == 200) {
              final Map<String, dynamic> responseData = jsonDecode(response.body);
              final String? text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (text != null) return GeminiResponse(data: jsonDecode(text.trim()));
            }
          } catch (_) {}
        }
      }
      return GeminiResponse(errorMessage: 'AI busy.');
    } catch (e) {
      return GeminiResponse(errorMessage: 'Error: $e');
    }
  }

  Future<GeminiResponse> getRecipes(String query) async {
    try {
      final String searchQuery = query.isEmpty ? "general diabetes-friendly recipes" : query;
      final prompt = """
      Generate 6 real, high-quality diabetes-friendly recipes for: "$searchQuery".
      
      RULES:
      1. MUST be scientifically accurate for low-GI diet.
      2. 'imageQuery' MUST be 2-3 dish-specific keywords.
      3. 'servingSize' MUST be specific.
      
      Return ONLY valid JSON:
      {
        "recipes": [
          {
            "name": "Recipe Name",
            "carbs": "Xg Carbs",
            "servingSize": "Portion",
            "imageQuery": "keywords",
            "protein": "Xg",
            "fiber": "Xg",
            "prep": "X min",
            "category": "Meal Type",
            "ingredients": ["item 1"],
            "steps": ["step 1"],
            "tips": "tip"
          }
        ]
      }
      """;

      for (var model in _models) {
        for (var version in ['v1beta', 'v1']) {
          try {
            final url = 'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$GEMINI_API_KEY';
            debugPrint('DEBUG: Trying Gemini -> $model ($version)');
            
            final response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                  "response_mime_type": "application/json"
                }
              }),
            ).timeout(const Duration(seconds: 30));

            if (response.statusCode == 200) {
              final Map<String, dynamic> responseData = jsonDecode(response.body);
              final String? text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
              
              if (text != null) {
                final Map<String, dynamic> rawData = jsonDecode(text.trim());
                final List recipes = rawData['recipes'] ?? [];
                for (var r in recipes) {
                  final String q = r['imageQuery'] ?? r['name'] ?? 'healthy food';
                  final String cleanQ = Uri.encodeComponent(q);
                  // Using a more reliable Unsplash URL format
                  r['image'] = 'https://source.unsplash.com/800x600/?food,$cleanQ';
                }
                return GeminiResponse(data: rawData);
              }
            } else {
              debugPrint('DEBUG: Gemini Failed (${response.statusCode}) -> ${response.body}');
            }
          } catch (e) {
            debugPrint('DEBUG: Gemini Exception ($model) -> $e');
          }
        }
      }
      return GeminiResponse(errorMessage: 'AI Models not responding. Please check your internet or API key.');
    } catch (e) {
      return GeminiResponse(errorMessage: 'Service Error: $e');
    }
  }
}
