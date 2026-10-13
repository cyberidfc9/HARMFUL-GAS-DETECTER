import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';
import '../../data/models/sensor_reading.dart';

class SensorCard extends StatelessWidget {
  final SensorReading reading;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.reading,
    this.onTap,
  });

  Color _getSensorAccent(SensorType type) {
    switch (type) {
      case SensorType.mq2:
        return AppColors.mq2Color;
      case SensorType.mq7:
        return AppColors.mq7Color;
      case SensorType.mq135:
        return AppColors.mq135Color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getSensorAccent(reading.type);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name, Target Gas & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            reading.type.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge.sensorState(
                    hasData: reading.hasData,
                    classification: reading.statusClassification,
                    isDarkMode: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  reading.type.targetGasLabel,
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main Numeric Reading & Measurement Unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        reading.displayValue,
                        maxLines: 1,
                        style: AppTypography.measurementLarge.copyWith(
                          color: reading.hasData
                              ? (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary)
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (reading.hasData)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reading.displayType,
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ),
                ],
              ),

              // Notice for MQ-7 if raw ADC
              if (reading.type == SensorType.mq7 &&
                  reading.displayType.toLowerCase().contains('adc')) ...[
                const SizedBox(height: 6),
                Text(
                  'Raw sensor response (Uncalibrated ADC)',
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),

              // Footer: Timestamp & Details Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            reading.timestamp != null
                                ? 'Updated ${DateFormatter.formatTime(reading.timestamp)}'
                                : 'No timestamp',
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
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
