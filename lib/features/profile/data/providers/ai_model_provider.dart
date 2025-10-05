import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Model Enum
enum AIModel { claude, groq, gemini }  // Replaced deepseek with gemini

/// Extension for AI Model
extension AIModelExtension on AIModel {
  String get name {
    switch (this) {
      case AIModel.claude:
        return 'claude';
      case AIModel.groq:
        return 'groq';
      case AIModel.gemini:
        return 'gemini';
    }
  }

  ///Return the AI model Display name
  String get displayName {
    switch (this) {
      case AIModel.claude:
        return 'Claude AI';
      case AIModel.groq:
        return 'Groq (Llama 3.1)';
      case AIModel.gemini:
        return 'Gemini (Free)';
    }
  }

  ///Return the AI model description
  String get description {
    switch (this) {
      case AIModel.claude:
        return 'Anthropic Claude - Thoughtful and detailed';
      case AIModel.groq:
        return 'Groq - Fast and efficient';
      case AIModel.gemini:
        return 'Google Gemini - Free tier available';
    }
  }
}

/// AI Model State Notifier
class AIModelNotifier extends StateNotifier<AIModel> {
  AIModelNotifier() : super(AIModel.gemini); // Default model changed to gemini

  void setModel(AIModel model) {
    state = model;
  }

  AIModel getModel() {
    return state;
  }
}

/// Provider for AI Model
final aiModelProvider = StateNotifierProvider<AIModelNotifier, AIModel>((ref) {
  return AIModelNotifier();
});