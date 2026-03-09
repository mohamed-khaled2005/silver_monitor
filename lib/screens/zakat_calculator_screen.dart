import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  static const Color _silverAccent = Color(0xFFC0C5D5);
  static const double _nisabPureSilverGrams = 595;

  final TextEditingController _weightController = TextEditingController();

  GoldCaliber? _selectedCaliber;
  double? _autoPricePerGram;

  double? _enteredWeight;
  double? _pureEquivalent999Grams;
  double? _marketValue;
  double? _zakatAmount;
  double? _nisabCashValue;
  bool _eligible = false;
  String _message = '';

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  String _money(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }

  void _clearResult() {
    _enteredWeight = null;
    _pureEquivalent999Grams = null;
    _marketValue = null;
    _zakatAmount = null;
    _nisabCashValue = null;
    _eligible = false;
    _message = '';
  }

  int _extractFineness(GoldCaliber caliber) {
    final fromName = RegExp(r'(\d{3})').firstMatch(caliber.name);
    if (fromName != null) {
      final parsed = int.tryParse(fromName.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    final purityRaw = caliber.purity.replaceAll('%', '').trim();
    final purityValue = double.tryParse(purityRaw);
    if (purityValue != null && purityValue > 0) {
      return (purityValue * 10).round();
    }
    return 999;
  }

  void _syncSelectedCaliber(List<GoldCaliber> calibers) {
    if (calibers.isEmpty) return;

    final selectedName = _selectedCaliber?.name;
    final next = calibers.firstWhere(
      (c) => c.name == selectedName,
      orElse: () => calibers.first,
    );

    final shouldUpdate = _selectedCaliber?.name != next.name ||
        (_autoPricePerGram ?? -1) != next.pricePerGram;
    if (!shouldUpdate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedCaliber = next;
        _autoPricePerGram = next.pricePerGram;
        if (_zakatAmount != null ||
            _marketValue != null ||
            _pureEquivalent999Grams != null ||
            _message.isNotEmpty) {
          _clearResult();
        }
      });
    });
  }

  void _calculate({
    required GoldCaliber? caliber,
    required double? gramPrice999,
    required String currency,
  }) {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      setState(() {
        _clearResult();
        _message = 'أدخل وزنًا صحيحًا بالجرام.';
      });
      return;
    }

    if (caliber == null) {
      setState(() {
        _clearResult();
        _message = 'اختر العيار أولًا.';
      });
      return;
    }

    final pricePerGram = caliber.pricePerGram;
    if (pricePerGram <= 0) {
      setState(() {
        _clearResult();
        _message = 'السعر التلقائي غير متوفر حاليًا. حدّث الأسعار أولًا.';
      });
      return;
    }

    final fineness = _extractFineness(caliber);
    final pureEquivalent = weight * (fineness / 999.0);
    final valueNow = weight * pricePerGram;
    final reachedNisab = pureEquivalent >= _nisabPureSilverGrams;
    final zakatDue = reachedNisab ? valueNow * 0.025 : 0.0;
    final nisabCash = gramPrice999 == null || gramPrice999 <= 0
        ? null
        : _nisabPureSilverGrams * gramPrice999;

    setState(() {
      _enteredWeight = weight;
      _pureEquivalent999Grams = pureEquivalent;
      _marketValue = valueNow;
      _zakatAmount = zakatDue;
      _nisabCashValue = nisabCash;
      _eligible = reachedNisab;
      _message = reachedNisab
          ? 'بلغت الكمية النصاب (595 جرام فضة خالصة). الزكاة = 2.5% من القيمة.'
          : 'لم تبلغ الكمية النصاب الشرعي (595 جرام فضة خالصة). لا زكاة واجبة الآن.';
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
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _silverAccent),
      ),
    );
  }

  Widget _weightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوزن (جرام)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
          ),
          decoration: _inputDecoration(),
          onChanged: (_) {
            if (_zakatAmount != null || _message.isNotEmpty) {
              setState(_clearResult);
            }
          },
        ),
      ],
    );
  }

  Widget _caliberField(List<GoldCaliber> calibers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العيار',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<GoldCaliber>(
          key: ValueKey(_selectedCaliber?.name ?? 'none'),
          initialValue: _selectedCaliber,
          items: calibers
              .map(
                (c) => DropdownMenuItem<GoldCaliber>(
                  value: c,
                  child: Text(
                    '${c.name} (${c.purity})',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCaliber = value;
              _autoPricePerGram = value.pricePerGram;
              _clearResult();
            });
          },
          icon: const Icon(Icons.expand_more_rounded, color: _silverAccent),
          decoration: _inputDecoration(),
          dropdownColor: AppColors.cardDark,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _autoPriceField(String currency) {
    final auto = _autoPricePerGram;
    final hasPrice = auto != null && auto > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _silverAccent.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          const Icon(Icons.price_change_rounded,
              color: _silverAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعر (تلقائي لكل جرام)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPrice ? _money(auto, currency) : 'غير متوفر حاليًا',
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

  Widget _resultCard({
    required String currency,
  }) {
    final accent = _eligible ? _silverAccent : AppColors.error;
    final due = _zakatAmount ?? 0;

    Widget metric(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            AppColors.cardLight.withValues(alpha: 0.92),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نتيجة الحساب',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          metric(
            'الوزن المدخل',
            '${(_enteredWeight ?? 0).toStringAsFixed(2)} جرام',
          ),
          const SizedBox(height: 8),
          metric(
            'الوزن المكافئ عيار 999',
            '${(_pureEquivalent999Grams ?? 0).toStringAsFixed(2)} جرام',
          ),
          const SizedBox(height: 8),
          metric(
            'قيمة الفضة الحالية',
            _money(_marketValue ?? 0, currency),
          ),
          const SizedBox(height: 8),
          metric(
            'النصاب الشرعي',
            _nisabCashValue == null
                ? '${_nisabPureSilverGrams.toStringAsFixed(0)} جرام فضة خالصة'
                : '${_nisabPureSilverGrams.toStringAsFixed(0)} جرام ≈ ${_money(_nisabCashValue!, currency)}',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
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
                  '${due.toStringAsFixed(2)} $currency',
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

  Widget _noteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: _silverAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ملاحظة: هذا الحساب تقديري اعتمادًا على الوزن والعيار والسعر الحالي. في حال وجود ديون، مستحقات، عروض تجارة، أو عوامل فقهية أخرى، يُرجى مراجعة جهة الإفتاء المعتمدة لتحديد الحكم النهائي.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
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
    final currency = provider.selectedCurrency;
    final gramPrice999 = provider.currentGoldPrice?.gramPrice;
    final calibers = provider.calibers;

    _syncSelectedCaliber(calibers);

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
                  'أدخل الوزن، اختر العيار، وسيتم تعبئة السعر تلقائيًا. يتم تحويل الوزن عكسيًا إلى مكافئ عيار 999 ثم فحص النصاب (595 جرام).',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                _weightField(),
                const SizedBox(height: 10),
                _caliberField(calibers),
                const SizedBox(height: 10),
                _autoPriceField(currency),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _calculate(
                      caliber: _selectedCaliber,
                      gramPrice999: gramPrice999,
                      currency: currency,
                    ),
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
                    _marketValue != null &&
                    _pureEquivalent999Grams != null &&
                    _enteredWeight != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _resultCard(currency: currency),
                ],
                const SizedBox(height: 12),
                _noteCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
