import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../animations/fade_animation.dart';
import '../animations/scale_animation.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import 'currency_selection_screen.dart';
import 'home_screen.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _saving = false;

  static const String _prefsKeyOnboarding = 'onboarding_completed';
  static const String _prefsKeyMulti = 'selected_currency_codes';
  static const String _prefsKeySingle = 'selected_currency_code';

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.stacked_line_chart_rounded,
      title: 'مراقب الفضة',
      description:
          'تابع سعر أونصة وجرام الفضة بشكل لحظي حسب العملة التي تختارها، بواجهة عربية واضحة.',
    ),
    _OnboardingPage(
      icon: Icons.candlestick_chart_rounded,
      title: 'حركة السعر',
      description:
          'شاهد أداء الفضة خلال آخر 10 أيام مع شارت تفاعلي وجدول مرتب من الأحدث إلى الأقدم.',
    ),
    _OnboardingPage(
      icon: Icons.workspace_premium_rounded,
      title: 'عيارات وسبائك',
      description:
          'اطلع على أسعار العيارات المختلفة وأسعار السبائك بطريقة منظمة وسهلة القراءة.',
    ),
    _OnboardingPage(
      icon: Icons.calculate_rounded,
      title: 'حاسبة الفضة',
      description:
          'احسب قيمة الفضة بسرعة بناءً على الوزن والوحدة المختارة، مع تحديث مباشر للأسعار.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyOnboarding, true);

      final selected = _loadSavedCurrencies(prefs);

      if (!mounted) return;

      Widget nextScreen;
      if (selected.isNotEmpty) {
        final provider = Provider.of<GoldProvider>(context, listen: false);
        provider.setCurrency(selected.first);
        nextScreen = const HomeScreen();
      } else {
        nextScreen = const CurrencySelectionScreen();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, animation, __) {
            return FadeTransition(
              opacity: animation,
              child: nextScreen,
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')),
      );
    }
  }

  List<String> _loadSavedCurrencies(SharedPreferences prefs) {
    final multi = prefs.getString(_prefsKeyMulti);
    List<String> selected = [];

    if (multi != null && multi.trim().isNotEmpty) {
      selected = multi
          .split(',')
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (selected.length > 2) {
        selected = selected.take(2).toList();
      }
    } else {
      final single = prefs.getString(_prefsKeySingle);
      if (single != null && single.trim().isNotEmpty) {
        selected = [single.trim().toUpperCase()];
      }
    }

    return selected;
  }

  void _next() {
    if (_saving) return;

    final isLast = _currentPage == _pages.length - 1;
    if (isLast) {
      _completeOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _saving ? null : _completeOnboarding,
                    child: Text(
                      'تخطي',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _silverAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return FadeAnimation(
                      key: ValueKey(index),
                      child: _buildPage(_pages[index]),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(isActive: index == _currentPage),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _silverAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          _silverAccent.withValues(alpha: 0.65),
                      disabledForegroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            isLast ? 'ابدأ الآن' : 'التالي',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleAnimation(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _silverAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 68,
                color: _silverAccent,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: 0.1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 26 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? _silverAccent : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
