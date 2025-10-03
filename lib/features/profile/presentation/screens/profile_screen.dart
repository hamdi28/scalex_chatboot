import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scalex_chatbot/features/profile/data/providers/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/providers/user_summary_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For ui.TextDirection
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart'; // For .tr()
import 'package:intl/intl.dart'; // For DateFormat

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/providers/user_summary_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _generatedSummary;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final chatState = ref.watch(chatProvider);
    final isRTL = context.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('profile'.tr()),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Card(
                key: const ValueKey('user_info_card'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'Guest',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${'member_since'.tr()} ${DateFormat('MMM yyyy').format(user?.metadata.creationTime ?? DateTime.now())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${chatState.messages.where((m) => m.isUser).length} ${isRTL ? 'رسالة مرسلة' : 'messages sent'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // AI-Generated Summary Section
              Text(
                'user_summary'.tr(),
                key: const ValueKey('summary_title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              _buildUserSummaryCard(chatState, isRTL),

              const SizedBox(height: 24),

              // Settings Section
              Text(
                'settings'.tr(),
                key: const ValueKey('settings_title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              Card(
                key: const ValueKey('settings_card'),
                child: Column(
                  children: [
                    // Language Setting
                    ListTile(
                      key: const ValueKey('language_tile'),
                      leading: const Icon(Icons.language),
                      title: Text('language'.tr()),
                      trailing: DropdownButton<Locale>(
                        key: const ValueKey('language_dropdown'),
                        value: context.locale,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: Locale('en'),
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: Locale('ar'),
                            child: Text('العربية'),
                          ),
                        ],
                        onChanged: (locale) {
                          if (locale != null) {
                            context.setLocale(locale);
                          }
                        },
                      ),
                    ),

                    const Divider(height: 1),

                    // Theme Setting
                    ListTile(
                      key: const ValueKey('theme_tile'),
                      leading: const Icon(Icons.brightness_6),
                      title: Text('theme'.tr()),
                      trailing: DropdownButton<ThemeMode>(
                        key: const ValueKey('theme_dropdown'),
                        value: ref.watch(themeModeProvider),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            ref.read(themeModeProvider.notifier).setThemeMode(mode);
                          }
                        },
                      ),
                    ),

                    const Divider(height: 1),

                    // Export History
                    ListTile(
                      key: const ValueKey('export_tile'),
                      leading: const Icon(Icons.download),
                      title: Text('export_history'.tr()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showExportDialog(context);
                      },
                    ),

                    const Divider(height: 1),

                    // Clear History
                    ListTile(
                      key: const ValueKey('clear_tile'),
                      leading: const Icon(Icons.delete, color: Colors.orange),
                      title: Text(
                        'clear_history'.tr(),
                        style: const TextStyle(color: Colors.orange),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showClearHistoryDialog(context, ref),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('logout_button'),
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                            (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text('logout'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSummaryCard(ChatState chatState, bool isRTL) {
    final userMessagesCount = chatState.messages.where((m) => m.isUser).length;

    if (userMessagesCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                isRTL
                    ? 'لا توجد رسائل كافية لإنشاء ملخص'
                    : 'Not enough messages to generate a summary',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ai_analysis'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_generatedSummary == null && !_isGenerating)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _generateSummary(),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(isRTL ? 'إنشاء الملخص' : 'Generate Summary'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

            if (_isGenerating)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      isRTL ? 'جاري إنشاء الملخص...' : 'Generating summary...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            if (_generatedSummary != null && !_isGenerating)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _generatedSummary!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRTL
                            ? 'بناءً على $userMessagesCount رسالة'
                            : 'Based on $userMessagesCount messages',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton.icon(
                        onPressed: () => _generateSummary(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(isRTL ? 'تحديث' : 'Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final chatState = ref.read(chatProvider);
      final userMessages = chatState.messages
          .where((m) => m.isUser && m.aiModel == chatState.selectedModel.name)
          .map((m) => m.content)
          .toList();

      final selectedModel = chatState.selectedModel;
      final summary = await ref.read(userSummaryProvider((userMessages, selectedModel)).future);

      if (mounted) {
        setState(() {
          _generatedSummary = summary;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatedSummary = context.locale.languageCode == 'ar'
              ? 'حدث خطأ أثناء إنشاء الملخص'
              : 'Error generating summary';
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('export_dialog'),
        title: Text('export_history'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('pdf_export_tile'),
              leading: const Icon(Icons.picture_as_pdf),
              title: Text('export_as_pdf'.tr()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.locale.languageCode == 'ar'
                        ? 'سيتم إضافة هذه الميزة قريباً'
                        : 'Feature coming soon'),
                  ),
                );
              },
            ),
            ListTile(
              key: const ValueKey('text_export_tile'),
              leading: const Icon(Icons.text_snippet),
              title: Text('export_as_text'.tr()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.locale.languageCode == 'ar'
                        ? 'سيتم إضافة هذه الميزة قريباً'
                        : 'Feature coming soon'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_export_button'),
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('clear_dialog'),
        title: Text('clear_history'.tr()),
        content: Text('confirm_clear'.tr()),
        actions: [
          TextButton(
            key: const ValueKey('cancel_clear_button'),
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            key: const ValueKey('delete_clear_button'),
            onPressed: () async {
              await ref.read(chatProvider.notifier).clearHistory();
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _generatedSummary = null; // Clear summary when history is cleared
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.locale.languageCode == 'ar'
                        ? 'تم مسح السجل'
                        : 'History cleared'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}