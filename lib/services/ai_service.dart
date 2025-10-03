import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scalex_chatbot/features/profile/data/providers/ai_model_provider.dart';

class AIService {
  final Dio _dio;

  AIService(this._dio) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => print('🌐 DIO: $object'),
    ));
  }

  Future<String> sendMessage({
    required String message,
    required String language,
    required AIModel model,
  }) async {
    print('\n🚀 ========== START SEND MESSAGE ==========');
    print('📤 Input parameters: message="$message", language=$language, model=$model');

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      final requestData = {
        'message': message,
        'model': model.name,
        'language': language
      };

      final stopwatch = Stopwatch()..start();
      final response = await _dio.post('$baseUrl/chat', data: requestData);
      stopwatch.stop();

      String result;
      if (response.data is String) {
        result = response.data;
      } else if (response.data is Map) {
        result = response.data['message'] ??
            response.data['response'] ??
            response.data['choices']?[0]?['message']?['content'] ??
            'No response from AI';
      } else {
        result = 'Unexpected response format: ${response.data.runtimeType}';
      }

      print('🎯 Final result: "$result"');
      return result;
    } on DioException catch (e) {
      return handleDioError(e);
    } catch (e) {
      print('🚨 Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    } finally {
      print('🔚 SendMessage execution completed\n');
    }
  }

// NEW: Get user summary with selected AI model and language
  Future<String> getUserSummary({
    required List<String> messages,
    required AIModel model,
    required String language, // Added language parameter
  }) async {
    print('\n🎯 ========== GENERATING USER SUMMARY ==========');
    print('📊 Messages count: ${messages.length}');
    print('🤖 Using model: ${model.name}');
    print('🌐 Language: $language');

    if (messages.isEmpty) {
      return language == 'ar'
          ? 'لا توجد رسائل لتحليلها.'
          : 'No messages to analyze.';
    }

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

      final requestData = {
        'messages': messages,
        'model': model.name, // Send the selected model
        'language': language, // Send the language
      };

      print('📤 Sending request to: $baseUrl/summary');

      final response = await _dio.post(
        '$baseUrl/summary',
        data: requestData,
      );

      print('📥 Response received: ${response.statusCode}');

      if (response.data is Map) {
        final summary = response.data['summary'] ??
            (language == 'ar' ? 'تعذر إنشاء الملخص.' : 'Unable to generate summary.');
        print('✅ Summary generated successfully');
        return summary;
      } else {
        print('⚠️ Unexpected response format');
        return language == 'ar'
            ? 'تعذر إنشاء الملخص في الوقت الحالي.'
            : 'Unable to generate summary at this time.';
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      final errorMessage = handleDioError(e);
      return language == 'ar'
          ? 'خطأ في إنشاء الملخص: $errorMessage'
          : 'Error generating summary: $errorMessage';
    } catch (e) {
      print('❌ Unexpected error: $e');
      return language == 'ar'
          ? 'فشل في إنشاء الملخص: $e'
          : 'Failed to generate summary: $e';
    } finally {
      print('🔚 Summary generation completed\n');
    }
  }

  Future<bool> testConnection() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      final response = await _dio.get(
        '$baseUrl/health',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      return true;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> translateText({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (fromLang == toLang) return text;

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      final response = await _dio.post(
        '$baseUrl/translate',
        data: {'text': text, 'from': fromLang, 'to': toLang},
      );
      return response.data['translated_text'] ?? response.data['translation'] ?? text;
    } catch (_) {
      return text;
    }
  }

  Future<List<dynamic>> getChatHistory(String email) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      final response = await _dio.get('$baseUrl/history/$email');
      if (response.data is Map && response.data['history'] is List) {
        return response.data['history'];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveChatMessage({
    required String email,
    required String userMessage,
    required String aiResponse,
    String language = 'en',
  }) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      await _dio.post('$baseUrl/history', data: {
        'email': email,
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'model': 'gemini', // Changed from 'deepseek' to 'gemini'
        'language': language,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
      final response = await _dio.get('$baseUrl/health');
      return response.data is Map ? response.data : {'status': 'unknown'};
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Cannot connect to server',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> getAvailableModels() async {
    return {
      'available_models': [
        {
          'id': 'gemini', // Replaced 'deepseek' with 'gemini'
          'name': 'Google Gemini (Free)',
          'status': 'available',
          'description': 'Free tier - 60 requests per minute'
        },
        {
          'id': 'groq',
          'name': 'Groq (Llama 3.1)',
          'status': 'available',
          'description': 'Fast and efficient AI model'
        },
        {
          'id': 'claude',
          'name': 'Claude AI',
          'status': 'available',
          'description': 'Thoughtful and detailed responses'
        }
      ],
      'default': 'gemini' // Changed default from 'deepseek' to 'gemini'
    };
  }

  String handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check if the server is running.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Check if server is running.';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return 'API key error. Please check your AI service configuration.'; // Updated to generic message
        }
        if (e.response?.statusCode == 429) {
          return 'Rate limit exceeded. Please try again later.';
        }
        if (e.response?.statusCode == 500) {
          return 'The server failed to fulfill an apparently valid request.';
        }
        return 'Server error (${e.response?.statusCode}): ${e.response?.data}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'Network error: ${e.message}';
    }
  }
}
