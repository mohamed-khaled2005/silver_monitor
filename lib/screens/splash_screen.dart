import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'currency_selection_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../utils/constants.dart';
import '../animations/scale_animation.dart';
import '../providers/gold_provider.dart';

/// ظ‹ع؛عکآ¨ ط¸â€‍ط¸ث†ط¸â€  ط¸ظ¾ط·آ¶ط¸ظ¹ ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ ط¸â€‍ط·آµط¸ظ¾ط·آ­ط·آ© ط·آ§ط¸â€‍ط·آ³ط·آ¨ط¸â€‍ط·آ§ط·آ´ ط·آ¨ط·آ¯ط¸â€‍ط·آ§ط¸â€¹ ط¸â€¦ط¸â€  ط·آ§ط¸â€‍ط·آ°ط¸â€،ط·آ¨ط¸ظ¹
const Color _silverAccent = Color(0xFFC0C5D5);

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _prefsKeyOnboarding = 'onboarding_completed';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    // ط¸â€ ط·آ®ط¸â€‍ط¸ظ¹ ط·آ§ط¸â€‍ط·آ£ط¸â€ ط¸ظ¹ط¸â€¦ط¸ظ¹ط·آ´ط¸â€  ط¸ظ¹ط·آ´ط·ع¾ط·ط›ط¸â€‍ ط·آ´ط¸ث†ط¸ظ¹ط·آ©
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool(_prefsKeyOnboarding) ?? false;
    final savedCurrency = prefs.getString('selected_currency_code');

    if (!mounted) return;

    Widget nextScreen;

    if (!onboardingCompleted) {
      nextScreen = const OnboardingScreen();
    } else if (savedCurrency != null && savedCurrency.isNotEmpty) {
      final provider = Provider.of<GoldProvider>(context, listen: false);
      provider.setCurrency(savedCurrency);
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const CurrencySelectionScreen();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: AppAnimations.pageTransition,
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
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
            radius: 1.5,
            colors: [
              _silverAccent.withAlpha((0.10 * 255).toInt()),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ط·آ¯ط·آ§ط·آ¦ط·آ±ط·آ© ط·آ§ط¸â€‍ط·آ£ط¸ظ¹ط¸â€ڑط¸ث†ط¸â€ ط·آ© ط·آ¨ط·آ®ط¸â€‍ط¸ظ¾ط¸ظ¹ط·آ© ط·آ¨ط¸ظ¹ط·آ¶ط·آ§ط·طŒ ط·آ¹ط·آ´ط·آ§ط¸â€  ط·آ§ط¸â€‍ط¸â€‍ط¸ث†ط·آ¬ط¸ث† ط¸ظ¹ط·آ¨ط·آ§ط¸â€
              ScaleAnimation(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _silverAccent.withAlpha((0.40 * 255).toInt()),
                        blurRadius: 30,
                        spreadRadius: 10,
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
              const SizedBox(height: 40),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        '\u0645\u0631\u0627\u0642\u0628 \u0627\u0644\u0641\u0636\u0629',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _silverAccent,
                          fontFamily: 'Tajawal',
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color:
                                  _silverAccent.withAlpha((0.50 * 255).toInt()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 40,
                  height: 40,
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
