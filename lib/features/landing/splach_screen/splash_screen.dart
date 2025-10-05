// splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scalex_chatbot/services/auth_service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _mainController; // controls the overall timeline (5s)
  late final AnimationController _pulseController; // breathing pulse
  late final AnimationController _glowController; // glow/shadow pulsing

  // Animations
  late final Animation<double> _scaleAnimation; // entrance scale (0 -> 2s)
  late final Animation<double> _fadeAnimation; // entrance fade (0 -> 2s)
  late final Animation<double> _pulseAnimation; // continuous subtle pulse
  late final Animation<double> _glowAnimation; // continuous glow/shadow

  // splash duration (must be 5s as requested)
  static const Duration _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    // make status bar blend with splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // main controller represents the full splash timeline (5 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();

    // pulse and glow run continuously while splash is visible
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Entrance animations happen in the first ~40% of the main timeline (0..2s)
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // continuous subtle breathing pulse
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // continuous glow variation (used in boxShadow blur/spread)
    _glowAnimation = Tween<double>(begin: 6.0, end: 18.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Guarantee the splash stays visible for the full 5 seconds, then navigate.
    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final authService = AuthService(); // adjust path/import as needed
      final bool loggedIn = authService.isLoggedIn;

      if (!mounted) return;
      if (loggedIn) {
        Navigator.of(context).pushReplacementNamed('/chat');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (_) {
      // fallback to landing if anything goes wrong
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep colors driven by theme like your app
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              primary.withOpacity(0.75),
              secondary.withOpacity(0.85),
              secondary,
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // subtle decorative background circles (optional)
            _buildBackgroundDecorations(),

            // center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated logo:
                  // outer AnimatedBuilder -> handles fade + entrance scale
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },

                    // inner child: a second AnimatedBuilder handles continuous pulse & glow,
                    // its child is the Icon so the icon itself doesn't rebuild unnecessarily.
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulseController, _glowController]),
                      builder: (context, childIcon) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.10),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.36),
                                  blurRadius: _glowAnimation.value,
                                  spreadRadius: _glowAnimation.value / 2,
                                ),
                              ],
                            ),
                            child: childIcon,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 100,
                        color: primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App name & subtitle (appear with same fade)
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'ScaleX Chatbot',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: primary.withOpacity(0.25),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AI-Powered Conversations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Loading indicator - visible during whole splash, keeps it feeling "alive"
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      // make spinner fade in with entrance
                      final spinnerOpacity = _fadeAnimation.value;
                      return Opacity(
                        opacity: spinnerOpacity,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // bottom small text
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  );
                },
                child: Text(
                  'Powered by Advanced AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    // simple subtle circles to add depth
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -120,
          child: Opacity(
            opacity: 0.12,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          left: -160,
          child: Opacity(
            opacity: 0.10,
            child: Container(
              width: 460,
              height: 460,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
