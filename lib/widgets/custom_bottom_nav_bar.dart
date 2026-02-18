import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  static const String _homeLabel =
      '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629';
  static const String _calculatorLabel =
      '\u0627\u0644\u062d\u0627\u0633\u0628\u0629';
  static const String _calibersLabel =
      '\u0627\u0644\u0639\u064a\u0627\u0631\u0627\u062a';
  static const String _bullionsLabel =
      '\u0627\u0644\u0633\u0628\u0627\u0626\u0643';
  static const String _ourAppsLabel =
      '\u062a\u0637\u0628\u064a\u0642\u0627\u062a\u0646\u0627';
  static const String _aboutLabel = '\u0639\u0646\u0627';
  static const String _whoWeAreLabel = '\u0645\u0646 \u0646\u062d\u0646';
  static const String _contactUsLabel =
      '\u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0628\u0646\u0627';
  static const Color _silverAccent = Color(0xFFC0C5D5);

  BoxDecoration _sheetDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF0F1116),
          Color(0xFF181B22),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white10, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 18,
          spreadRadius: 1.2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final int displayIndex = _mapScreenIndexToBarIndex(widget.currentIndex);

    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F1116),
            Color(0xFF181B22),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(
          color: Colors.white10,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 22,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: BottomNavigationBar(
          currentIndex: displayIndex,
          onTap: (barIndex) {
            if (barIndex <= 4) {
              widget.onTap(barIndex);
              return;
            }
            _openAboutMenu(context);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _silverAccent,
          unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.8),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
          ),
          showUnselectedLabels: true,
          items: [
            _buildNavItem(
              outlineIcon: Icons.home_outlined,
              filledIcon: Icons.home,
              label: _homeLabel,
              isSelected: widget.currentIndex == 0,
            ),
            _buildNavItem(
              outlineIcon: Icons.calculate_outlined,
              filledIcon: Icons.calculate,
              label: _calculatorLabel,
              isSelected: widget.currentIndex == 1,
            ),
            _buildNavItem(
              outlineIcon: Icons.diamond_outlined,
              filledIcon: Icons.diamond,
              label: _calibersLabel,
              isSelected: widget.currentIndex == 2,
            ),
            _buildNavItem(
              outlineIcon: Icons.auto_awesome_outlined,
              filledIcon: Icons.auto_awesome,
              label: _bullionsLabel,
              isSelected: widget.currentIndex == 3,
            ),
            _buildNavItem(
              outlineIcon: Icons.apps_outlined,
              filledIcon: Icons.apps,
              label: _ourAppsLabel,
              isSelected: widget.currentIndex == 4,
            ),
            _buildNavItem(
              outlineIcon: Icons.info_outline,
              filledIcon: Icons.info,
              label: _aboutLabel,
              isSelected: widget.currentIndex == 5 || widget.currentIndex == 6,
            ),
          ],
        ),
      ),
    );
  }

  int _mapScreenIndexToBarIndex(int screenIndex) {
    if (screenIndex <= 4) return screenIndex;
    return 5;
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: AppAnimations.buttonAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: AnimatedSwitcher(
          duration: AppAnimations.buttonAnimation,
          child: Icon(
            isSelected ? filledIcon : outlineIcon,
            key: ValueKey('${label}_${isSelected ? 'filled' : 'outline'}'),
            size: 22,
          ),
        ),
      ),
      label: label,
    );
  }

  void _openAboutMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                decoration: _sheetDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 62,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _menuTile(
                      title: _whoWeAreLabel,
                      icon: Icons.info_outline_rounded,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onTap(5);
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.textSecondary.withValues(alpha: 0.16),
                    ),
                    _menuTile(
                      title: _contactUsLabel,
                      icon: Icons.contact_page_outlined,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onTap(6);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _silverAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: _silverAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    height: 1.1,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
