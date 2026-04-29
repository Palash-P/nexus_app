import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeStatus { ready, processing, failed, pending }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      BadgeStatus.ready    => (AppColors.success, 'Ready'),
      BadgeStatus.processing => (AppColors.warning, 'Processing'),
      BadgeStatus.failed   => (AppColors.error, 'Failed'),
      BadgeStatus.pending  => (AppColors.textMuted, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$1.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: config.$1,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? config.$2,
            style: AppTextStyles.caption.copyWith(
              color: config.$1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}