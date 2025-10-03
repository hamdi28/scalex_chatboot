import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// AI Model Enum
enum AIModel { claude, deepseek, groq }  // Replaced grok with deepseek

// Extension for AI Model
extension AIModelExtension on AIModel {
  String get name {
    switch (this) {
      case AIModel.claude:
        return 'claude';
      case AIModel.deepseek:  // Replaced grok
        return 'deepseek';
      case AIModel.groq:
        return 'groq';
    }
  }

  String get displayName {
    switch (this) {
      case AIModel.claude:
        return 'Claude AI';
      case AIModel.deepseek:  // Replaced grok
        return 'DeepSeek (Free)';
      case AIModel.groq:
        return 'Groq (Llama 3.1)';
    }
  }

  String get description {
    switch (this) {
      case AIModel.claude:
        return 'Anthropic Claude - Thoughtful and detailed';
      case AIModel.deepseek:  // Replaced grok
        return 'DeepSeek - Completely free with 128K context';
      case AIModel.groq:
        return 'Groq - Fast and efficient';
    }
  }
}

// AI Model State Notifier
class AIModelNotifier extends StateNotifier<AIModel> {
  AIModelNotifier() : super(AIModel.deepseek); // Default model changed to deepseek

  void setModel(AIModel model) {
    state = model;
  }

  AIModel getModel() {
    return state;
  }
}

// Provider for AI Model
final aiModelProvider = StateNotifierProvider<AIModelNotifier, AIModel>((ref) {
  return AIModelNotifier();
});