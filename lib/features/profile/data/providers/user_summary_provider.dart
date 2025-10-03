import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalex_chatbot/features/profile/data/providers/ai_model_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
// Provider for user summary with selected AI model
final userSummaryProvider = FutureProvider.family<String, ({
List<String> messages,
AIModel model,
String language, // Added language parameter
})>((ref, params) async {
  final userMessages = params.messages;
  final selectedModel = params.model;
  final language = params.language;

  if (userMessages.isEmpty) {
    return language == 'ar'
        ? 'لا توجد محادثات متاحة حتى الآن.'
        : 'No chat history available yet.';
  }

  try {
    final aiService = ref.watch(aiServiceProvider);

    // Get summary using the selected AI model and language
    final summary = await aiService.getUserSummary(
      messages: userMessages,
      model: selectedModel,
      language: language, // Pass the language
    );

    return summary;
  } catch (e, st) {
    // Provide language-specific error messages
    final errorMessage = language == 'ar'
        ? 'فشل في إنشاء الملخص: $e'
        : 'Failed to generate summary: $e';

    // Forward error so Riverpod handles it properly
    throw Exception(errorMessage);
  }
});
