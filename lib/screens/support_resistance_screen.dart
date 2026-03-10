import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../services/forex_api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class SupportResistanceScreen extends StatefulWidget {
  const SupportResistanceScreen({
    super.key,
    required this.isActive,
  });

  final bool isActive;

  @override
  State<SupportResistanceScreen> createState() =>
      _SupportResistanceScreenState();
}

class _SupportResistanceScreenState extends State<SupportResistanceScreen> {
  bool _priming = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _ensureData();
    }
  }

  @override
  void didUpdateWidget(covariant SupportResistanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _ensureData();
    }
  }

  void _ensureData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _priming) return;
      _priming = true;
      try {
        final provider = context.read<GoldProvider>();
        if (provider.isLoading) {
          await Future<void>.delayed(const Duration(milliseconds: 180));
          if (mounted) {
            _ensureData();
          }
          return;
        }
        await provider.ensurePivotPointsLoaded();
      } finally {
        _priming = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoldProvider>();
    final data = provider.pivotPoints;
    final isLoading = provider.isPivotPointsLoading;
    final error = provider.pivotPointsError;

    final modelKeys = data?.models.keys.toList() ?? const <String>[];
    if (_selectedTabIndex >= modelKeys.length) {
      _selectedTabIndex = 0;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: Responsive.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'الدعم والمقاومة'),
          const SizedBox(height: 14),
          _buildBody(
            provider: provider,
            data: data,
            isLoading: isLoading,
            error: error,
            modelKeys: modelKeys,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildBody({
    required GoldProvider provider,
    required PivotPointsData? data,
    required bool isLoading,
    required String? error,
    required List<String> modelKeys,
  }) {
    if (isLoading && data == null) {
      return _loadingState();
    }

    if (data == null) {
      return _errorState(error);
    }

    final selectedKey = modelKeys[_selectedTabIndex];
    final selectedLevels = data.models[selectedKey] ?? const <String, double>{};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            AppColors.cardLight.withValues(alpha: 0.92),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(
            signal: data.signal,
            isLoading: isLoading,
          ),
          const SizedBox(height: 12),
          _modelTabs(modelKeys: modelKeys),
          if (isLoading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
          ],
          const SizedBox(height: 10),
          _levelsTable(
            modelName: _modelName(selectedKey),
            levels: selectedLevels,
            currency: provider.selectedCurrency,
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return Container(
      width: double.infinity,
      height: 260,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const CircularProgressIndicator(),
    );
  }

  Widget _errorState(String? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تعذر تحميل بيانات الدعم والمقاومة حالياً.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (error != null && error.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.86),
                fontSize: 11.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context
                .read<GoldProvider>()
                .ensurePivotPointsLoaded(force: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _silverAccent,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'إعادة المحاولة',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow({
    required PivotSignal signal,
    required bool isLoading,
  }) {
    final signalColor = _signalColor(signal.summary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _silverAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _silverAccent.withValues(alpha: 0.34)),
              ),
              child: const Icon(Icons.layers_rounded, color: _silverAccent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مستويات Pivot اليومية',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    isLoading
                        ? 'تحديث مباشر للمستويات...'
                        : 'اختر النموذج من التابات بالأسفل',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context
                  .read<GoldProvider>()
                  .ensurePivotPointsLoaded(force: true),
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded, color: _silverAccent),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              icon: Icons.track_changes_rounded,
              text: 'الإشارة: ${_signalLabel(signal.summary)}',
              color: signalColor,
            ),
            _chip(
              icon: Icons.verified_rounded,
              text:
                  'الثقة: ${signal.confidence.isEmpty ? '-' : signal.confidence}',
              color: _silverAccent,
            ),
            _chip(
              icon: Icons.query_stats_rounded,
              text: 'النتيجة: ${signal.score.toStringAsFixed(1)}',
              color: _silverAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelTabs({required List<String> modelKeys}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(modelKeys.length, (index) {
            final key = modelKeys[index];
            final selected = _selectedTabIndex == index;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedTabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _silverAccent.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? _silverAccent.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    _modelName(key),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected ? _silverAccent : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _levelsTable({
    required String modelName,
    required Map<String, double> levels,
    required String currency,
  }) {
    final ordered = _orderedLevels(levels);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نموذج $modelName',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...ordered.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _levelRow(
                level: entry.key,
                value: entry.value,
                currency: currency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelRow({
    required String level,
    required double value,
    required String currency,
  }) {
    final color = _levelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${value.toStringAsFixed(2)} $currency',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _orderedLevels(Map<String, double> levels) {
    const order = <String>[
      'R5',
      'R4',
      'R3',
      'R2',
      'R1',
      'P',
      'S1',
      'S2',
      'S3',
      'S4',
      'S5',
    ];

    final result = <MapEntry<String, double>>[];
    for (final key in order) {
      final value = levels[key];
      if (value != null) {
        result.add(MapEntry(key, value));
      }
    }

    for (final entry in levels.entries) {
      if (result.any((e) => e.key == entry.key)) continue;
      result.add(entry);
    }

    return result;
  }

  String _modelName(String key) {
    switch (key.trim().toLowerCase()) {
      case 'fibonacci':
        return 'فيبوناتشي';
      case 'classic':
        return 'كلاسيك';
      case 'camarilla':
        return 'كاماريلا';
      case 'woodie':
        return 'وودي';
      case 'demark':
        return 'دي مارك';
      default:
        return key.toUpperCase();
    }
  }

  String _signalLabel(String summary) {
    switch (summary.trim().toLowerCase()) {
      case 'buy':
        return 'شراء';
      case 'sell':
        return 'بيع';
      default:
        return 'محايد';
    }
  }

  Color _signalColor(String summary) {
    switch (summary.trim().toLowerCase()) {
      case 'buy':
        return AppColors.success;
      case 'sell':
        return AppColors.error;
      default:
        return _silverAccent;
    }
  }

  Color _levelColor(String level) {
    final upper = level.toUpperCase();
    if (upper.startsWith('R')) return AppColors.error;
    if (upper.startsWith('S')) return AppColors.success;
    return _silverAccent;
  }
}
