import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../widgets/app_section_header.dart';

/// 🎨 لون فضي محلي لصفحة "عن التطبيق"
const Color _silverAccent = Color(0xFFC0C5D5);

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeAnimation(
      child: SingleChildScrollView(
        padding: Responsive.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const AppSectionHeader(title: 'من نحن'),
            const SizedBox(height: 16),
            // الكارت العلوي (نبذة عن التطبيق)
            SlideAnimation(
              child: _buildHeaderCard(),
            ),
            const SizedBox(height: 20),

            // شبكة المميزات
            SlideAnimation(
              delay: const Duration(milliseconds: 120),
              child: _buildFeatureGrid(),
            ),
            const SizedBox(height: 20),

            // كارت عن موقع المراقب
            SlideAnimation(
              delay: const Duration(milliseconds: 220),
              child: _buildSiteInfoCard(),
            ),
            const SizedBox(height: 20),

            // الفوتر (مخفي)
            SlideAnimation(
              delay: const Duration(milliseconds: 320),
              child: _buildFooterNote(),
            ),
          ],
        ),
      ),
    );
  }

  // ======================= Header (تم تبسيطه) =======================

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن التطبيق',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _silverAccent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'مراقب الفضة',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'تطبيق “مراقب الفضة” هو التطبيق الرسمي لمنصة المراقب (almurakib.com)، تم تصميمه بعناية ليقدّم لك عرضًا واضحًا لأسعار الأونصة والجرام والعيارات والسبائك، بالإضافة إلى رسوم بيانية لأداء الفضة خلال الفترة الماضية، وكل ذلك بواجهة عربية أنيقة وسهلة الاستخدام.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ======================= Feature grid =======================

  Widget _buildFeatureGrid() {
    final List<Map<String, dynamic>> features = [
      {
        'icon': Icons.refresh_rounded,
        'title': 'أسعار لحظية',
        'desc': 'تحديثات آلية مستمرة تعكس آخر حركة في سوق الفضة.',
      },
      {
        'icon': Icons.calculate_rounded,
        'title': 'حاسبة الفضة',
        'desc': 'حساب قيمة الفضة بدقة حسب الوزن والوحدة والعملة.',
      },
      {
        'icon': Icons.show_chart_rounded,
        'title': 'رسوم بيانية',
        'desc': 'منحنيات سعرية توضح اتجاه الفضة عبر الأيام.',
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'title': 'سبائك وأعيرة',
        'desc': 'عرض منظم لأسعار عيارات الفضة وسبائكها بمختلف الأوزان.',
      },
      {
        'icon': Icons.language_rounded,
        'title': 'واجهة عربية كاملة',
        'desc': 'تصميم مريح وسهل الاستخدام للمستخدم العربي.',
      },
      {
        'icon': Icons.shield_rounded,
        'title': 'موثوقية عالية',
        'desc': 'بيانات معتمدة ضمن منظومة موقع المراقب المالية.',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ما الذي يقدّمه لك التطبيق؟',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: _silverAccent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 500;
              final int crossAxisCount = isWide ? 2 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 3.4 : 3.0,
                ),
                itemBuilder: (context, index) {
                  final item = features[index];
                  return _buildFeatureTile(
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    description: item['desc'] as String,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _silverAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: _silverAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================= Site info =======================

  Widget _buildSiteInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن موقع المراقب',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _silverAccent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'موقع المراقب هو منصة عربية متخصصة في متابعة الأسعار المالية والأسواق العالمية، مع تغطية لأسعار الفضة، الذهب، العملات، الأسهم، الطاقة، والمؤشرات على مدار الساعة.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'يقدّم الموقع بيانات دقيقة ومحدّثة مبنية على مصادر رسمية، مع محتوى مبسّط يساعد المستخدم على فهم المشهد الاقتصادي واتخاذ قرارات أكثر وعيًا.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'تطبيق “مراقب الفضة” هو الامتداد العملي لهذه المنظومة على الهواتف الذكية، لتبقى قريبًا من حركة الفضة أينما كنت، وبطريقة تناسب إيقاعك اليومي.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ======================= Footer =======================

  Widget _buildFooterNote() {
    return const SizedBox.shrink();
  }
}

// ======================= Tag chip =======================

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _silverAccent.withOpacity(0.7),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 16,
            color: _silverAccent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
