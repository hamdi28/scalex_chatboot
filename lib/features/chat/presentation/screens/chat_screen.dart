import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scalex_chatbot/features/chat/data/models/message.dart';
import 'package:scalex_chatbot/features/profile/data/providers/ai_model_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../../../../services/ai_service.dart';
import 'dart:ui' as ui;
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isRTL = context.locale.languageCode == 'ar';
    List<Message> messageFromAi = chatState.messages.where((element) => element.aiModel == ref.read(chatProvider.notifier).state.selectedModel.name).toList();

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('app_name'.tr()),
          actions: [
            // AI Model Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<AIModel>(
                value: chatState.selectedModel,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: [
                  DropdownMenuItem(
                    value: AIModel.claude,
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, size: 16),
                        const SizedBox(width: 8),
                        Text('ai_models.claude'.tr()),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AIModel.deepseek,  // Replaced grok with deepseek
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy, size: 16),
                        const SizedBox(width: 8),
                        Text('ai_models.deepseek'.tr()),  // Updated translation key
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AIModel.groq,
                    child: Row(
                      children: [
                        const Icon(Icons.science, size: 16),
                        const SizedBox(width: 8),
                        Text('ai_models.groq'.tr()),
                      ],
                    ),
                  )
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(chatProvider.notifier).setSelectedModel(value);
                  }
                },
              ),
            ),

            // Profile Button
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages List
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_messages'.tr(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messageFromAi.length,
                itemBuilder: (context, index) {
                  final message = messageFromAi[index];
                  return MessageBubble(message: message);
                },
              ),
            ),

            // Loading Indicator
            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'loading'.tr(),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            // Input Area
            _buildInputArea(isRTL),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'type_message'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_empty_message'.tr())),
      );
      return;
    }

    final language = context.locale.languageCode;
    ref.read(chatProvider.notifier).sendMessage(text, language);

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}