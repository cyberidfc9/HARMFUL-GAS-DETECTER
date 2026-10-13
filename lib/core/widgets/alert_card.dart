import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../../data/models/alert_item.dart';

class AlertCard extends StatelessWidget {
  final AlertItem alert;

  const AlertCard({
    super.key,
    required this.alert,
  });

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.statusCritical;
      case AlertSeverity.warning:
        return AppColors.statusWarning;
      case AlertSeverity.info:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sevColor = _getSeverityColor(alert.severity);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert.resolved
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : sevColor.withValues(alpha: 0.5),
          width: alert.resolved ? 0.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Severity badge, Sensor Tag & Resolution status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity.label.toUpperCase(),
                        style: AppTypography.badge.copyWith(
                          color: sevColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (alert.sensorType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alert.sensorType!.displayName,
                          style: AppTypography.badge.copyWith(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (alert.resolved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: AppColors.statusNormal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Resolved',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusNormal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: sevColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Message
          Text(
            alert.message,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),

          // Recorded reading if present
          if (alert.recordedValue != null) ...[
            const SizedBox(height: 6),
            Text(
              'Recorded: ${alert.recordedValue} ${alert.measurementType ?? "Raw ADC"}',
              style: AppTypography.caption.copyWith(
                color: textSecondary,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),

          // Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.formatShortDateTime(alert.timestamp),
                style: AppTypography.caption.copyWith(
                  color: textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Device: ${alert.deviceId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
