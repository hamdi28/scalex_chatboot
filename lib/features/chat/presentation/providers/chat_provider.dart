import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:scalex_chatbot/features/profile/data/providers/ai_model_provider.dart';
import '../../data/models/message.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/database_service.dart';

// Providers
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final aiServiceProvider = Provider<AIService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  return AIService(dio);
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(aiServiceProvider),
    ref.watch(databaseServiceProvider),
  );
});

// Chat State
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final AIModel selectedModel;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.selectedModel = AIModel.claude,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    AIModel? selectedModel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}

// Chat Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final AIService _aiService;
  final DatabaseService _databaseService;

  ChatNotifier(this._aiService, this._databaseService) : super(ChatState()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await _databaseService.getAllMessages();
    state = state.copyWith(messages: messages);
  }

  void setSelectedModel(AIModel model) {
    state = state.copyWith(selectedModel: model);
    _databaseService.saveSelectedModel(model.toString().split('.').last);
  }

  Future<void> sendMessage(String content, String language) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      aiModel: state.selectedModel.name,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(userMessage);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Get AI response
      final aiResponse = await _aiService.sendMessage(
        message: content,
        model: state.selectedModel,
        language: language,
      );

      // Add AI message
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        aiModel: state.selectedModel.toString().split('.').last,
      );

      await _databaseService.saveMessage(aiMessage);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      // Add error message to chat
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        aiModel: 'error',
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
      );
    }
  }

  Future<void> clearHistory() async {
    await _databaseService.clearHistory();
    state = state.copyWith(messages: []);
  }

  Future<void> deleteMessage(String messageId) async {
    await _databaseService.deleteMessage(messageId);
    state = state.copyWith(
      messages: state.messages.where((msg) => msg.id != messageId).toList(),
    );
  }
}