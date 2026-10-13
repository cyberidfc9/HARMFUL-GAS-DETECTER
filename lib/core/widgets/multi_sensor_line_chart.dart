import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../../data/models/analytics_summary.dart';
import '../../data/models/sensor_reading.dart';

class MultiSensorLineChart extends StatelessWidget {
  final Map<SensorType, List<ChartDataPoint>> pointsBySensor;
  final TimeRange timeRange;

  const MultiSensorLineChart({
    super.key,
    required this.pointsBySensor,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gridBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorderSubtle;

    // Gather all points across all sensors to establish bounds
    final allPoints = <ChartDataPoint>[];
    for (final list in pointsBySensor.values) {
      allPoints.addAll(list);
    }

    if (allPoints.length < 2) {
      return Container(
        height: 230,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 28, color: textSecondary),
            const SizedBox(height: 8),
            Text(
              allPoints.isEmpty
                  ? 'No records in this time window'
                  : 'Insufficient data points to plot trend',
              style: AppTypography.caption.copyWith(color: textSecondary),
            ),
          ],
        ),
      );
    }

    double minTime = allPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
    double maxTime = allPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
    double minVal = allPoints.first.value;
    double maxVal = allPoints.first.value;

    for (final p in allPoints) {
      final t = p.timestamp.millisecondsSinceEpoch.toDouble();
      if (t < minTime) minTime = t;
      if (t > maxTime) maxTime = t;
      if (p.value < minVal) minVal = p.value;
      if (p.value > maxVal) maxVal = p.value;
    }

    // Ensure minTime != maxTime to avoid div by zero
    if (minTime == maxTime) {
      maxTime += 60000;
    }

    final padding = (maxVal - minVal) * 0.1;
    final yMin = (minVal - (padding == 0 ? 5 : padding)).clamp(0.0, double.infinity);
    final yMax = maxVal + (padding == 0 ? 5 : padding);

    // Build line bars for each sensor that has at least 2 points
    final lineBars = <LineChartBarData>[];

    final colors = {
      SensorType.mq2: AppColors.mq2Color,
      SensorType.mq7: AppColors.mq7Color,
      SensorType.mq135: AppColors.mq135Color,
    };

    pointsBySensor.forEach((sensor, points) {
      if (points.length >= 2) {
        final color = colors[sensor] ?? AppColors.accent;
        final spots = points
            .map((p) =>
                FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value))
            .toList();

        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: color,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: points.length <= 15,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: isDark ? AppColors.darkSurface : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: isDark ? 0.05 : 0.03),
            ),
          ),
        );
      }
    });

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
          // Multi-sensor legend row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(
                color: AppColors.mq2Color,
                label: 'MQ-2 (LPG ppm)',
                isDark: isDark,
              ),
              _LegendItem(
                color: AppColors.mq7Color,
                label: 'MQ-7 (CO ppm)',
                isDark: isDark,
              ),
              _LegendItem(
                color: AppColors.mq135Color,
                label: 'MQ-135 (AQI)',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (yMax - yMin) > 0 ? (yMax - yMin) / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridBorder,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: (yMax - yMin) > 0 ? (yMax - yMin) / 4 : 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            value.toInt().toString(),
                            textAlign: TextAlign.right,
                            style: AppTypography.caption.copyWith(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval:
                          (maxTime - minTime) > 0 ? (maxTime - minTime) / 3 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == minTime || value == maxTime) {
                          return const SizedBox.shrink();
                        }
                        final date =
                            DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormatter.formatForChart(
                                date, timeRange.duration),
                            style: AppTypography.caption.copyWith(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: minTime,
                maxX: maxTime,
                minY: yMin,
                maxY: yMax,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                            spot.x.toInt());
                        final formattedTime = DateFormatter.formatTime(date);
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}\n$formattedTime',
                          AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: lineBars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
