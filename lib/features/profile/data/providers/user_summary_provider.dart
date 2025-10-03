import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalex_chatbot/features/profile/data/providers/ai_model_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
// Provider for user summary with selected AI model
final userSummaryProvider =
FutureProvider.family<String, (List<String>, AIModel)>((ref, params) async {
  final (userMessages, selectedModel) = params;

  if (userMessages.isEmpty) {
    return 'No chat history available yet.';
  }

  try {
    final aiService = ref.watch(aiServiceProvider);

    // Get summary using the selected AI model
    final summary = await aiService.getUserSummary(
      messages: userMessages,
      model: selectedModel,
    );

    return summary;
  } catch (e, st) {
    // Forward error so Riverpod handles it properly
    throw Exception('Failed to generate summary: $e\n$st');
  }
});
