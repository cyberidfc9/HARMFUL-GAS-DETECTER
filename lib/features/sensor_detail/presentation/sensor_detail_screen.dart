import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/sensor_line_chart.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/alert_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/historical_timeline_list.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/analytics_summary.dart';
import '../../dashboard/providers/device_providers.dart';
import '../../analytics/providers/analytics_providers.dart';

class SensorDetailScreen extends ConsumerStatefulWidget {
  final SensorType sensorType;

  const SensorDetailScreen({
    super.key,
    required this.sensorType,
  });

  @override
  ConsumerState<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends ConsumerState<SensorDetailScreen> {
  TimeRange _timeRange = TimeRange.twentyFourHours;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final deviceStateAsync = ref.watch(deviceStateStreamProvider);
    final alertsAsync = ref.watch(alertsStreamProvider);

    final reading = deviceStateAsync.value?.sensors[widget.sensorType] ??
        SensorReading(type: widget.sensorType, valid: false);

    final historyList = ref.watch(realtimeHistoryProvider);
    final analytics = AnalyticsSummary.calculate(
      sensorType: widget.sensorType,
      timeRange: _timeRange,
      records: historyList,
    );

    // Sensor-specific alerts
    final sensorAlerts = (alertsAsync.value ?? [])
        .where((a) => a.sensorType == widget.sensorType)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sensorType.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Card with Main Reading
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sensorType.targetGasLabel,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.sensorType.displayName,
                            style: AppTypography.caption.copyWith(
                              color: textSecondary,
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
                const SizedBox(height: 20),
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
                            fontSize: 44,
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
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reading.displayType,
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Sensor Technical Specifics
                const SizedBox(height: 12),
                Text(
                  widget.sensorType.technicalRole,
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),

                // MQ-7 Calibrated Distinction Note
                if (widget.sensorType == SensorType.mq7) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reading.calibratedValue != null
                                ? 'Calibrated CO: ${reading.calibratedValue} ppm'
                                : 'Measurement is displayed as Raw ADC response. Calibrated ppm is not asserted without verified hardware calibration.',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reading.timestamp != null
                            ? 'Last measurement at ${DateFormatter.formatTime(reading.timestamp)}'
                            : 'No recorded timestamp',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Time Range Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HISTORICAL TIMELINE',
                style: AppTypography.caption.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TimeRange.values.map((range) {
                    final isSelected = _timeRange == range;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(range.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _timeRange = range);
                          }
                        },
                        labelStyle: AppTypography.caption.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        ),
                        selectedColor: AppColors.accent,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Line Chart
          SensorLineChart(
            points: analytics.points,
            sensorType: widget.sensorType,
            timeRange: _timeRange,
            unit: reading.displayType,
          ),

          const SizedBox(height: 16),

          // Stats Grid: Min, Max, Average, Trend
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Min',
                  value: analytics.min != null
                      ? analytics.min!.toString()
                      : '--',
                  unit: analytics.min != null ? reading.displayType : null,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Max',
                  value: analytics.max != null
                      ? analytics.max!.toString()
                      : '--',
                  unit: analytics.max != null ? reading.displayType : null,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Average',
                  value: analytics.average != null
                      ? analytics.average!.toStringAsFixed(1)
                      : '--',
                  unit: analytics.average != null ? reading.displayType : null,
                  icon: Icons.calculate_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Trend',
                  value: analytics.trend.label,
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${analytics.readingCount} pts',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Real-time Historical Timeline for this sensor
          HistoricalTimelineList(
            records: historyList,
            sensorFilter: widget.sensorType,
            maxItems: 30,
          ),

          const SizedBox(height: 24),

          // Sensor Alert History
          Text(
            'ALERT HISTORY FOR ${widget.sensorType.displayName}',
            style: AppTypography.caption.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (sensorAlerts.isEmpty)
            EmptyStateView.noAlerts()
          else
            ...sensorAlerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AlertCard(alert: alert),
                )),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
