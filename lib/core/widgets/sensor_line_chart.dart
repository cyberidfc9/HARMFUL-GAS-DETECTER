import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../../data/models/analytics_summary.dart';
import '../../data/models/sensor_reading.dart';

class SensorLineChart extends StatelessWidget {
  final List<ChartDataPoint> points;
  final SensorType sensorType;
  final TimeRange timeRange;
  final String unit;

  const SensorLineChart({
    super.key,
    required this.points,
    required this.sensorType,
    required this.timeRange,
    required this.unit,
  });

  Color _getLineColor() {
    switch (sensorType) {
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
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gridBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorderSubtle;
    final lineColor = _getLineColor();

    if (points.length < 2) {
      return Container(
        height: 220,
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
              points.isEmpty
                  ? 'No records in this time window'
                  : 'Insufficient data points to plot trend',
              style: AppTypography.caption.copyWith(color: textSecondary),
            ),
          ],
        ),
      );
    }

    final minTime = points.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxTime = points.last.timestamp.millisecondsSinceEpoch.toDouble();

    double minVal = points.first.value;
    double maxVal = points.first.value;
    for (final p in points) {
      if (p.value < minVal) minVal = p.value;
      if (p.value > maxVal) maxVal = p.value;
    }

    // Add 10% breathing room to Y axis
    final padding = (maxVal - minVal) * 0.1;
    final yMin = (minVal - (padding == 0 ? 5 : padding)).clamp(0.0, double.infinity);
    final yMax = maxVal + (padding == 0 ? 5 : padding);

    final spots = points.map((p) {
      return FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value);
    }).toList();

    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (yMax - yMin) > 0 ? (yMax - yMin) / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: gridBorder,
                strokeWidth: 1,
              );
            },
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
                interval: (maxTime - minTime) > 0 ? (maxTime - minTime) / 3 : 1,
                getTitlesWidget: (value, meta) {
                  if (value == minTime || value == maxTime) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormatter.formatForChart(date, timeRange.duration),
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
                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  final formattedTime = DateFormatter.formatTime(date);
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} $unit\n$formattedTime',
                    AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: lineColor,
              barWidth: 2.2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: points.length <= 15,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 1.5,
                    strokeColor: isDark ? AppColors.darkSurface : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
