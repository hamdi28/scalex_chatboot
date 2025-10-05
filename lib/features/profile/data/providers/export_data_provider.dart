import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalex_chatbot/features/chat/data/models/message.dart';
import 'package:scalex_chatbot/features/chat/presentation/providers/chat_provider.dart';
import 'package:scalex_chatbot/services/export_data_service.dart';

/// Provider for export functionality
final exportProvider = Provider<ExportService>((ref) => ExportService());

/// Provider for filtered messages by selected model
/// Returns all user messages and AI messages matching [selectedModel]
final filteredMessagesProvider =
Provider.family<List<Message>, String>((ref, selectedModel) {
  final chatState = ref.watch(chatProvider);
  return chatState.messages
      .where((message) => message.isUser || message.aiModel == selectedModel)
      .toList();
});

/// StateNotifierProvider to manage export state (exporting, success, error)
final exportStateProvider =
StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier();
});

/// Represents the export process state
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

/// StateNotifier for controlling export actions and state updates
class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier() : super(const ExportState());

  /// Marks the start of an export process
  void startExporting() {
    state = state.copyWith(isExporting: true, error: null);
  }

  /// Updates state on successful export
  void exportSuccess(String path) {
    state = state.copyWith(
      isExporting: false,
      exportPath: path,
      error: null,
    );
  }

  /// Updates state on export failure
  void exportError(String error) {
    state = state.copyWith(
      isExporting: false,
      exportPath: null,
      error: error,
    );
  }

  /// Resets state to initial values
  void reset() {
    state = const ExportState();
  }
}
