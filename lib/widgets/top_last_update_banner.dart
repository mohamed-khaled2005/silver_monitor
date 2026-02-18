import 'package:flutter/material.dart';

import '../utils/constants.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class TopLastUpdateBanner extends StatelessWidget {
  const TopLastUpdateBanner({
    super.key,
    required this.lastUpdatedUtc,
    required this.isLoading,
  });

  final DateTime? lastUpdatedUtc;
  final bool isLoading;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatLocalDateTime(DateTime localDateTime) {
    return '${localDateTime.year}/${_twoDigits(localDateTime.month)}/${_twoDigits(localDateTime.day)} '
        '${_twoDigits(localDateTime.hour)}:${_twoDigits(localDateTime.minute)}';
  }

  String _formatGmtOffset(DateTime localDateTime) {
    final offset = localDateTime.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs();
    final minutes = offset.inMinutes.abs() % 60;

    if (minutes == 0) {
      return 'GMT$sign$hours';
    }
    return 'GMT$sign$hours:${_twoDigits(minutes)}';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? localDateTime = lastUpdatedUtc?.toLocal();

    final String displayText = localDateTime == null
        ? '--'
        : '${_formatLocalDateTime(localDateTime)} (${_formatGmtOffset(localDateTime)})';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 16,
            color: _silverAccent,
          ),
          const SizedBox(width: 8),
          Text(
            'آخر تحديث:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('banner_loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(_silverAccent),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('banner_idle'),
                    width: 16,
                    height: 16,
                  ),
          ),
        ],
      ),
    );
  }
}
