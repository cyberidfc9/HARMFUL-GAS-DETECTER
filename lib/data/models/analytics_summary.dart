import '../models/sensor_reading.dart';
import '../models/historical_record.dart';

enum TimeRange {
  oneHour,
  sixHours,
  twentyFourHours,
  sevenDays,
  thirtyDays;

  String get label {
    switch (this) {
      case TimeRange.oneHour:
        return '1h';
      case TimeRange.sixHours:
        return '6h';
      case TimeRange.twentyFourHours:
        return '24h';
      case TimeRange.sevenDays:
        return '7d';
      case TimeRange.thirtyDays:
        return '30d';
    }
  }

  String get fullLabel {
    switch (this) {
      case TimeRange.oneHour:
        return 'Last 1 Hour';
      case TimeRange.sixHours:
        return 'Last 6 Hours';
      case TimeRange.twentyFourHours:
        return 'Last 24 Hours';
      case TimeRange.sevenDays:
        return 'Last 7 Days';
      case TimeRange.thirtyDays:
        return 'Last 30 Days';
    }
  }

  Duration get duration {
    switch (this) {
      case TimeRange.oneHour:
        return const Duration(hours: 1);
      case TimeRange.sixHours:
        return const Duration(hours: 6);
      case TimeRange.twentyFourHours:
        return const Duration(hours: 24);
      case TimeRange.sevenDays:
        return const Duration(days: 7);
      case TimeRange.thirtyDays:
        return const Duration(days: 30);
    }
  }
}

enum TrendDirection {
  increasing,
  decreasing,
  stable,
  insufficientData;

  String get label {
    switch (this) {
      case TrendDirection.increasing:
        return 'Increasing';
      case TrendDirection.decreasing:
        return 'Decreasing';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.insufficientData:
        return 'Insufficient data';
    }
  }
}

class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  const ChartDataPoint({required this.timestamp, required this.value});
}

class AnalyticsSummary {
  final SensorType sensorType;
  final TimeRange timeRange;
  final num? min;
  final num? max;
  final double? average;
  final int readingCount;
  final TrendDirection trend;
  final double? percentageChange;
  final List<ChartDataPoint> points;
  final String unit;

  const AnalyticsSummary({
    required this.sensorType,
    required this.timeRange,
    this.min,
    this.max,
    this.average,
    required this.readingCount,
    required this.trend,
    this.percentageChange,
    required this.points,
    required this.unit,
  });

  bool get hasSufficientData => readingCount >= 2;

  factory AnalyticsSummary.calculate({
    required SensorType sensorType,
    required TimeRange timeRange,
    required List<HistoricalRecord> records,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(timeRange.duration);

    // Filter valid records strictly within the time range
    final filtered = records
        .where((r) => r.timestamp.isAfter(cutoff) || r.timestamp.isAtSameMomentAs(cutoff))
        .toList();

    // Sort chronologically ascending
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final points = <ChartDataPoint>[];
    num? minVal;
    num? maxVal;
    double sum = 0.0;
    String detectedUnit = sensorType == SensorType.mq135 ? 'AQI' : 'ppm';

    for (final record in filtered) {
      final val = record.getValueFor(sensorType);
      if (val != null) {
        final dVal = val.toDouble();
        points.add(ChartDataPoint(timestamp: record.timestamp, value: dVal));
        if (minVal == null || val < minVal) minVal = val;
        if (maxVal == null || val > maxVal) maxVal = val;
        sum += dVal;
        detectedUnit = record.getUnitFor(sensorType);
      }
    }

    final count = points.length;
    final avg = count > 0 ? (sum / count) : null;

    // Trend calculation explicitly comparing two equal halves of the time window
    TrendDirection trend = TrendDirection.insufficientData;
    double? changePercent;

    if (count >= 4) {
      final half = count ~/ 2;
      final olderHalf = points.sublist(0, half);
      final recentHalf = points.sublist(half);

      final olderAvg = olderHalf.map((p) => p.value).reduce((a, b) => a + b) / half;
      final recentAvg =
          recentHalf.map((p) => p.value).reduce((a, b) => a + b) / recentHalf.length;

      if (olderAvg > 0) {
        changePercent = ((recentAvg - olderAvg) / olderAvg) * 100;
      }

      // 5% change threshold for trend sensitivity
      final diff = recentAvg - olderAvg;
      final relativeThreshold = olderAvg.abs() * 0.05;
      final effectiveThreshold = relativeThreshold < 1.0 ? 1.0 : relativeThreshold;

      if (diff > effectiveThreshold) {
        trend = TrendDirection.increasing;
      } else if (diff < -effectiveThreshold) {
        trend = TrendDirection.decreasing;
      } else {
        trend = TrendDirection.stable;
      }
    }

    return AnalyticsSummary(
      sensorType: sensorType,
      timeRange: timeRange,
      min: minVal,
      max: maxVal,
      average: avg,
      readingCount: count,
      trend: trend,
      percentageChange: changePercent,
      points: points,
      unit: detectedUnit,
    );
  }
}
