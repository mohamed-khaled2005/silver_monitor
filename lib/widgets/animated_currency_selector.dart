import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AnimatedCurrencySelector extends StatefulWidget {
  final Map<String, dynamic> currency;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedCurrencySelector({
    Key? key,
    required this.currency,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  _AnimatedCurrencySelectorState createState() =>
      _AnimatedCurrencySelectorState();
}

class _AnimatedCurrencySelectorState extends State<AnimatedCurrencySelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // لو البداية مختارة فعلاً، خليه في حالة مفعّلة
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedCurrencySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                // نستخدم جراديانت الذهب الموجود حاليًا في الثيم
                gradient: widget.isSelected ? AppColors.goldGradient : null,
                color: widget.isSelected ? null : AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                border: Border.all(
                  color: AppColors.primaryGold
                      .withOpacity(_borderAnimation.value * 0.5),
                  width: 2,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGold.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // دائرة لعرض العلم أو رمز العملة
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Colors.white
                          : AppColors.cardLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.currency['flag'] ?? widget.currency['symbol'],
                        style: TextStyle(
                          fontSize: widget.currency['flag'] != null ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.currency['name'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isSelected
                          ? Colors.black
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.currency['code'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: widget.isSelected
                          ? Colors.black54
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (widget.isSelected) ...[
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.black,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
