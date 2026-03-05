import 'package:flutter/material.dart';

import '../utils/constants.dart';

const Color _silverAccent = Color(0xFFC0C5D5);

class TopLastUpdateBanner extends StatelessWidget {
  const TopLastUpdateBanner({
    super.key,
    required this.lastUpdatedUtc,
  });

  final DateTime? lastUpdatedUtc;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatLocalDateTime(DateTime localDateTime) {
    return '${localDateTime.year}/${_twoDigits(localDateTime.month)}/${_twoDigits(localDateTime.day)} '
        '${_twoDigits(localDateTime.hour)}:${_twoDigits(localDateTime.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? localDateTime = lastUpdatedUtc?.toLocal();

    final String displayText =
        localDateTime == null ? '--' : _formatLocalDateTime(localDateTime);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            spreadRadius: 0.0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 15,
            color: _silverAccent,
          ),
          const SizedBox(width: 6),
          Text(
            '\u0622\u062E\u0631 \u062A\u062D\u062F\u064A\u062B:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 10.8,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
