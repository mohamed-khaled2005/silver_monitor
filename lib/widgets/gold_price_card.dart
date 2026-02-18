import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GoldPriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String change;
  final String changePercent;
  final bool isPositive;
  final String currency;

  const GoldPriceCard({
    Key? key,
    required this.title,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.isPositive,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // 🔹 جراديانت داكن فضّي
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1C1F26), // رمادي داكن مزرق
            Color(0xFF101218), // داكن جدًا للخلفية
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // دائرة الأيقونة بستايل فضّي داكن
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFCFD8DC), // فضي فاتح
                  Color(0xFF90A4AE), // فضي أغمق
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.cardDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // العنوان والسعر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مثلاً: "سعر أونصة الفضة" / "سعر جرام الفضة"
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$price $currency',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          // التغيير والنسبة
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'التغيير',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: changeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    change,
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                changePercent,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
