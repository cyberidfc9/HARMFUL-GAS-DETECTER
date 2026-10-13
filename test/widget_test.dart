import 'package:flutter_test/flutter_test.dart';
import 'package:gas_monitor/data/models/sensor_reading.dart';
import 'package:gas_monitor/data/models/device_state.dart';
import 'package:gas_monitor/data/models/historical_record.dart';
import 'package:gas_monitor/data/models/analytics_summary.dart';

void main() {
  group('Gas Monitor Model and Parsing Tests', () {
    test('SensorReading parses raw ADC correctly and prevents fake ppm', () {
      final reading = SensorReading.fromMap(SensorType.mq7, {
        'value': 350,
        'measurementType': 'Raw ADC',
        'valid': true,
      });

      expect(reading.type, SensorType.mq7);
      expect(reading.value, 350);
      expect(reading.displayValue, '350');
      expect(reading.displayType, 'Raw ADC');
      expect(reading.hasData, isTrue);
      expect(reading.calibratedValue, isNull);
    });

    test('Missing sensor reading returns valid = false without fake zero', () {
      final reading = SensorReading.fromMap(SensorType.mq2, null);

      expect(reading.hasData, isFalse);
      expect(reading.value, isNull);
      expect(reading.displayValue, 'No data');
      expect(reading.valid, isFalse);
    });

    test('DeviceState infers connectivity status strictly from heartbeat rules', () {
      final now = DateTime.now();

      // Recent heartbeat (10 seconds ago) -> Online
      final onlineDevice = DeviceState.fromMap('esp32_01', {
        'lastSeen': now.subtract(const Duration(seconds: 10)).millisecondsSinceEpoch,
        'sensors': {'mq2': 210, 'mq7': 110, 'mq135': 300},
      });
      expect(onlineDevice.getConnectionStatus(heartbeatTimeoutSeconds: 60),
          DeviceConnectionStatus.online);

      // Stale heartbeat (90 seconds ago, timeout 60s) -> Stale
      final staleDevice = DeviceState.fromMap('esp32_01', {
        'lastSeen': now.subtract(const Duration(seconds: 90)).millisecondsSinceEpoch,
      });
      expect(staleDevice.getConnectionStatus(heartbeatTimeoutSeconds: 60),
          DeviceConnectionStatus.stale);

      // Old heartbeat (10 minutes ago) -> Offline
      final offlineDevice = DeviceState.fromMap('esp32_01', {
        'lastSeen': now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
      });
      expect(offlineDevice.getConnectionStatus(heartbeatTimeoutSeconds: 60),
          DeviceConnectionStatus.offline);

      // No heartbeat recorded -> Unknown
      final unknownDevice = DeviceState.empty('esp32_01');
      expect(unknownDevice.getConnectionStatus(heartbeatTimeoutSeconds: 60),
          DeviceConnectionStatus.unknown);
    });
  });

  group('Analytics and Trend Calculation Tests', () {
    test('Calculates min, max, and average correctly from actual history', () {
      final now = DateTime.now();
      final records = [
        HistoricalRecord(
          id: '1',
          timestamp: now.subtract(const Duration(minutes: 40)),
          mq2: 100,
        ),
        HistoricalRecord(
          id: '2',
          timestamp: now.subtract(const Duration(minutes: 30)),
          mq2: 200,
        ),
        HistoricalRecord(
          id: '3',
          timestamp: now.subtract(const Duration(minutes: 20)),
          mq2: 300,
        ),
        HistoricalRecord(
          id: '4',
          timestamp: now.subtract(const Duration(minutes: 10)),
          mq2: 400,
        ),
      ];

      final summary = AnalyticsSummary.calculate(
        sensorType: SensorType.mq2,
        timeRange: TimeRange.oneHour,
        records: records,
      );

      expect(summary.min, 100);
      expect(summary.max, 400);
      expect(summary.average, 250.0);
      expect(summary.readingCount, 4);
      // Average of first half (100, 200) is 150. Average of second half (300, 400) is 350 -> Increasing
      expect(summary.trend, TrendDirection.increasing);
    });

    test('Excludes records outside the selected time range', () {
      final now = DateTime.now();
      final records = [
        HistoricalRecord(
          id: '1',
          timestamp: now.subtract(const Duration(hours: 3)), // Outside 1h window
          mq2: 50,
        ),
        HistoricalRecord(
          id: '2',
          timestamp: now.subtract(const Duration(minutes: 15)), // Inside 1h window
          mq2: 120,
        ),
      ];

      final summary = AnalyticsSummary.calculate(
        sensorType: SensorType.mq2,
        timeRange: TimeRange.oneHour,
        records: records,
      );

      expect(summary.readingCount, 1);
      expect(summary.min, 120);
      expect(summary.max, 120);
      expect(summary.average, 120.0);
      // With only 1 reading, trend must be InsufficientData
      expect(summary.trend, TrendDirection.insufficientData);
    });

    test('HistoricalRecord parses real values and units accurately', () {
      final record = HistoricalRecord.fromMap('-P3j5Wg1', {
        'timestamp': 1791791600383,
        'mq2': 634.1,
        'mq7': 0.0,
        'mq135': 88,
      });

      expect(record.mq2, 634.1);
      expect(record.getUnitFor(SensorType.mq2), 'ppm');
      expect(record.getStatusFor(SensorType.mq2), 'LPG NORMAL');
      expect(record.getFormattedValue(SensorType.mq2), '634.1');

      expect(record.mq7, 0.0);
      expect(record.getUnitFor(SensorType.mq7), 'ppm');
      expect(record.getStatusFor(SensorType.mq7), 'CO NORMAL');
      expect(record.getFormattedValue(SensorType.mq7), '0');

      expect(record.mq135, 88);
      expect(record.getUnitFor(SensorType.mq135), 'AQI');
      expect(record.getStatusFor(SensorType.mq135), 'GOOD');
      expect(record.getFormattedValue(SensorType.mq135), '88');
    });

    test('HistoricalRecord classifies elevated gas and smoke values correctly', () {
      final badRecord = HistoricalRecord.fromMap('-P3jSmoke', {
        'timestamp': 1791791650000,
        'mq2': 1450.0,
        'mq7': 75.0,
        'mq135': 185,
      });

      expect(badRecord.getStatusFor(SensorType.mq2), 'LPG HIGH');
      expect(badRecord.getStatusFor(SensorType.mq7), 'CO HIGH');
      expect(badRecord.getStatusFor(SensorType.mq135), 'BAD');

      final medRecord = HistoricalRecord.fromMap('-P3jMed', {
        'timestamp': 1791791650000,
        'mq135': 115,
      });
      expect(medRecord.getStatusFor(SensorType.mq135), 'MEDIUM');
    });
  });
}
