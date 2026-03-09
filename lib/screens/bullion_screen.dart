import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animations/fade_animation.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';

class BullionScreen extends StatelessWidget {
  const BullionScreen({super.key});

  static const Color _silverAccent = Color(0xFFC0C5D5);

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
            const AppSectionHeader(title: 'أسعار السبائك'),
            const SizedBox(height: 16),
            _buildBullionTable(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBullionTable(GoldProvider provider) {
    final bullions = List.of(provider.bullions)
      ..sort((a, b) => a.weight.compareTo(b.weight));

    if (bullions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            'لا توجد بيانات متاحة لسبائك الفضة حاليًا.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.cardLight.withValues(alpha: 0.9),
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
          ...bullions.map((bullion) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      bullion.type,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
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
