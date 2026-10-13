import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';

class DataFreshnessIndicator extends StatelessWidget {
  final DateTime? lastSeen;
  final bool isOffline;

  const DataFreshnessIndicator({
    super.key,
    required this.lastSeen,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color dotColor;
    String statusText;

    if (lastSeen == null) {
      dotColor = AppColors.statusOffline;
      statusText = 'No data';
    } else {
      final diff = DateTime.now().difference(lastSeen!).inSeconds;
      if (isOffline || diff > 180) {
        dotColor = AppColors.statusOffline;
        statusText = 'Offline • ${DateFormatter.formatRelative(lastSeen)}';
      } else if (diff > 60) {
        dotColor = AppColors.statusWarning;
        statusText = 'Stale • ${DateFormatter.formatRelative(lastSeen)}';
      } else {
        dotColor = AppColors.statusNormal;
        statusText = 'Live • ${DateFormatter.formatRelative(lastSeen)}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: AppTypography.monoLabel.copyWith(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
