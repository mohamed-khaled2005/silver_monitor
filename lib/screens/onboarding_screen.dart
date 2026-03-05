import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_manager_provider.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

const Color _silverAccent = Color(0xFFC0C5D5);
const Color _onboardingTop = Color(0xFF0A0A0A);
const Color _onboardingBottom = Color(0xFF050505);
const Color _cardColor = Color(0xFF151515);

const List<_OnboardingFeature> _features = [
  _OnboardingFeature(
    icon: Icons.bolt_rounded,
    title: 'تحديثات سعر الفضة لحظيا',
    description:
        'احصل على تحديث مستمر لسعر الفضة في الوقت الحقيقي، مع عرض واضح لحركة الأسعار لمساعدتك في اتخاذ القرار بسرعة.',
    tag: 'Live',
  ),
  _OnboardingFeature(
    icon: Icons.payments_rounded,
    title: 'دعم العملات المختلفة',
    description:
        'اختر العملة المناسبة لك واعرض الأسعار والحسابات بنفس العملة التي تتعامل بها يوميا بدون تحويل يدوي.',
    tag: 'Currency',
  ),
  _OnboardingFeature(
    icon: Icons.straighten_rounded,
    title: 'متابعة العيارات',
    description:
        'استعرض أسعار عيارات الفضة المختلفة بشكل منظم وقارن بينها بسرعة لمعرفة الأنسب في الشراء أو البيع.',
    tag: 'Calibers',
  ),
  _OnboardingFeature(
    icon: Icons.inventory_2_rounded,
    title: 'قسم السبائك',
    description:
        'تابع أسعار وأوزان السبائك بسهولة مع واجهة واضحة تساعدك على المقارنة قبل تنفيذ أي صفقة.',
    tag: 'Bullion',
  ),
  _OnboardingFeature(
    icon: Icons.calculate_rounded,
    title: 'حاسبة الفضة الذكية',
    description:
        'احسب القيمة الفعلية للفضة حسب الوزن والعيار والسعر الحالي بدقة خلال ثوان قليلة.',
    tag: 'Calculator',
  ),
  _OnboardingFeature(
    icon: Icons.trending_up_rounded,
    title: 'حاسبة الربح والخسارة',
    description:
        'قيّم نتائج صفقاتك بدقة واعرف صافي الربح أو الخسارة بناء على سعر الشراء وسعر البيع والوزن.',
    tag: 'P/L',
  ),
  _OnboardingFeature(
    icon: Icons.mosque_rounded,
    title: 'حاسبة الزكاة',
    description:
        'احسب زكاة الفضة بطريقة بسيطة ودقيقة وفق القيم الحالية لتكون متأكدا من القيمة المستحقة.',
    tag: 'Zakat',
  ),
  _OnboardingFeature(
    icon: Icons.school_rounded,
    title: 'محتوى تعليمي متخصص',
    description:
        'اطلع على مقالات تعليمية تساعدك على فهم السوق وقراءة التغيرات وتحسين قراراتك الاستثمارية.',
    tag: 'Education',
  ),
  _OnboardingFeature(
    icon: Icons.person_rounded,
    title: 'حساب شخصي ومزامنة إعدادات',
    description:
        'أنشئ حسابك لحفظ إعداداتك والوصول إلى تفضيلاتك من أكثر من جهاز بسهولة وأمان.',
    tag: 'Sync',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _prefsKeyOnboarding = 'onboarding_completed';
  bool _saving = false;

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyOnboarding, true);

      if (!mounted) return;

      final manager = context.read<AppManagerProvider>();
      final provider = context.read<GoldProvider>();
      final savedCurrency = manager.preferences.selectedCurrency ??
          prefs.getString('selected_currency_code');
      if (savedCurrency != null && savedCurrency.isNotEmpty) {
        provider.setCurrency(savedCurrency);
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const HomeScreen(),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _onboardingBottom,
        body: Stack(
          children: [
            const _OnboardingBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _saving ? null : _continue,
                        style: TextButton.styleFrom(
                          foregroundColor: _silverAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        label: const Text(
                          'تخطي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHero(),
                              const SizedBox(height: 16),
                              Text(
                                'أهم الميزات',
                                style: AppTextStyles.headingSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'واجهة أخف وأوضح لمتابعة الأسعار والحسابات الأساسية بسرعة.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ..._features.take(5).map(_buildFeatureCard),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _silverAccent,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              _silverAccent.withValues(alpha: 0.55),
                          disabledForegroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'ابدأ الآن',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cardColor.withValues(alpha: 0.96),
            const Color(0xFF202020).withValues(alpha: 0.92),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _silverAccent.withValues(alpha: 0.30),
              ),
            ),
            child: Image.asset(
              'assets/images/Icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبا بك في مراقب الفضة',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'تطبيق احترافي لمتابعة أسعار الفضة، إدارة قرارات الشراء والبيع، وتنفيذ الحسابات المهمة بدقة وسرعة.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_OnboardingFeature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _cardColor.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _silverAccent.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: _silverAccent.withValues(alpha: 0.14),
              ),
              child: Icon(
                feature.icon,
                size: 20,
                color: _silverAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          feature.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _silverAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          feature.tag,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _silverAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feature.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_onboardingTop, _onboardingBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -115,
            right: -70,
            child: _GlowCircle(
              size: 260,
              color: _silverAccent.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 320,
            left: -90,
            child: _GlowCircle(
              size: 230,
              color: _silverAccent.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _GlowCircle(
              size: 220,
              color: _silverAccent.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _OnboardingFeature {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String description;
  final String tag;
}
