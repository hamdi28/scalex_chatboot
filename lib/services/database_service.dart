import 'package:hive/hive.dart';
import '../features/chat/data/models/message.dart';

class DatabaseService {
  static const String _messagesBox = 'messages';
  static const String _settingsBox = 'settings';

  Future<void> init() async {
    await Hive.openBox<Message>(_messagesBox);
    await Hive.openBox(_settingsBox);
  }

  Box<Message> get messagesBox => Hive.box<Message>(_messagesBox);
  Box get settingsBox => Hive.box(_settingsBox);

  // Message operations
  Future<void> saveMessage(Message message) async {
    await messagesBox.add(message);
  }

  Future<List<Message>> getAllMessages() async {
    return messagesBox.values.toList();
  }

  Future<List<Message>> getMessagesByUser(String userId) async {
    return messagesBox.values
        .where((message) => message.userId == userId)
        .toList();
  }

  Future<void> clearHistory() async {
    await messagesBox.clear();
  }

  Future<void> deleteMessage(String messageId) async {
    final message = messagesBox.values.firstWhere(
          (msg) => msg.id == messageId,
    );
    await message.delete();
  }

  // Settings operations
  Future<void> saveLanguage(String languageCode) async {
    await settingsBox.put('language', languageCode);
  }

  String? getLanguage() {
    return settingsBox.get('language');
  }

  Future<void> saveSelectedModel(String model) async {
    await settingsBox.put('selected_model', model);
  }

  String? getSelectedModel() {
    return settingsBox.get('selected_model');
  }

  Future<void> saveDarkMode(bool isDark) async {
    await settingsBox.put('dark_mode', isDark);
  }

  bool? getDarkMode() {
    return settingsBox.get('dark_mode');
  }

  // Clear all data
  Future<void> clearAll() async {
    await messagesBox.clear();
    await settingsBox.clear();
  }
}