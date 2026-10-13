import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../data/models/device_state.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.showDot = false,
  });

  factory StatusBadge.fromConnectionStatus(
    DeviceConnectionStatus status, {
    required bool isDarkMode,
  }) {
    switch (status) {
      case DeviceConnectionStatus.online:
        return StatusBadge(
          label: 'ONLINE',
          foreground: AppColors.statusNormal,
          background: isDarkMode
              ? AppColors.statusNormalBgDark.withValues(alpha: 0.4)
              : AppColors.statusNormalBgLight,
          showDot: true,
        );
      case DeviceConnectionStatus.stale:
        return StatusBadge(
          label: 'STALE DATA',
          foreground: AppColors.statusWarning,
          background: isDarkMode
              ? AppColors.statusWarningBgDark.withValues(alpha: 0.4)
              : AppColors.statusWarningBgLight,
          showDot: true,
        );
      case DeviceConnectionStatus.offline:
        return StatusBadge(
          label: 'OFFLINE',
          foreground: AppColors.statusOffline,
          background: isDarkMode
              ? AppColors.statusOfflineBgDark.withValues(alpha: 0.5)
              : AppColors.statusOfflineBgLight,
          showDot: true,
        );
      case DeviceConnectionStatus.unknown:
        return StatusBadge(
          label: 'WAITING FOR DEVICE',
          foreground: AppColors.statusOffline,
          background: isDarkMode
              ? AppColors.statusOfflineBgDark.withValues(alpha: 0.4)
              : AppColors.statusOfflineBgLight,
          showDot: true,
        );
    }
  }

  factory StatusBadge.sensorState({
    required bool hasData,
    String? classification,
    required bool isDarkMode,
  }) {
    if (!hasData) {
      return StatusBadge(
        label: 'NO DATA',
        foreground: AppColors.statusOffline,
        background: isDarkMode
            ? AppColors.statusOfflineBgDark.withValues(alpha: 0.4)
            : AppColors.statusOfflineBgLight,
        showDot: false,
      );
    }

    final lower = classification?.toLowerCase() ?? 'active';
    if (lower.contains('crit') ||
        lower.contains('danger') ||
        lower.contains('high') ||
        lower.contains('bad') ||
        lower.contains('poor') ||
        lower.contains('severe')) {
      return StatusBadge(
        label: classification != null ? classification.toUpperCase() : 'BAD',
        foreground: AppColors.statusCritical,
        background: isDarkMode
            ? AppColors.statusCriticalBgDark.withValues(alpha: 0.4)
            : AppColors.statusCriticalBgLight,
        icon: Icons.warning_amber_rounded,
      );
    }

    if (lower.contains('warn') ||
        lower.contains('elevated') ||
        lower.contains('med') ||
        lower.contains('mod')) {
      return StatusBadge(
        label: classification != null ? classification.toUpperCase() : 'MEDIUM',
        foreground: AppColors.statusWarning,
        background: isDarkMode
            ? AppColors.statusWarningBgDark.withValues(alpha: 0.4)
            : AppColors.statusWarningBgLight,
        icon: Icons.info_outline,
      );
    }

    return StatusBadge(
      label: classification != null ? classification.toUpperCase() : 'GOOD',
      foreground: AppColors.statusNormal,
      background: isDarkMode
          ? AppColors.statusNormalBgDark.withValues(alpha: 0.4)
          : AppColors.statusNormalBgLight,
      showDot: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(
              color: foreground,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
