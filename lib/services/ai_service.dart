import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {

  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> ask(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Groq error: ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('AIService.ask ERROR: $e\n$stack');
      rethrow;
    }
  }


  static String extractJsonArray(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']') + 1;
    if (start == -1 || end == 0) {
      throw Exception('No JSON array found in AI response. Raw: $raw');
    }
    return raw.substring(start, end);
  }


  static String extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}') + 1;
    if (start == -1 || end == 0) {
      throw Exception('No JSON object found in AI response. Raw: $raw');
    }
    return raw.substring(start, end);
  }

  static Future<List<dynamic>> askForJsonArray(String prompt) async {
    final raw = await ask(prompt);
    try {
      final cleaned = extractJsonArray(raw);
      return jsonDecode(cleaned) as List<dynamic>;
    } catch (e, stack) {
      debugPrint('AIService.askForJsonArray parse ERROR: $e\n$stack');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> askForJsonObject(String prompt) async {
    final raw = await ask(prompt);
    try {
      final cleaned = extractJsonObject(raw);
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e, stack) {
      debugPrint('AIService.askForJsonObject parse ERROR: $e\n$stack');
      rethrow;
    }
  }
}