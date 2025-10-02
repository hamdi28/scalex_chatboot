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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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