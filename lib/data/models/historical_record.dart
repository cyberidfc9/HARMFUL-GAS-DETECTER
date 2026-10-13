import 'sensor_reading.dart';

class HistoricalRecord {
  final String id;
  final String? deviceId;
  final DateTime timestamp;
  final num? mq2;
  final String mq2Type;
  final bool mq2Valid;

  final num? mq7;
  final String mq7Type;
  final bool mq7Valid;

  final num? mq135;
  final String mq135Type;
  final bool mq135Valid;

  const HistoricalRecord({
    required this.id,
    this.deviceId,
    required this.timestamp,
    this.mq2,
    this.mq2Type = 'ppm',
    this.mq2Valid = true,
    this.mq7,
    this.mq7Type = 'ppm',
    this.mq7Valid = true,
    this.mq135,
    this.mq135Type = 'AQI',
    this.mq135Valid = true,
  });

  num? getValueFor(SensorType type) {
    switch (type) {
      case SensorType.mq2:
        return mq2Valid ? mq2 : null;
      case SensorType.mq7:
        return mq7Valid ? mq7 : null;
      case SensorType.mq135:
        return mq135Valid ? mq135 : null;
    }
  }

  String getUnitFor(SensorType type) {
    switch (type) {
      case SensorType.mq2:
        return mq2Type;
      case SensorType.mq7:
        return mq7Type;
      case SensorType.mq135:
        return mq135Type;
    }
  }

  String? getStatusFor(SensorType type) {
    switch (type) {
      case SensorType.mq2:
        if (mq2 == null) return null;
        return mq2! > 1200 ? 'LPG HIGH' : 'LPG NORMAL';
      case SensorType.mq7:
        if (mq7 == null) return null;
        return mq7! > 50 ? 'CO HIGH' : 'CO NORMAL';
      case SensorType.mq135:
        if (mq135 == null) return null;
        if (mq135! <= 90) return 'GOOD';
        if (mq135! <= 129) return 'MEDIUM';
        return 'BAD';
    }
  }

  String getFormattedValue(SensorType type) {
    final val = getValueFor(type);
    if (val == null) return '--';
    if (val is int || val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  factory HistoricalRecord.fromMap(String key, dynamic raw) {
    if (raw == null || raw is! Map) {
      return HistoricalRecord(id: key, timestamp: DateTime.now());
    }

    final data = Map<String, dynamic>.from(raw);

    DateTime recordTime = DateTime.now();
    final tsRaw = data['timestamp'] ?? data['time'] ?? data['ts'];
    if (tsRaw != null) {
      if (tsRaw is int) {
        recordTime = tsRaw > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(tsRaw)
            : DateTime.fromMillisecondsSinceEpoch(tsRaw * 1000);
      } else if (tsRaw is String) {
        final parsed = int.tryParse(tsRaw);
        if (parsed != null) {
          recordTime = parsed > 1000000000000
              ? DateTime.fromMillisecondsSinceEpoch(parsed)
              : DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
        } else {
          recordTime = DateTime.tryParse(tsRaw) ?? DateTime.now();
        }
      }
    }

    // MQ2
    num? mq2Val;
    String mq2T = 'ppm';
    bool mq2V = true;
    final mq2Data = data['mq2'] ?? data['MQ2'];
    if (mq2Data is num) {
      mq2Val = mq2Data;
    } else if (mq2Data is String) {
      mq2Val = num.tryParse(mq2Data);
    } else if (mq2Data is Map) {
      final m = Map<String, dynamic>.from(mq2Data);
      mq2Val = num.tryParse((m['value'] ?? m['calibrated'] ?? m['raw'] ?? m['val'])?.toString() ?? '');
      mq2T = m['measurementType']?.toString() ?? m['unit']?.toString() ?? 'ppm';
      mq2V = m['valid'] == null ? (mq2Val != null) : m['valid'] == true;
    }

    // MQ7
    num? mq7Val;
    String mq7T = 'ppm';
    bool mq7V = true;
    final mq7Data = data['mq7'] ?? data['MQ7'];
    if (mq7Data is num) {
      mq7Val = mq7Data;
    } else if (mq7Data is String) {
      mq7Val = num.tryParse(mq7Data);
    } else if (mq7Data is Map) {
      final m = Map<String, dynamic>.from(mq7Data);
      mq7Val = num.tryParse((m['value'] ?? m['calibrated'] ?? m['raw'] ?? m['val'])?.toString() ?? '');
      mq7T = m['measurementType']?.toString() ?? m['unit']?.toString() ?? 'ppm';
      mq7V = m['valid'] == null ? (mq7Val != null) : m['valid'] == true;
    }

    // MQ135
    num? mq135Val;
    String mq135T = 'AQI';
    bool mq135V = true;
    final mq135Data = data['mq135'] ?? data['MQ135'];
    if (mq135Data is num) {
      mq135Val = mq135Data;
    } else if (mq135Data is String) {
      mq135Val = num.tryParse(mq135Data);
    } else if (mq135Data is Map) {
      final m = Map<String, dynamic>.from(mq135Data);
      mq135Val = num.tryParse((m['value'] ?? m['calibrated'] ?? m['raw'] ?? m['val'])?.toString() ?? '');
      mq135T = m['measurementType']?.toString() ?? m['unit']?.toString() ?? 'AQI';
      mq135V = m['valid'] == null ? (mq135Val != null) : m['valid'] == true;
    }

    return HistoricalRecord(
      id: key,
      deviceId: data['deviceId']?.toString(),
      timestamp: recordTime,
      mq2: mq2Val,
      mq2Type: mq2T,
      mq2Valid: mq2V,
      mq7: mq7Val,
      mq7Type: mq7T,
      mq7Valid: mq7V,
      mq135: mq135Val,
      mq135Type: mq135T,
      mq135Valid: mq135V,
    );
  }
}
