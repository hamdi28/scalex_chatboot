// lib/providers/export_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalex_chatbot/features/chat/data/models/message.dart';
import 'package:scalex_chatbot/features/chat/presentation/providers/chat_provider.dart';
import 'package:scalex_chatbot/services/export_data_service.dart';


// Provider for export functionality
final exportProvider = Provider<ExportService>((ref) {
  return ExportService();
});

// Provider for filtered messages by selected model
final filteredMessagesProvider = Provider.family<List<Message>, String>((ref, selectedModel) {
  final chatState = ref.watch(chatProvider);

  return chatState.messages.where((message) {
    // Include both user messages and AI responses from the selected model
    return message.isUser || message.aiModel == selectedModel;
  }).toList();
});

// Provider for export state
final exportStateProvider = StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier();
});

class ExportState {
  final bool isExporting;
  final String? exportPath;
  final String? error;

  const ExportState({
    this.isExporting = false,
    this.exportPath,
    this.error,
  });

  ExportState copyWith({
    bool? isExporting,
    String? exportPath,
    String? error,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      exportPath: exportPath ?? this.exportPath,
      error: error ?? this.error,
    );
  }
}

class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier() : super(const ExportState());

  void startExporting() {
    state = state.copyWith(isExporting: true, error: null);
  }

  void exportSuccess(String path) {
    state = state.copyWith(
      isExporting: false,
      exportPath: path,
      error: null,
    );
  }

  void exportError(String error) {
    state = state.copyWith(
      isExporting: false,
      exportPath: null,
      error: error,
    );
  }

  void reset() {
    state = const ExportState();
  }
}