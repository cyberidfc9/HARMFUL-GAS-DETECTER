import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sensor_line_chart.dart';
import '../../../core/widgets/multi_sensor_line_chart.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/historical_timeline_list.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/analytics_summary.dart';
import '../providers/analytics_providers.dart';
import '../../dashboard/providers/device_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final filter = ref.watch(selectedFilterProvider);
    final selectedRange = ref.watch(selectedTimeRangeProvider);
    final singleAnalytics = ref.watch(analyticsSummaryProvider);
    final allAnalytics = ref.watch(allSensorsAnalyticsProvider);
    final records = ref.watch(realtimeHistoryProvider);
    final deviceStateAsync = ref.watch(deviceStateStreamProvider);
    final alertsAsync = ref.watch(alertsStreamProvider);

    // Calculate alerts during selected time range
    final now = DateTime.now();
    final cutoff = now.subtract(selectedRange.duration);
    final periodAlertCount = (alertsAsync.value ?? [])
        .where((a) =>
            (filter.sensorType == null || a.sensorType == filter.sensorType) &&
            (a.timestamp.isAfter(cutoff) || a.timestamp.isAtSameMomentAs(cutoff)))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & History'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Sensor Segmented Selector: All Sensors, MQ-2, MQ-7, MQ-135
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: AnalyticsSensorFilter.values.map((f) {
                final isSelected = filter == f;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedFilterProvider.notifier).setFilter(f);
                      if (f.sensorType != null) {
                        ref
                            .read(selectedSensorProvider.notifier)
                            .setSensor(f.sensorType!);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.lightSurfaceElevated)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          f.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary)
                                : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Time Range Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimeRange.values.map((range) {
                final isSelected = selectedRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(range.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedTimeRangeProvider.notifier).setRange(range);
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
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Main Graph
          if (filter == AnalyticsSensorFilter.all) ...[
            MultiSensorLineChart(
              pointsBySensor: {
                SensorType.mq2: allAnalytics[SensorType.mq2]?.points ?? [],
                SensorType.mq7: allAnalytics[SensorType.mq7]?.points ?? [],
                SensorType.mq135: allAnalytics[SensorType.mq135]?.points ?? [],
              },
              timeRange: selectedRange,
            ),
          ] else ...[
            SensorLineChart(
              points: singleAnalytics.points,
              sensorType: filter.sensorType!,
              timeRange: selectedRange,
              unit: singleAnalytics.unit,
            ),
          ],

          const SizedBox(height: 16),

          // Metrics Section
          if (filter == AnalyticsSensorFilter.all) ...[
            // All Sensors: 3 Sensor Summary Cards
            _AllSensorsSummaryGrid(
              allAnalytics: allAnalytics,
              deviceState: deviceStateAsync.value,
              isDark: isDark,
            ),
          ] else ...[
            // Single Sensor Analytics Grid: Min, Max, Average, Valid Count, Trend, Period Alerts
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Min Reading',
                    value: singleAnalytics.min != null
                        ? singleAnalytics.min!.toString()
                        : '--',
                    unit: singleAnalytics.min != null ? singleAnalytics.unit : null,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Max Reading',
                    value: singleAnalytics.max != null
                        ? singleAnalytics.max!.toString()
                        : '--',
                    unit: singleAnalytics.max != null ? singleAnalytics.unit : null,
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
                    value: singleAnalytics.average != null
                        ? singleAnalytics.average!.toStringAsFixed(1)
                        : '--',
                    unit: singleAnalytics.average != null
                        ? singleAnalytics.unit
                        : null,
                    icon: Icons.calculate_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Valid Readings',
                    value: singleAnalytics.readingCount.toString(),
                    icon: Icons.data_usage_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Calculated Trend',
                    value: singleAnalytics.trend.label,
                    trailing: singleAnalytics.percentageChange != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: singleAnalytics.trend ==
                                      TrendDirection.increasing
                                  ? AppColors.statusWarningBgLight
                                  : AppColors.statusNormalBgLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${singleAnalytics.percentageChange! > 0 ? "+" : ""}${singleAnalytics.percentageChange!.toStringAsFixed(1)}%',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: singleAnalytics.trend ==
                                        TrendDirection.increasing
                                    ? AppColors.statusWarning
                                    : AppColors.statusNormal,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Period Alerts',
                    value: periodAlertCount.toString(),
                    icon: Icons.notifications_none_rounded,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Real-time Historical Timeline Section
          HistoricalTimelineList(
            records: records,
            sensorFilter: filter.sensorType,
            maxItems: 40,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AllSensorsSummaryGrid extends StatelessWidget {
  final Map<SensorType, AnalyticsSummary> allAnalytics;
  final dynamic deviceState;
  final bool isDark;

  const _AllSensorsSummaryGrid({
    required this.allAnalytics,
    required this.deviceState,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SensorAnalyticsRowCard(
          sensorType: SensorType.mq2,
          summary: allAnalytics[SensorType.mq2],
          reading: deviceState?.sensors[SensorType.mq2],
          accentColor: AppColors.mq2Color,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _SensorAnalyticsRowCard(
          sensorType: SensorType.mq7,
          summary: allAnalytics[SensorType.mq7],
          reading: deviceState?.sensors[SensorType.mq7],
          accentColor: AppColors.mq7Color,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _SensorAnalyticsRowCard(
          sensorType: SensorType.mq135,
          summary: allAnalytics[SensorType.mq135],
          reading: deviceState?.sensors[SensorType.mq135],
          accentColor: AppColors.mq135Color,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SensorAnalyticsRowCard extends StatelessWidget {
  final SensorType sensorType;
  final AnalyticsSummary? summary;
  final SensorReading? reading;
  final Color accentColor;
  final bool isDark;

  const _SensorAnalyticsRowCard({
    required this.sensorType,
    required this.summary,
    required this.reading,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final curVal = reading?.displayValue ?? '--';
    final unit = summary?.unit ?? (sensorType == SensorType.mq135 ? 'AQI' : 'ppm');
    final minVal = summary?.min != null ? summary!.min.toString() : '--';
    final maxVal = summary?.max != null ? summary!.max.toString() : '--';
    final avgVal = summary?.average != null
        ? summary!.average!.toStringAsFixed(1)
        : '--';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sensorType.displayName,
                      style: AppTypography.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '(${sensorType.targetGasLabel})',
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
              StatusBadge.sensorState(
                hasData: reading?.hasData == true,
                classification: reading?.statusClassification,
                isDarkMode: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$curVal $unit',
                        style: AppTypography.measurementSmall.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'MIN / MAX',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '$minVal / $maxVal',
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'AVERAGE',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$avgVal $unit',
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
