import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../animations/fade_animation.dart';
import '../widgets/app_section_header.dart';

class BullionScreen extends StatelessWidget {
  const BullionScreen({Key? key}) : super(key: key);

  // 🎨 ألوان فضية خاصة بالشاشة دي
  static const Color _silverAccent = Color(0xFFC0C5D5);
  static const Color _silverBorder = Color(0xFF9FA6B5);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoldProvider>(context);

    return FadeAnimation(
      child: SingleChildScrollView(
        padding: Responsive.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const AppSectionHeader(title: 'السبائك'),
            const SizedBox(height: 16),
            _buildHintChip(context),
            const SizedBox(height: 24),
            _buildBullionTable(context, provider),
          ],
        ),
      ),
    );
  }

  /// شريحة توضيحية صغيرة أعلى الصفحة
  Widget _buildHintChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _silverBorder.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: _silverAccent,
            size: 18,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'أسعار سبائك الفضة حسب العملة المختارة',
              style: AppTextStyles.bodySmall,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullionTable(BuildContext context, GoldProvider provider) {
    final bullions = List.of(provider.bullions);

    if (bullions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'لا توجد بيانات متاحة لسبائك الفضة حالياً.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    // ترتيب تصاعدي حسب الوزن
    bullions.sort((a, b) => a.weight.compareTo(b.weight));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ هيدر الجدول (النوع | السعر)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.cardLight.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'النوع',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'السعر',
                    textAlign: TextAlign.left,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ✅ صفوف السبائك (بدون Scroll أفقي، عمودين فقط)
          ...bullions.map((bullion) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // النوع (مثال: "سبيكة 1 كيلوجرام فضة نقية")
                  Expanded(
                    flex: 2,
                    child: Text(
                      bullion.type,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // السعر في نفس السطر + العملة
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${bullion.price.toStringAsFixed(2)} ${provider.selectedCurrency}',
                      textAlign: TextAlign.left,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _silverAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
