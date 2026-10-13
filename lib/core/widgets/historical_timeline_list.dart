import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';
import '../../data/models/sensor_reading.dart';
import '../../data/models/historical_record.dart';

class HistoricalTimelineList extends StatelessWidget {
  final List<HistoricalRecord> records;
  final SensorType? sensorFilter;
  final int maxItems;

  const HistoricalTimelineList({
    super.key,
    required this.records,
    this.sensorFilter,
    this.maxItems = 50,
  });

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 15) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    // Filter records with valid data for the filter
    final displayRecords = records.where((r) {
      if (sensorFilter == null) {
        return r.mq2 != null || r.mq7 != null || r.mq135 != null;
      }
      return r.getValueFor(sensorFilter!) != null;
    }).toList();

    // Sort newest first
    displayRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final limited = displayRecords.take(maxItems).toList();

    if (limited.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 28, color: textSecondary),
            const SizedBox(height: 8),
            Text(
              'No timeline records yet',
              style: AppTypography.cardTitle.copyWith(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Historical records will stream here as the ESP32 logs real sensor telemetry.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: textTertiary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live streaming header badge
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.statusNormal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REAL-TIME TIMELINE STREAM',
                    style: AppTypography.caption.copyWith(
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                '${limited.length} entries',
                style: AppTypography.caption.copyWith(
                  color: textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Timeline Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limited.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final record = limited[index];
            final isLatest = index == 0;
            final formattedTime = DateFormatter.formatTime(record.timestamp);
            final relTime = _formatRelativeTime(record.timestamp);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLatest
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isLatest ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isLatest ? AppColors.accent : textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                formattedTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.monoLabel.copyWith(
                                  fontSize: 12,
                                  fontWeight: isLatest ? FontWeight.w600 : FontWeight.w500,
                                  color: isLatest
                                      ? (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary)
                                      : textSecondary,
                                ),
                              ),
                            ),
                            if (isLatest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LATEST',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        relTime,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: textTertiary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Real sensor readings for this timeline point
                  if (sensorFilter == null) ...[
                    // All sensors view
                    Row(
                      children: [
                        // MQ-2
                        Expanded(
                          child: _SensorTimelineChip(
                            label: 'MQ-2',
                            value: record.getFormattedValue(SensorType.mq2),
                            unit: record.getUnitFor(SensorType.mq2),
                            status: record.getStatusFor(SensorType.mq2),
                            color: AppColors.mq2Color,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // MQ-7
                        Expanded(
                          child: _SensorTimelineChip(
                            label: 'MQ-7',
                            value: record.getFormattedValue(SensorType.mq7),
                            unit: record.getUnitFor(SensorType.mq7),
                            status: record.getStatusFor(SensorType.mq7),
                            color: AppColors.mq7Color,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // MQ-135
                        Expanded(
                          child: _SensorTimelineChip(
                            label: 'MQ-135',
                            value: record.getFormattedValue(SensorType.mq135),
                            unit: record.getUnitFor(SensorType.mq135),
                            status: record.getStatusFor(SensorType.mq135),
                            color: AppColors.mq135Color,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Focused single sensor view
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getSensorColor(sensorFilter!),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${record.getFormattedValue(sensorFilter!)} ${record.getUnitFor(sensorFilter!)}',
                                    style: AppTypography.measurementSmall.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge.sensorState(
                          hasData: record.getValueFor(sensorFilter!) != null,
                          classification: record.getStatusFor(sensorFilter!),
                          isDarkMode: isDark,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getSensorColor(SensorType type) {
    switch (type) {
      case SensorType.mq2:
        return AppColors.mq2Color;
      case SensorType.mq7:
        return AppColors.mq7Color;
      case SensorType.mq135:
        return AppColors.mq135Color;
    }
  }
}

class _SensorTimelineChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? status;
  final Color color;
  final bool isDark;

  const _SensorTimelineChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Color badgeBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceElevated;
    Color badgeText = textSecondary;

    if (status != null) {
      final s = status!.toLowerCase();
      if (s.contains('high') || s.contains('bad') || s.contains('danger')) {
        badgeBg = isDark
            ? AppColors.statusCriticalBgDark.withValues(alpha: 0.5)
            : AppColors.statusCriticalBgLight;
        badgeText = AppColors.statusCritical;
      } else if (s.contains('med') || s.contains('warn')) {
        badgeBg = isDark
            ? AppColors.statusWarningBgDark.withValues(alpha: 0.5)
            : AppColors.statusWarningBgLight;
        badgeText = AppColors.statusWarning;
      } else {
        badgeBg = isDark
            ? AppColors.statusNormalBgDark.withValues(alpha: 0.4)
            : AppColors.statusNormalBgLight;
        badgeText = AppColors.statusNormal;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value $unit',
              style: AppTypography.monoLabel.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              status ?? 'NORMAL',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
