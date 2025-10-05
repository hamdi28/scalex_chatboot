import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:scalex_chatbot/features/profile/data/providers/ai_model_provider.dart';
import '../../data/models/message.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/database_service.dart';

// Providers

/// Provides a singleton instance of [DatabaseService] for Hive operations.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provides a singleton instance of [AIService] with Dio configured.
final aiServiceProvider = Provider<AIService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  return AIService(dio);
});

/// Provides the [ChatNotifier] to manage chat state.
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(aiServiceProvider),
    ref.watch(databaseServiceProvider),
  );
});

/// Represents the state of the chat, including messages, loading status, errors, and selected AI model.
class ChatState {
  /// List of all chat messages.
  final List<Message> messages;

  /// True if waiting for an AI response.
  final bool isLoading;

  /// Stores the last error message (if any).
  final String? error;

  /// Currently selected AI model.
  final AIModel selectedModel;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.selectedModel = AIModel.claude,
  });

  /// Returns a new [ChatState] with updated fields.
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

/// Handles chat logic: sending messages, receiving AI responses, and managing chat history.
class ChatNotifier extends StateNotifier<ChatState> {
  final AIService _aiService;
  final DatabaseService _databaseService;

  /// Initializes the [ChatNotifier] and loads existing messages.
  ChatNotifier(this._aiService, this._databaseService) : super(ChatState()) {
    _loadMessages();
  }

  /// Loads all messages from the local database into state.
  Future<void> _loadMessages() async {
    final messages = await _databaseService.getAllMessages();
    state = state.copyWith(messages: messages);
  }

  /// Updates the selected AI model and saves it to local settings.
  void setSelectedModel(AIModel model) {
    state = state.copyWith(selectedModel: model);
    _databaseService.saveSelectedModel(model.toString().split('.').last);
  }

  /// Sends a user message to the AI and handles the response.
  Future<void> sendMessage(String content, String language) async {
    if (content.trim().isEmpty) return;

    // Create user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      aiModel: state.selectedModel.name,
      timestamp: DateTime.now(),
    );

    await _databaseService.saveMessage(userMessage);

    // Update state with new user message and loading flag
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

      // Create AI message
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        aiModel: state.selectedModel.toString().split('.').last,
      );

      await _databaseService.saveMessage(aiMessage);

      // Update state with AI response
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      // Update state with error
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

  /// Clears all chat history.
  Future<void> clearHistory() async {
    await _databaseService.clearHistory();
    state = state.copyWith(messages: []);
  }

  /// Deletes a specific message by [messageId].
  Future<void> deleteMessage(String messageId) async {
    await _databaseService.deleteMessage(messageId);
    state = state.copyWith(
      messages: state.messages.where((msg) => msg.id != messageId).toList(),
    );
  }
}
