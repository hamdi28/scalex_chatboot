import 'package:hive/hive.dart';
import '../features/chat/data/models/message.dart';

/// Service class for handling local database operations using Hive.
class DatabaseService {
  static const String _messagesBox = 'messages';
  static const String _settingsBox = 'settings';

  /// Initializes the Hive boxes for messages and settings.
  Future<void> init() async {
    await Hive.openBox<Message>(_messagesBox);
    await Hive.openBox(_settingsBox);
  }

  /// Returns the Hive box containing messages.
  Box<Message> get messagesBox => Hive.box<Message>(_messagesBox);

  /// Returns the Hive box containing settings.
  Box get settingsBox => Hive.box(_settingsBox);

  /// Saves a new [message] to the messages box.
  Future<void> saveMessage(Message message) async {
    await messagesBox.add(message);
  }

  /// Returns all messages stored in the messages box.
  Future<List<Message>> getAllMessages() async {
    return messagesBox.values.toList();
  }

  /// Returns all messages for the specified [userId].
  Future<List<Message>> getMessagesByUser(String userId) async {
    return messagesBox.values
        .where((message) => message.userId == userId)
        .toList();
  }

  /// Clears all messages from the messages box.
  Future<void> clearHistory() async {
    await messagesBox.clear();
  }

  /// Deletes a specific message by its [messageId].
  Future<void> deleteMessage(String messageId) async {
    final message = messagesBox.values.firstWhere(
          (msg) => msg.id == messageId,
    );
    await message.delete();
  }

  /// Saves the preferred language code in settings.
  Future<void> saveLanguage(String languageCode) async {
    await settingsBox.put('language', languageCode);
  }

  /// Returns the saved language code from settings, if any.
  String? getLanguage() {
    return settingsBox.get('language');
  }

  /// Saves the selected AI model in settings.
  Future<void> saveSelectedModel(String model) async {
    await settingsBox.put('selected_model', model);
  }

  /// Returns the selected AI model from settings, if any.
  String? getSelectedModel() {
    return settingsBox.get('selected_model');
  }

  /// Saves the dark mode preference in settings.
  Future<void> saveDarkMode(bool isDark) async {
    await settingsBox.put('dark_mode', isDark);
  }

  /// Returns the dark mode preference from settings, if any.
  bool? getDarkMode() {
    return settingsBox.get('dark_mode');
  }

  /// Clears all data from messages and settings boxes.
  Future<void> clearAll() async {
    await messagesBox.clear();
    await settingsBox.clear();
  }
}
