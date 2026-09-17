import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/keys.dart';

class GeminiResponse {
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final bool isFallback;

  GeminiResponse({this.data, this.errorMessage, this.isFallback = false});
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  String _cachedOpenAiKey = '';

  Future<String> getOpenAiApiKey() async {
    if (_cachedOpenAiKey.isNotEmpty) return _cachedOpenAiKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_openai_api_key') ?? '';
      if (saved.isNotEmpty && saved.length > 10) {
        _cachedOpenAiKey = saved;
        return _cachedOpenAiKey;
      }
    } catch (_) {}
    return OPENAI_API_KEY;
  }

  Future<void> saveCustomOpenAiApiKey(String key) async {
    _cachedOpenAiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_openai_api_key', _cachedOpenAiKey);
    } catch (e) {
      debugPrint('Could not save OpenAI API key: $e');
    }
  }

  Future<bool> get isOpenAiKeyConfigured async {
    final key = await getOpenAiApiKey();
    return key.isNotEmpty && !key.contains('YOUR_') && key.length > 10;
  }

  // Backward compatibility alias methods so old callers don't error out
  Future<String> getApiKey() async => getOpenAiApiKey();
  Future<void> saveCustomApiKey(String key) async => saveCustomOpenAiApiKey(key);
  Future<bool> get isKeyConfigured async => isOpenAiKeyConfigured;
  Future<Map<String, dynamic>> testApiKey(String testKey) async => testOpenAiApiKey(testKey);

  /// Tests if an OpenAI API key is valid.
  Future<Map<String, dynamic>> testOpenAiApiKey(String testKey) async {
    final key = testKey.trim();
    if (key.isEmpty || key.length < 10) {
      return {'success': false, 'message': 'OpenAI API Key is too short or empty.'};
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "user", "content": "Hello"}
          ],
          "max_tokens": 5
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return {'success': true, 'model': 'gpt-4o-mini', 'message': 'OpenAI API Key verified successfully!'};
      } else {
        final body = response.body.toLowerCase();
        if (response.statusCode == 401 || body.contains('invalid_api_key')) {
          return {'success': false, 'message': 'Invalid OpenAI API Key or unauthorized.'};
        } else if (response.statusCode == 429 || body.contains('quota')) {
          return {'success': false, 'message': 'OpenAI API quota exceeded or rate limited.'};
        } else {
          return {'success': false, 'message': 'OpenAI Error (${response.statusCode}): ${response.reasonPhrase}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to OpenAI API: $e'};
    }
  }

  Map<String, dynamic>? _cleanAndParseJson(String rawText) {
    try {
      String cleaned = rawText.trim();
      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }
      final map = jsonDecode(cleaned) as Map<String, dynamic>;

      double parseNum(dynamic val, double fallback) {
        if (val == null) return fallback;
        if (val is num) return val.toDouble();
        final s = val.toString().replaceAll(RegExp(r'[^0-9.]'), '').trim();
        return double.tryParse(s) ?? fallback;
      }

      if (map['name'] == null || map['name'].toString().trim().isEmpty) {
        if (map['dishName'] != null) {
          map['name'] = map['dishName'].toString();
        } else if (map['foodName'] != null) {
          map['name'] = map['foodName'].toString();
        } else if (map['portion'] != null && map['portion'].toString().isNotEmpty) {
          final portionStr = map['portion'].toString();
          final cleanName = portionStr
              .replaceAll(RegExp(r'^[0-9.]+\s*(bowl|cup|cups|plate|serving|servings|g|grams|pieces?|of)\s*', caseSensitive: false), '')
              .replaceAll(RegExp(r'\([^)]*\)'), '')
              .trim();
          if (cleanName.isNotEmpty) {
            map['name'] = cleanName;
          }
        }
      }

      map['carbs'] = parseNum(map['carbs'], 35.0);
      map['fiber'] = parseNum(map['fiber'], 4.0);
      map['netCarbs'] = parseNum(map['netCarbs'], ((map['carbs'] as double) - (map['fiber'] as double)).clamp(0.0, 500.0));
      map['calories'] = parseNum(map['calories'], 250.0).round();
      map['protein'] = parseNum(map['protein'], 8.0);
      map['fat'] = parseNum(map['fat'], 6.0);
      map['confidence_score'] = map['confidence_score']?.toString() ?? 'High';
      map['assumptions_made'] = map['assumptions_made']?.toString() ?? 'Calculated using standard clinical preparation ratios.';

      return map;
    } catch (e) {
      debugPrint('JSON parse error: $e. Raw text was: $rawText');
      return null;
    }
  }

  /// Analyzes meal photo using OpenAI GPT-4o Vision API
  Future<GeminiResponse> analyzeFoodImage(
    dynamic imageInput, {
    Map<String, dynamic>? referenceDetails,
  }) async {
    return analyzeFoodImageWithOpenAi(imageInput, referenceDetails: referenceDetails);
  }

  Future<GeminiResponse> analyzeFoodImageWithOpenAi(
    dynamic imageInput, {
    Map<String, dynamic>? referenceDetails,
  }) async {
    final openAiKey = await getOpenAiApiKey();
    final bool validKey = openAiKey.isNotEmpty && !openAiKey.contains('YOUR_') && openAiKey.length > 10;

    if (!validKey) {
      return GeminiResponse(
        errorMessage: 'OpenAI API key is not configured. Please set your OpenAI API key in settings.',
        isFallback: true,
      );
    }

    try {
      Uint8List bytes;
      if (imageInput is Uint8List) {
        bytes = imageInput;
      } else if (imageInput is XFile) {
        bytes = await imageInput.readAsBytes();
      } else if (imageInput is File) {
        bytes = await imageInput.readAsBytes();
      } else {
        return GeminiResponse(errorMessage: 'Invalid image data', isFallback: true);
      }

      final base64Image = base64Encode(bytes);

      String userRefContext = '';
      if (referenceDetails != null && referenceDetails.isNotEmpty) {
        final filling = referenceDetails['filling'];
        final oilLevel = referenceDetails['oilLevel'];
        final sweetness = referenceDetails['sweetness'];
        final notes = referenceDetails['notes'];

        final sb = StringBuffer('\n\nCRITICAL USER REFERENCE DETAILS:\n');
        if (filling != null && filling.toString().trim().isNotEmpty && filling != 'Standard' && filling != 'None / Standard') {
          sb.writeln('- Base / Filling Type: $filling');
        }
        if (oilLevel != null && oilLevel.toString().trim().isNotEmpty) {
          sb.writeln('- Cooking Oil / Fat Level: $oilLevel');
        }
        if (sweetness != null && sweetness.toString().trim().isNotEmpty && sweetness != 'Sugar-Free / None') {
          sb.writeln('- Sugar / Sweetness: $sweetness');
        }
        if (notes != null && notes.toString().trim().isNotEmpty) {
          sb.writeln('- Custom Recipe / Hidden Ingredients: $notes');
        }
        userRefContext = sb.toString();
      }

      final promptText = """
You are a clinical dietitian and diabetologist specializing in Indian and International foods, diabetes carb counting, and glycemic control.

Analyze this food/meal photo and return ONLY a valid JSON object matching these exact keys:
- name: (String) Specific culinary name of the dish
- portion: (String) Realistic portion size visible
- ingredients: (List of Strings) Detected ingredients
- carbs: (float) Total carbs in grams
- fiber: (float) Dietary fiber in grams
- netCarbs: (float) Total carbs minus fiber
- protein: (float) Total protein in grams
- fat: (float) Total lipids/fat in grams
- calories: (int) Total energy in kcal
- gi: (String) Glycemic Index ('Low', 'Med', 'High')
- gl: (String) Glycemic Load ('Low', 'Med', 'High')
- spikeRisk: (String) 'Low', 'Med', 'High', or 'Very High'
- confidence_score: (String) 'High', 'Medium', or 'Low'
- assumptions_made: (String) Brief explanation of recipe assumptions
- swap: (String) Practical diabetic tip
- alternates: (List of Strings) 3 realistic alternative dishes
$userRefContext
""";

      final openAiModels = ['gpt-4o-mini', 'gpt-4o'];

      for (var model in openAiModels) {
        try {
          final response = await http.post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiKey',
            },
            body: jsonEncode({
              "model": model,
              "messages": [
                {
                  "role": "user",
                  "content": [
                    {"type": "text", "text": promptText},
                    {
                      "type": "image_url",
                      "image_url": {
                        "url": "data:image/jpeg;base64,$base64Image"
                      }
                    }
                  ]
                }
              ],
              "response_format": {"type": "json_object"},
              "max_tokens": 1000,
              "temperature": 0.1
            }),
          ).timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final String? textResponse = responseData['choices']?[0]?['message']?['content'];
            if (textResponse != null) {
              final parsed = _cleanAndParseJson(textResponse);
              if (parsed != null && (parsed['name'] != null || parsed['portion'] != null)) {
                return GeminiResponse(data: parsed, isFallback: false);
              }
            }
          } else {
            debugPrint('OpenAI API Error ($model) status: ${response.statusCode}, body: ${response.body}');
          }
        } catch (e) {
          debugPrint('OpenAI attempt failed ($model): $e');
        }
      }
      return GeminiResponse(errorMessage: 'OpenAI Vision model failed.', isFallback: true);
    } catch (e) {
      return GeminiResponse(errorMessage: 'OpenAI Error: $e', isFallback: true);
    }
  }

  Future<GeminiResponse> analyzeFoodByName(String foodName) async {
    final openAiKey = await getOpenAiApiKey();
    final bool validKey = openAiKey.isNotEmpty && !openAiKey.contains('YOUR_') && openAiKey.length > 10;

    if (!validKey) {
      return GeminiResponse(
        errorMessage: 'Using Smart Local Clinical Database.',
        isFallback: true,
      );
    }

    try {
      final prompt = "As a clinical dietitian, provide diabetic nutritional estimates for a standard serving of '$foodName'. "
                     "Return ONLY valid raw JSON with keys: "
                     "{\"name\": \"$foodName\", \"carbs\": 25.0, \"netCarbs\": 20.0, \"protein\": 8.0, \"fat\": 5.0, \"fiber\": 5.0, \"calories\": 200, \"portion\": \"1 serving\", \"gi\": \"Med\", \"gl\": \"Low\", \"spikeRisk\": \"Low\", \"swap\": \"Healthier alternative\"}";
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "response_format": {"type": "json_object"},
          "max_tokens": 500,
          "temperature": 0.2
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? text = responseData['choices']?[0]?['message']?['content'];
        if (text != null) {
          final parsed = _cleanAndParseJson(text);
          if (parsed != null) return GeminiResponse(data: parsed, isFallback: false);
        }
      }
      return GeminiResponse(errorMessage: 'AI busy. Using Smart Local Database.', isFallback: true);
    } catch (e) {
      return GeminiResponse(errorMessage: 'Error: $e. Using Smart Local Database.', isFallback: true);
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
      
      Return ONLY valid JSON with root key "recipes":
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

      final openAiKey = await getOpenAiApiKey();
      final bool validKey = openAiKey.isNotEmpty && !openAiKey.contains('YOUR_') && openAiKey.length > 10;

      if (!validKey) {
        return GeminiResponse(errorMessage: 'API Key not set. Using local recipe engine.', isFallback: true);
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "response_format": {"type": "json_object"},
          "max_tokens": 1500,
          "temperature": 0.2
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? text = responseData['choices']?[0]?['message']?['content'];
        
        if (text != null) {
          final Map<String, dynamic>? rawData = _cleanAndParseJson(text);
          if (rawData != null) {
            final List recipes = rawData['recipes'] ?? [];
            for (var r in recipes) {
              final String q = r['imageQuery'] ?? r['name'] ?? 'healthy food';
              final String cleanQ = Uri.encodeComponent(q);
              r['image'] = 'https://source.unsplash.com/800x600/?$cleanQ,food';
            }
            return GeminiResponse(data: rawData);
          }
        }
      }
      return GeminiResponse(errorMessage: 'AI Models not responding.', isFallback: true);
    } catch (e) {
      return GeminiResponse(errorMessage: 'Service Error: $e', isFallback: true);
    }
  }
}
