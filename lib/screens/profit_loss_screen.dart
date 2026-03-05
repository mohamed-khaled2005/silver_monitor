import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({Key? key}) : super(key: key);

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  static const Color _silverAccent = Color(0xFFC0C5D5);

  final TextEditingController _buyPrice = TextEditingController();
  final TextEditingController _sellPrice = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _fees = TextEditingController(text: '0');

  double? _netResult;
  double? _percentage;

  @override
  void dispose() {
    _buyPrice.dispose();
    _sellPrice.dispose();
    _quantity.dispose();
    _fees.dispose();
    super.dispose();
  }

  void _calculate() {
    final buy = double.tryParse(_buyPrice.text.trim()) ?? 0;
    final sell = double.tryParse(_sellPrice.text.trim()) ?? 0;
    final qty = double.tryParse(_quantity.text.trim()) ?? 0;
    final fees = double.tryParse(_fees.text.trim()) ?? 0;

    if (buy <= 0 || sell <= 0 || qty <= 0) {
      setState(() {
        _netResult = null;
        _percentage = null;
      });
      return;
    }

    final cost = (buy * qty) + fees;
    final revenue = sell * qty;
    final net = revenue - cost;
    final pct = (net / cost) * 100;

    setState(() {
      _netResult = net;
      _percentage = pct;
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
            if (_netResult == null && _percentage == null) return;
            setState(() {
              _netResult = null;
              _percentage = null;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.responsivePadding(context);
    final profit = (_netResult ?? 0) >= 0;

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'الربح والخسارة'),
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
                  'أدخل سعر الشراء وسعر البيع والكمية والرسوم لحساب صافي الربح أو الخسارة بدقة.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _inputField(controller: _buyPrice, label: 'سعر الشراء'),
                const SizedBox(height: 10),
                _inputField(controller: _sellPrice, label: 'سعر البيع'),
                const SizedBox(height: 10),
                _inputField(controller: _quantity, label: 'الكمية'),
                const SizedBox(height: 10),
                _inputField(controller: _fees, label: 'الرسوم / العمولة'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _silverAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'احسب الآن',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (_netResult != null && _percentage != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: profit ? AppColors.success : AppColors.error,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          profit
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: profit ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                profit
                                    ? 'نتيجة الصفقة: ربح'
                                    : 'نتيجة الصفقة: خسارة',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: profit
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _netResult!.toStringAsFixed(2),
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_percentage!.toStringAsFixed(2)}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
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
