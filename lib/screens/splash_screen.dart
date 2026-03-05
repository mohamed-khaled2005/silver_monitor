import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../animations/scale_animation.dart';
import '../providers/app_manager_provider.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _prefsKeyOnboarding = 'onboarding_completed';

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final manager = context.read<AppManagerProvider>();
    await manager.initialize();

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(_prefsKeyOnboarding) ?? false;

    if (!mounted) return;

    final provider = context.read<GoldProvider>();
    final savedCurrency = manager.preferences.selectedCurrency ??
        prefs.getString('selected_currency_code');
    if (savedCurrency != null && savedCurrency.isNotEmpty) {
      provider.setCurrency(savedCurrency);
    }

    final Widget nextScreen =
        onboardingCompleted ? const HomeScreen() : const OnboardingScreen();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: AppAnimations.pageTransition,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: nextScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.45,
            colors: [
              _silverAccent.withValues(alpha: 0.12),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleAnimation(
                child: Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _silverAccent.withValues(alpha: 0.38),
                        blurRadius: 26,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Image.asset(
                      'assets/images/Icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'مراقب الفضة',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                      color: _silverAccent,
                      fontFamily: 'Tajawal',
                      shadows: [
                        Shadow(
                          blurRadius: 9,
                          color: _silverAccent.withValues(alpha: 0.42),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_silverAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
