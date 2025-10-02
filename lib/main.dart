import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scalex_chatbot/features/profile/data/providers/theme_provider.dart';
import 'package:scalex_chatbot/services/auth_service.dart';

import 'core/theme/app_theme.dart';
import 'features/landing/presentation/screens/landing_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/chat/data/models/message.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(MessageAdapter());

  // Initialize Database Service
  final databaseService = DatabaseService();
  await databaseService.init();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerWidget { // Changed from StatelessWidget to ConsumerWidget
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider); // Now accessible via ConsumerWidget
    return MaterialApp(
      title: 'ScaleX Chatbot',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // Fixed: was incorrectly set to lightTheme
      themeMode: themeMode, // Now uses the dynamic themeMode from provider

      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/chat': (context) => const ChatScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class LandingWrapper extends StatelessWidget {
  const LandingWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    // Decide initial screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authService.isLoggedIn) {
        // User is logged in, navigate to chat and remove landing from stack
        Navigator.pushReplacementNamed(context, '/chat');
      }
    });

    // While checking, show the landing screen
    return const LandingScreen();
  }
}
