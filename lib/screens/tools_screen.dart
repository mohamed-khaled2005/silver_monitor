import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'calculator_screen.dart';
import 'zakat_calculator_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const Color _silverAccent = Color(0xFFC0C5D5);

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.responsivePadding(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              pagePadding.top,
              pagePadding.right,
              8,
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: _silverAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                splashBorderRadius: BorderRadius.circular(12),
                tabs: const [
                  Tab(text: 'الحاسبة'),
                  Tab(text: 'حاسبة الزكاة'),
                ],
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                CalculatorScreen(),
                ZakatCalculatorScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

