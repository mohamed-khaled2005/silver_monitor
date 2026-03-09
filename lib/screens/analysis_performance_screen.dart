import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';
import '../widgets/price_chart.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class AnalysisPerformanceScreen extends StatefulWidget {
  const AnalysisPerformanceScreen({
    super.key,
    required this.chartRefreshTick,
    required this.isActive,
  });

  final int chartRefreshTick;
  final bool isActive;

  @override
  State<AnalysisPerformanceScreen> createState() =>
      _AnalysisPerformanceScreenState();
}

class _AnalysisPerformanceScreenState extends State<AnalysisPerformanceScreen> {
  bool _preloadInProgress = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _handleScreenActivation();
    }
  }

  @override
  void didUpdateWidget(covariant AnalysisPerformanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _handleScreenActivation();
      return;
    }
    if (widget.isActive &&
        oldWidget.chartRefreshTick != widget.chartRefreshTick) {
      _handleScreenActivation();
    }
  }

  void _handleScreenActivation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_preloadInProgress) return;
      _preloadInProgress = true;
      try {
        final provider = context.read<GoldProvider>();
        if (provider.isLoading) {
          await Future<void>.delayed(const Duration(milliseconds: 180));
          if (mounted) {
            _handleScreenActivation();
          }
          return;
        }

        if (provider.currentGoldPrice == null) {
          await provider.fetchGoldPrices();
        }

        await provider.setChartRange(
          ChartRange.year,
          loadIfNeeded: false,
        );
        await provider.preloadAnalysisChartRanges();
      } finally {
        _preloadInProgress = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoldProvider>();
    final price = provider.currentGoldPrice;
    final history = provider.selectedChartPrices;
    final selectedRange = provider.selectedChartRange;

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
              price: price,
              currency: provider.selectedCurrency,
            ),
            const SizedBox(height: 14),
            _chartCard(
              provider: provider,
              selectedRange: selectedRange,
              history: history,
              currency: provider.selectedCurrency,
            ),
            const SizedBox(height: 14),
            _technicalIndicators(
              history: history,
              currency: provider.selectedCurrency,
            ),
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
    required GoldPrice price,
    required String currency,
  }) {
    final directionLabel = price.isPositive ? 'أداء صاعد' : 'أداء هابط';
    final directionColor =
        price.isPositive ? AppColors.success : AppColors.error;
    final signedChange =
        '${price.change > 0 ? '+' : ''}${price.change.toStringAsFixed(2)} $currency';
    final changePercent = _ensurePercent(price.changePercent);
    final lastUpdated = _formatShortDate(price.lastUpdated.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            AppColors.cardLight.withValues(alpha: 0.94),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ملخص الأداء',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: directionColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: directionColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      price.isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 15,
                      color: directionColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      directionLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: directionColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${price.ouncePrice.toStringAsFixed(2)} $currency',
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 4),
          Text(
            'سعر الأونصة الحالي',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _summaryStatCard(
                    width: cardWidth,
                    label: 'التغير',
                    value: signedChange,
                    accent: directionColor,
                    icon: Icons.swap_vert_rounded,
                  ),
                  _summaryStatCard(
                    width: cardWidth,
                    label: 'النسبة',
                    value: changePercent,
                    accent: directionColor,
                    icon: Icons.percent_rounded,
                  ),
                  _summaryStatCard(
                    width: cardWidth,
                    label: 'سعر الجرام',
                    value: '${price.gramPrice.toStringAsFixed(2)} $currency',
                    accent: _silverAccent,
                    icon: Icons.straighten_rounded,
                  ),
                  _summaryStatCard(
                    width: cardWidth,
                    label: 'آخر تحديث',
                    value: lastUpdated,
                    accent: _silverAccent,
                    icon: Icons.schedule_rounded,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryStatCard({
    required double width,
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13.6,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({
    required GoldProvider provider,
    required ChartRange selectedRange,
    required List<double> history,
    required String currency,
  }) {
    final isRangeLoading = provider.isChartRangeLoading(selectedRange);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101722),
            Color(0xFF161F2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الشارت التحليلي',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _silverAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _silverAccent.withValues(alpha: 0.32),
                  ),
                ),
                child: Text(
                  selectedRange.labelAr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _silverAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.78),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'اسحب للتنقل - كبّر بإصبعين - نقرتان لإعادة الضبط',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rangeSelector(selectedRange),
          if (isRangeLoading && history.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 286,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D121A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: isRangeLoading && history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : PriceChart(
                    refreshTick: widget.chartRefreshTick,
                    prices: history,
                    range: selectedRange,
                    latestDateUtc: provider.currentGoldPrice?.lastUpdated,
                    currencyCode: currency,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector(ChartRange selectedRange) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0E141D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ChartRange.values.map((range) {
            final isSelected = range == selectedRange;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => context.read<GoldProvider>().setChartRange(range),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minWidth: 62),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _silverAccent.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isSelected
                          ? _silverAccent.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    range.labelAr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          isSelected ? _silverAccent : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _technicalIndicators({
    required List<double> history,
    required String currency,
  }) {
    if (history.length < 2) {
      return const SizedBox.shrink();
    }

    final sma7 = _simpleMovingAverage(history, 7);
    final sma30 = _simpleMovingAverage(history, 30);
    final rsi14 = _rsi(history, 14);
    final volatility = _volatilityPercent(history, 30);
    final trendSignal = _trendSignal(history);
    final trendColor = _trendColor(trendSignal);
    final periodReturn = _periodReturnPercent(history);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            AppColors.cardLight.withValues(alpha: 0.94),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _silverAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _silverAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: _silverAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المؤشرات الفنية للأداء',
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'قراءة سريعة لحركة السعر خلال الفترة المختارة',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = constraints.maxWidth >= 300 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _indicatorCard(
                    width: cardWidth,
                    title: 'SMA 7',
                    value: '${sma7.toStringAsFixed(2)} $currency',
                    hint: 'متوسط قصير الأجل',
                    accent: _silverAccent,
                    icon: Icons.show_chart_rounded,
                  ),
                  _indicatorCard(
                    width: cardWidth,
                    title: 'SMA 30',
                    value: '${sma30.toStringAsFixed(2)} $currency',
                    hint: 'متوسط متوسط الأجل',
                    accent: _silverAccent,
                    icon: Icons.timeline_rounded,
                  ),
                  _indicatorCard(
                    width: cardWidth,
                    title: 'RSI 14',
                    value: rsi14.toStringAsFixed(1),
                    hint: _rsiLabel(rsi14),
                    accent: _rsiColor(rsi14),
                    icon: Icons.speed_rounded,
                  ),
                  _indicatorCard(
                    width: cardWidth,
                    title: 'التذبذب',
                    value: '${volatility.toStringAsFixed(2)}%',
                    hint: _volatilityLabel(volatility),
                    accent: _silverAccent,
                    icon: Icons.multiline_chart_rounded,
                  ),
                  _indicatorCard(
                    width: cardWidth,
                    title: 'زخم الفترة',
                    value: _signedPercent(periodReturn),
                    hint: 'من أول الفترة لآخرها',
                    accent:
                        periodReturn >= 0 ? AppColors.success : AppColors.error,
                    icon: periodReturn >= 0
                        ? Icons.north_east_rounded
                        : Icons.south_east_rounded,
                  ),
                  _indicatorCard(
                    width: cardWidth,
                    title: 'إشارة الاتجاه',
                    value: trendSignal,
                    hint: 'SMA7 ${sma7 >= sma30 ? 'أعلى' : 'أقل'} من SMA30',
                    accent: trendColor,
                    icon: trendSignal == 'صاعد'
                        ? Icons.trending_up_rounded
                        : trendSignal == 'هابط'
                            ? Icons.trending_down_rounded
                            : Icons.trending_flat_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _rsiGauge(rsi14),
        ],
      ),
    );
  }

  Widget _indicatorCard({
    required double width,
    required String title,
    required String value,
    required String hint,
    required Color accent,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: AppTextStyles.bodySmall.copyWith(
                color: accent.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rsiGauge(double rsi) {
    final normalized = (rsi / 100).clamp(0.0, 1.0).toDouble();
    final meterColor = _rsiColor(rsi);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meterColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'مؤشر RSI بصري',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${rsi.toStringAsFixed(1)} / 100',
                style: AppTextStyles.bodySmall.copyWith(
                  color: meterColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              const markerSize = 12.0;
              final left =
                  (constraints.maxWidth - markerSize) * normalized.clamp(0, 1);
              const trackHeight = 8.0;
              const trackTop = (markerSize - trackHeight) / 2;

              return SizedBox(
                height: markerSize,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: trackTop,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF23C26B),
                              Color(0xFFE6B323),
                              Color(0xFFDA4C4C),
                            ],
                          ),
                        ),
                        child: const SizedBox(height: trackHeight),
                      ),
                    ),
                    Positioned(
                      left: left,
                      top: 0,
                      child: Container(
                        width: markerSize,
                        height: markerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: meterColor,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: meterColor.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rsiHint('30-', 'تشبع بيع'),
              _rsiHint('50', 'متوازن'),
              _rsiHint('70+', 'تشبع شراء'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rsiHint(String level, String label) {
    return Text(
      '$level $label',
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
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

  double _simpleMovingAverage(List<double> values, int window) {
    if (values.isEmpty) return 0;
    final start = math.max(0, values.length - window);
    final slice = values.sublist(start);
    final sum = slice.fold<double>(0, (acc, value) => acc + value);
    return sum / slice.length;
  }

  double _rsi(List<double> values, int period) {
    if (values.length < 2) return 50;

    final from = math.max(1, values.length - period);
    double gains = 0;
    double losses = 0;
    int samples = 0;

    for (var i = from; i < values.length; i++) {
      final diff = values[i] - values[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses += diff.abs();
      }
      samples++;
    }

    if (samples == 0) return 50;
    final avgGain = gains / samples;
    final avgLoss = losses / samples;
    if (avgGain == 0 && avgLoss == 0) return 50;
    if (avgLoss == 0) return 100;

    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  double _volatilityPercent(List<double> values, int window) {
    if (values.length < 2) return 0;

    final start = math.max(0, values.length - window);
    final slice = values.sublist(start);
    final mean =
        slice.fold<double>(0, (acc, value) => acc + value) / slice.length;
    if (mean == 0) return 0;

    final variance = slice.fold<double>(
          0,
          (acc, value) => acc + math.pow(value - mean, 2).toDouble(),
        ) /
        slice.length;
    final stdDev = math.sqrt(variance);
    return (stdDev / mean) * 100;
  }

  double _periodReturnPercent(List<double> values) {
    if (values.length < 2) return 0;
    final first = values.first;
    if (first == 0) return 0;
    return ((values.last - first) / first) * 100;
  }

  String _signedPercent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  String _trendSignal(List<double> values) {
    if (values.length < 2) return 'محايد';
    final smaShort = _simpleMovingAverage(values, 7);
    final smaLong = _simpleMovingAverage(values, 30);
    final last = values.last;

    if (last > smaShort && smaShort >= smaLong) return 'صاعد';
    if (last < smaShort && smaShort <= smaLong) return 'هابط';
    return 'محايد';
  }

  String _rsiLabel(double rsi) {
    if (rsi >= 70) return 'تشبع شراء';
    if (rsi <= 30) return 'تشبع بيع';
    return 'متوازن';
  }

  String _volatilityLabel(double volatility) {
    if (volatility >= 5) return 'تذبذب مرتفع';
    if (volatility >= 2) return 'تذبذب متوسط';
    return 'تذبذب منخفض';
  }

  Color _rsiColor(double rsi) {
    if (rsi >= 70) return AppColors.error;
    if (rsi <= 30) return AppColors.success;
    return _silverAccent;
  }

  Color _trendColor(String signal) {
    switch (signal) {
      case 'صاعد':
        return AppColors.success;
      case 'هابط':
        return AppColors.error;
      default:
        return _silverAccent;
    }
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

  String _formatShortDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }
}
