import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _weightController = TextEditingController();

  bool _isOunce = false; // false = جرام، true = أونصة
  double? _result;

  // علشان نعرف إمتى العملة اتغيرت ونمسح النتيجة تلقائي
  String? _lastCurrencyCode;

  // 🎨 ألوان فضية خاصة بالشاشة دي
  static const Color _silverAccent = Color(0xFFC0C5D5);
  static const Color _silverAccentDark = Color(0xFF9FA6B5);

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  /// حساب بالضغط على الزر (مع رسائل خطأ واضحة)
  void _calculate() {
    final text = _weightController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل وزن صحيح أولاً'),
        ),
      );
      return;
    }

    final weight = double.tryParse(text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('قيمة الوزن غير صحيحة، حاول مرة أخرى'),
        ),
      );
      return;
    }

    final provider = Provider.of<GoldProvider>(context, listen: false);
    final goldPrice = provider.currentGoldPrice;

    if (goldPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات أسعار حالياً، حدّث الأسعار أولاً'),
        ),
      );
      return;
    }

    final unitPrice = _isOunce ? goldPrice.ouncePrice : goldPrice.gramPrice;

    setState(() {
      _result = unitPrice * weight;
    });

    // قفل الكيبورد بعد الحساب (اختياري)
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoldProvider>(context);
    final padding = Responsive.responsivePadding(context);

    // 👇 هنا نراقب تغيير العملة:
    // أول مرة نخزن الكود، بعد كده لو اتغير نمسح الوزن والنتيجة
    if (_lastCurrencyCode == null) {
      _lastCurrencyCode = provider.selectedCurrency;
    } else if (_lastCurrencyCode != provider.selectedCurrency) {
      _lastCurrencyCode = provider.selectedCurrency;
      _weightController.text = '';
      _result = null;
    }

    final currentUnitPrice = provider.currentGoldPrice == null
        ? null
        : (_isOunce
            ? provider.currentGoldPrice!.ouncePrice
            : provider.currentGoldPrice!.gramPrice);

    final currentUnitLabel = _isOunce ? 'سعر الأونصة' : 'سعر الجرام';

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'الحاسبة'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.35 * 255).toInt()),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدخل وزن الفضة واختر الوحدة لحساب القيمة حسب آخر سعر متاح:',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                  ),
                  onChanged: (value) {
                    // أي تغيير في الوزن يمسح النتيجة → لازم يضغط "احسب الآن" من جديد
                    setState(() {
                      _result = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'الوزن',
                    labelStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Tajawal',
                    ),
                    hintText: 'مثال: 10',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Tajawal',
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _silverAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // زر الجرام
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isOunce = false;
                            // تغيير الوحدة يمسح النتيجة → لازم يعيد الحساب يدويًا
                            _result = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: !_isOunce
                                ? _silverAccent.withAlpha((0.18 * 255).toInt())
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_isOunce ? _silverAccent : Colors.white12,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.scale_rounded,
                                size: 20,
                                color: !_isOunce
                                    ? _silverAccentDark
                                    : Colors.white70,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'جرام',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      !_isOunce ? Colors.white : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // زر الأونصة
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isOunce = true;
                            // تغيير الوحدة يمسح النتيجة → لازم يعيد الحساب يدويًا
                            _result = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _isOunce
                                ? _silverAccent.withAlpha((0.18 * 255).toInt())
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isOunce ? _silverAccent : Colors.white12,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_rounded,
                                size: 20,
                                color: _isOunce
                                    ? _silverAccentDark
                                    : Colors.white70,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'أونصة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isOunce ? Colors.white : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (currentUnitPrice != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.price_change_outlined,
                          color: _silverAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$currentUnitLabel: ${currentUnitPrice.toStringAsFixed(2)} ${provider.selectedCurrency}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _silverAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'احسب الآن',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cardDark,
                          AppColors.cardLight.withAlpha((0.85 * 255).toInt()),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _silverAccent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                          color: _silverAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'النتيجة بعد الحساب',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_result!.toStringAsFixed(2)} ${provider.selectedCurrency}',
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: _silverAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _result = null;
                              _weightController.clear();
                            });
                          },
                          tooltip: 'مسح النتيجة',
                        ),
                      ],
                    ),
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
