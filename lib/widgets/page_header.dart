import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? margin;
  final TextAlign textAlign;

  const PageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.margin,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCentered = textAlign == TextAlign.center;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // العنوان
          Text(
            title,
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: textAlign,
          ),

          const SizedBox(height: 8),

          // خط فضّي صغير تحت العنوان (ديكور لطيف)
          Align(
            alignment: isCentered
                ? Alignment.center
                : AlignmentDirectional.centerStart,
            child: Container(
              width: 42,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFCFD8DC), // فضي فاتح
                    Color(0xFF90A4AE), // فضي أغمق
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
            ),
          ),

          // السطر الفرعي
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: textAlign,
            ),
          ],
        ],
      ),
    );
  }
}
