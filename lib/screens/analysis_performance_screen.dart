import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';
import '../widgets/price_chart.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class AnalysisPerformanceScreen extends StatelessWidget {
  const AnalysisPerformanceScreen({
    super.key,
    required this.chartRefreshTick,
  });

  final int chartRefreshTick;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoldProvider>();
    final price = provider.currentGoldPrice;
    final history = provider.weeklyOuncePrices;

    return SingleChildScrollView(
      padding: Responsive.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'التحليل والأداء'),
          const SizedBox(height: 16),
          if (price == null)
            _emptyState()
          else ...[
            _performanceSummary(
              change: price.change,
              changePercent: price.changePercent,
              isPositive: price.isPositive,
              currency: provider.selectedCurrency,
            ),
            const SizedBox(height: 14),
            _chartCard(),
            const SizedBox(height: 14),
            _historyInsights(
              history: history,
              currency: provider.selectedCurrency,
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, color: _silverAccent, size: 34),
          const SizedBox(height: 8),
          Text(
            'لا توجد بيانات تحليل متاحة الآن.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _performanceSummary({
    required double change,
    required String changePercent,
    required bool isPositive,
    required String currency,
  }) {
    final directionLabel = isPositive ? 'أداء صاعد' : 'أداء هابط';
    final directionColor = isPositive ? AppColors.success : AppColors.error;
    final signedChange =
        '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)} $currency';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الأداء',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricChip('التغير', signedChange, _silverAccent),
              _metricChip(
                'النسبة',
                _ensurePercent(changePercent),
                directionColor,
              ),
              _metricChip('الاتجاه', directionLabel, directionColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: AppTextStyles.bodySmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الشارت لآخر 10 أيام',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PriceChart(refreshTick: chartRefreshTick),
          ),
        ],
      ),
    );
  }

  Widget _historyInsights({
    required List<double> history,
    required String currency,
  }) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final high = history.reduce(math.max);
    final low = history.reduce(math.min);
    final avg = history.reduce((a, b) => a + b) / history.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قراءة سريعة',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _insightRow('أعلى سعر', '${high.toStringAsFixed(2)} $currency'),
          const SizedBox(height: 8),
          _insightRow('أدنى سعر', '${low.toStringAsFixed(2)} $currency'),
          const SizedBox(height: 8),
          _insightRow('متوسط السعر', '${avg.toStringAsFixed(2)} $currency'),
        ],
      ),
    );
  }

  Widget _insightRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  String _ensurePercent(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '0%';
    if (t.contains('%')) return t;
    final d = double.tryParse(t);
    if (d == null) return '$t%';
    final sign = d > 0 ? '+' : '';
    return '$sign${d.toStringAsFixed(2)}%';
  }
}
