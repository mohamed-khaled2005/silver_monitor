import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  static const Color _silverAccent = Color(0xFFC0C5D5);
  static const double _fixedSilverThresholdGrams = 595;

  final TextEditingController _assetsController = TextEditingController();
  final TextEditingController _debtsController = TextEditingController();

  double? _zakatAmount;
  double? _netAmount;
  double? _thresholdValue;
  bool _eligible = false;
  String _message = '';

  @override
  void dispose() {
    _assetsController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  String _money(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }

  void _clearResult() {
    _zakatAmount = null;
    _netAmount = null;
    _thresholdValue = null;
    _eligible = false;
    _message = '';
  }

  void _calculate({
    required double? gramPrice,
  }) {
    final assets = double.tryParse(_assetsController.text.trim());
    final debts = double.tryParse(_debtsController.text.trim()) ?? 0;

    if (assets == null || assets <= 0 || debts < 0) {
      setState(() {
        _clearResult();
        _message = 'أدخل القيم بشكل صحيح.';
      });
      return;
    }

    if (gramPrice == null || gramPrice <= 0) {
      setState(() {
        _clearResult();
        _message = 'لا يوجد سعر جرام حالي. حدّث الأسعار أولًا.';
      });
      return;
    }

    final net = assets - debts;
    final thresholdValue = _fixedSilverThresholdGrams * gramPrice;

    if (net <= 0) {
      setState(() {
        _zakatAmount = 0;
        _netAmount = net;
        _thresholdValue = thresholdValue;
        _eligible = false;
        _message =
            'صافي المال بعد خصم الديون يساوي صفر أو أقل. لا زكاة واجبة الآن.';
      });
      return;
    }

    if (net < thresholdValue) {
      setState(() {
        _zakatAmount = 0;
        _netAmount = net;
        _thresholdValue = thresholdValue;
        _eligible = false;
        _message =
            'صافي المال أقل من الحد الشرعي (595 جرام فضة). لا زكاة واجبة الآن.';
      });
      return;
    }

    setState(() {
      _zakatAmount = net * 0.025;
      _netAmount = net;
      _thresholdValue = thresholdValue;
      _eligible = true;
      _message = 'الزكاة المستحقة = 2.5% من صافي المال الذي بلغ الحد الشرعي.';
    });
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: '0.00',
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontFamily: 'Tajawal',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _silverAccent),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
          ),
          decoration: _inputDecoration(),
          onChanged: (_) {
            if (_zakatAmount == null &&
                _message.isEmpty &&
                _netAmount == null &&
                _thresholdValue == null) {
              return;
            }
            setState(_clearResult);
          },
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _silverAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePriceCard({
    required double? gramPrice,
    required String currency,
  }) {
    final hasPrice = gramPrice != null && gramPrice > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.price_change_outlined,
                size: 18,
                color: _silverAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'سعر جرام الفضة الحالي (تلقائي)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            hasPrice
                ? _money(gramPrice, currency)
                : 'غير متوفر حاليًا - حدّث الأسعار',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String currency,
    required double? gramPrice,
  }) {
    final accent = _eligible ? _silverAccent : AppColors.error;
    final badgeText = _eligible ? 'زكاة واجبة' : 'لا زكاة واجبة';
    final badgeBg = _eligible
        ? _silverAccent.withValues(alpha: 0.16)
        : AppColors.error.withValues(alpha: 0.18);
    final amountValue = _zakatAmount?.toStringAsFixed(2) ?? '0.00';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            AppColors.cardLight.withValues(alpha: 0.90),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _eligible
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نتيجة حساب الزكاة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _metricCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'صافي المال بعد الديون',
            value: _money(_netAmount!, currency),
          ),
          const SizedBox(height: 8),
          _metricCard(
            icon: Icons.rule_folder_outlined,
            title: 'الحد الشرعي (595 جرام فضة)',
            value: _money(_thresholdValue!, currency),
          ),
          if (gramPrice != null) ...[
            const SizedBox(height: 8),
            _metricCard(
              icon: Icons.sell_outlined,
              title: 'سعر الجرام المستخدم بالحساب',
              value: _money(gramPrice, currency),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'الزكاة المستحقة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$amountValue $currency',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.responsivePadding(context);
    final provider = context.watch<GoldProvider>();
    final gramPrice = provider.currentGoldPrice?.gramPrice;
    final currency = provider.selectedCurrency;

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'حاسبة زكاة الفضة'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'أدخل إجمالي الأصول والديون فقط. سعر جرام الفضة يتم جلبه تلقائيًا، والحد الشرعي ثابت (595 جرام فضة).',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLivePriceCard(
                  gramPrice: gramPrice,
                  currency: currency,
                ),
                const SizedBox(height: 10),
                _inputField(
                  controller: _assetsController,
                  label: 'إجمالي الأصول',
                ),
                const SizedBox(height: 10),
                _inputField(
                  controller: _debtsController,
                  label: 'إجمالي الديون',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _calculate(gramPrice: gramPrice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _silverAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'احسب الزكاة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (_message.isNotEmpty && _zakatAmount == null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_zakatAmount != null &&
                    _netAmount != null &&
                    _thresholdValue != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _buildResultCard(
                    currency: currency,
                    gramPrice: gramPrice,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
