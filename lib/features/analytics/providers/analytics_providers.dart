import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/historical_record.dart';
import '../../../data/models/analytics_summary.dart';
import '../../settings/providers/settings_providers.dart';
import '../../dashboard/providers/device_providers.dart';

enum AnalyticsSensorFilter {
  all,
  mq2,
  mq7,
  mq135;

  String get displayName {
    switch (this) {
      case AnalyticsSensorFilter.all:
        return 'All Sensors';
      case AnalyticsSensorFilter.mq2:
        return 'MQ-2';
      case AnalyticsSensorFilter.mq7:
        return 'MQ-7';
      case AnalyticsSensorFilter.mq135:
        return 'MQ-135';
    }
  }

  SensorType? get sensorType {
    switch (this) {
      case AnalyticsSensorFilter.all:
        return null;
      case AnalyticsSensorFilter.mq2:
        return SensorType.mq2;
      case AnalyticsSensorFilter.mq7:
        return SensorType.mq7;
      case AnalyticsSensorFilter.mq135:
        return SensorType.mq135;
    }
  }
}

class SelectedFilterNotifier extends Notifier<AnalyticsSensorFilter> {
  @override
  AnalyticsSensorFilter build() => AnalyticsSensorFilter.all;

  void setFilter(AnalyticsSensorFilter filter) => state = filter;
}

final selectedFilterProvider =
    NotifierProvider<SelectedFilterNotifier, AnalyticsSensorFilter>(
        SelectedFilterNotifier.new);

class SelectedSensorNotifier extends Notifier<SensorType> {
  @override
  SensorType build() => SensorType.mq2;

  void setSensor(SensorType type) => state = type;
}

final selectedSensorProvider =
    NotifierProvider<SelectedSensorNotifier, SensorType>(
        SelectedSensorNotifier.new);

class SelectedTimeRangeNotifier extends Notifier<TimeRange> {
  @override
  TimeRange build() => TimeRange.twentyFourHours;

  void setRange(TimeRange range) => state = range;
}

final selectedTimeRangeProvider =
    NotifierProvider<SelectedTimeRangeNotifier, TimeRange>(
        SelectedTimeRangeNotifier.new);

final historicalRecordsStreamProvider =
    StreamProvider<List<HistoricalRecord>>((ref) {
  final repo = ref.watch(gasMonitorRepositoryProvider);
  final deviceId = ref.watch(deviceIdProvider);
  return repo.watchHistory(deviceId: deviceId);
});

/// Real-time historical stream merging persisted records with live streaming state
final realtimeHistoryProvider = Provider<List<HistoricalRecord>>((ref) {
  final historyAsync = ref.watch(historicalRecordsStreamProvider);
  final deviceStateAsync = ref.watch(deviceStateStreamProvider);

  final records = List<HistoricalRecord>.from(historyAsync.value ?? []);

  final liveState = deviceStateAsync.value;
  if (liveState != null && liveState.lastSeen != null) {
    final mq2 = liveState.sensors[SensorType.mq2];
    final mq7 = liveState.sensors[SensorType.mq7];
    final mq135 = liveState.sensors[SensorType.mq135];

    final hasAny = (mq2 != null && mq2.hasData) ||
        (mq7 != null && mq7.hasData) ||
        (mq135 != null && mq135.hasData);

    if (hasAny) {
      final liveRecord = HistoricalRecord(
        id: 'live_realtime',
        deviceId: liveState.deviceId,
        timestamp: liveState.lastSeen!,
        mq2: mq2?.calibratedValue ?? mq2?.value,
        mq2Type: 'ppm',
        mq2Valid: mq2?.hasData == true,
        mq7: mq7?.calibratedValue ?? mq7?.value,
        mq7Type: 'ppm',
        mq7Valid: mq7?.hasData == true,
        mq135: mq135?.calibratedValue ?? mq135?.value,
        mq135Type: 'AQI',
        mq135Valid: mq135?.hasData == true,
      );

      if (records.isEmpty) {
        records.add(liveRecord);
      } else {
        final last = records.last;
        if (liveRecord.timestamp.difference(last.timestamp).inSeconds.abs() <= 6) {
          records[records.length - 1] = liveRecord;
        } else if (liveRecord.timestamp.isAfter(last.timestamp)) {
          records.add(liveRecord);
        }
      }
    }
  }

  return records;
});

final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final filter = ref.watch(selectedFilterProvider);
  final fallback = ref.watch(selectedSensorProvider);
  final SensorType sensor = filter.sensorType ?? fallback;
  final range = ref.watch(selectedTimeRangeProvider);
  final records = ref.watch(realtimeHistoryProvider);

  return AnalyticsSummary.calculate(
    sensorType: sensor,
    timeRange: range,
    records: records,
  );
});

final allSensorsAnalyticsProvider =
    Provider<Map<SensorType, AnalyticsSummary>>((ref) {
  final range = ref.watch(selectedTimeRangeProvider);
  final records = ref.watch(realtimeHistoryProvider);

  return {
    SensorType.mq2: AnalyticsSummary.calculate(
      sensorType: SensorType.mq2,
      timeRange: range,
      records: records,
    ),
    SensorType.mq7: AnalyticsSummary.calculate(
      sensorType: SensorType.mq7,
      timeRange: range,
      records: records,
    ),
    SensorType.mq135: AnalyticsSummary.calculate(
      sensorType: SensorType.mq135,
      timeRange: range,
      records: records,
    ),
  };
});
