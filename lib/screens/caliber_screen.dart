import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../animations/fade_animation.dart';
import '../widgets/app_section_header.dart';

class CaliberScreen extends StatefulWidget {
  @override
  _CaliberScreenState createState() => _CaliberScreenState();
}

class _CaliberScreenState extends State<CaliberScreen> {
  bool _showOunce = false; // false = لكل جرام، true = لكل أونصة

  // 🎨 ألوان فضة خاصة بالصفحة دي فقط
  static const Color _silverAccent = Color(0xFFC0C5D5);
  static const Color _silverAccentDark = Color(0xFF9FA6B5);
  static const LinearGradient _silverGradient = LinearGradient(
    colors: [
      Color(0xFFE6E9F0),
      Color(0xFFCFD4E1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
            const AppSectionHeader(title: 'العيارات'),
            const SizedBox(height: 16),
            _buildUnitToggle(),
            const SizedBox(height: 16),
            _buildCaliberList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showOunce = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showOunce ? Colors.transparent : _silverAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'لكل جرام',
                    style: TextStyle(
                      color:
                          _showOunce ? AppColors.textSecondary : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showOunce = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showOunce ? _silverAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'لكل أونصة',
                    style: TextStyle(
                      color:
                          _showOunce ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaliberList(GoldProvider provider) {
    return Column(
      children: provider.calibers.asMap().entries.map((entry) {
        final index = entry.key;
        final caliber = entry.value;

        final double pricePerUnit =
            _showOunce ? caliber.pricePerGram * 31.1035 : caliber.pricePerGram;

        final bool isMainCard = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isMainCard
                ? _silverGradient
                : const LinearGradient(
                    colors: [
                      AppColors.cardDark,
                      AppColors.cardLight,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildCaliberIcon(index),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👇 تصغير حجم خط اسم العيار
                    Text(
                      caliber.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 15,
                        color:
                            isMainCard ? Colors.black : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'نقاء ${caliber.purity}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isMainCard
                            ? Colors.black54
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 👇 تصغير حجم خط السعر
                  Text(
                    pricePerUnit.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isMainCard ? Colors.black : _silverAccent,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    _showOunce
                        ? '${provider.selectedCurrency} / أونصة'
                        : '${provider.selectedCurrency} / جرام',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          isMainCard ? Colors.black54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCaliberIcon(int index) {
    final icons = [
      Icons.auto_awesome,
      Icons.workspace_premium,
      Icons.star,
      Icons.grade,
      Icons.diamond,
      Icons.stars,
      Icons.military_tech,
    ];

    // لو عدد العيارات أكبر من الليست، نلف على الأيقونات
    final iconData = icons[index % icons.length];

    final bool isMain = index == 0;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isMain ? Colors.white : _silverAccent.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: isMain ? Colors.transparent : _silverAccentDark,
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        color: _silverAccentDark,
        size: 24,
      ),
    );
  }
}
