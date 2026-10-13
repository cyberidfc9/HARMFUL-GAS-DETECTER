import 'sensor_reading.dart';

enum DeviceConnectionStatus {
  online,
  offline,
  stale,
  unknown;

  String get label {
    switch (this) {
      case DeviceConnectionStatus.online:
        return 'Online';
      case DeviceConnectionStatus.offline:
        return 'Offline';
      case DeviceConnectionStatus.stale:
        return 'Stale Data';
      case DeviceConnectionStatus.unknown:
        return 'Unknown';
    }
  }
}

enum DataFreshness {
  fresh,
  stale,
  offline,
  unknown;

  String get label {
    switch (this) {
      case DataFreshness.fresh:
        return 'Fresh (Real-time)';
      case DataFreshness.stale:
        return 'Stale (> 60s)';
      case DataFreshness.offline:
        return 'Offline (> 3m)';
      case DataFreshness.unknown:
        return 'No Data';
    }
  }
}

class DeviceState {
  final String deviceId;
  final DateTime? lastSeen;
  final String? reportedStatus;
  final String? firmwareVersion;
  final String? ipAddress;
  final Map<SensorType, SensorReading> sensors;

  const DeviceState({
    required this.deviceId,
    this.lastSeen,
    this.reportedStatus,
    this.firmwareVersion,
    this.ipAddress,
    required this.sensors,
  });

  /// Inferred connection status based on heartbeat timestamp rules.
  /// PRD Section 10.8: "Device connectivity must be inferred from heartbeat
  /// or timestamp rules, not from the last sensor value alone."
  DeviceConnectionStatus getConnectionStatus({int heartbeatTimeoutSeconds = 90}) {
    if (lastSeen == null) return DeviceConnectionStatus.unknown;

    final diff = DateTime.now().difference(lastSeen!).inSeconds;
    if (diff < 0) return DeviceConnectionStatus.online; // Device clock slightly ahead

    if (diff <= heartbeatTimeoutSeconds) {
      return DeviceConnectionStatus.online;
    } else if (diff <= heartbeatTimeoutSeconds * 2) {
      return DeviceConnectionStatus.stale;
    } else {
      return DeviceConnectionStatus.offline;
    }
  }

  DataFreshness getFreshness() {
    if (lastSeen == null) return DataFreshness.unknown;
    final diff = DateTime.now().difference(lastSeen!).inSeconds;
    if (diff <= 60) return DataFreshness.fresh;
    if (diff <= 180) return DataFreshness.stale;
    return DataFreshness.offline;
  }

  bool get isOnline =>
      getConnectionStatus() == DeviceConnectionStatus.online;

  SensorReading? getReading(SensorType type) => sensors[type];

  factory DeviceState.empty(String deviceId) {
    return DeviceState(
      deviceId: deviceId,
      lastSeen: null,
      reportedStatus: 'waiting',
      sensors: {
        SensorType.mq2: const SensorReading(type: SensorType.mq2, valid: false),
        SensorType.mq7: const SensorReading(type: SensorType.mq7, valid: false),
        SensorType.mq135: const SensorReading(type: SensorType.mq135, valid: false),
      },
    );
  }

  factory DeviceState.fromMap(String deviceId, dynamic raw) {
    if (raw == null || raw is! Map) {
      return DeviceState.empty(deviceId);
    }

    final data = Map<String, dynamic>.from(raw);

    // Parse lastSeen timestamp
    DateTime? lastSeenTime;
    final tsRaw = data['lastSeen'] ?? data['timestamp'] ?? data['last_seen'] ?? data['time'];
    if (tsRaw != null) {
      if (tsRaw is int) {
        lastSeenTime = tsRaw > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(tsRaw)
            : DateTime.fromMillisecondsSinceEpoch(tsRaw * 1000);
      } else if (tsRaw is String) {
        lastSeenTime = DateTime.tryParse(tsRaw);
      }
    }

    final reportedStatus = data['status']?.toString();
    final firmware = data['firmware']?.toString() ?? data['firmwareVersion']?.toString();
    final ip = data['ip']?.toString() ?? data['ipAddress']?.toString();

    // Parse sensors (nested under 'sensors', or directly at root)
    final sensorsMap = <SensorType, SensorReading>{};
    final dynamic sensorsContainer = data['sensors'] is Map ? data['sensors'] : data;

    if (sensorsContainer is Map) {
      final sMap = Map<String, dynamic>.from(sensorsContainer);

      // MQ-2
      final mq2Data = sMap['mq2'] ?? sMap['MQ2'] ?? sMap['mq_2'] ?? sMap['gas'];
      sensorsMap[SensorType.mq2] = SensorReading.fromMap(SensorType.mq2, mq2Data);

      // MQ-7
      final mq7Data = sMap['mq7'] ?? sMap['MQ7'] ?? sMap['mq_7'] ?? sMap['co'];
      sensorsMap[SensorType.mq7] = SensorReading.fromMap(SensorType.mq7, mq7Data);

      // MQ-135
      final mq135Data = sMap['mq135'] ?? sMap['MQ135'] ?? sMap['mq_135'] ?? sMap['air'];
      sensorsMap[SensorType.mq135] = SensorReading.fromMap(SensorType.mq135, mq135Data);
    } else {
      sensorsMap[SensorType.mq2] = const SensorReading(type: SensorType.mq2, valid: false);
      sensorsMap[SensorType.mq7] = const SensorReading(type: SensorType.mq7, valid: false);
      sensorsMap[SensorType.mq135] = const SensorReading(type: SensorType.mq135, valid: false);
    }

    // If device timestamp was missing in root but sensor has timestamp, fallback
    if (lastSeenTime == null) {
      for (final reading in sensorsMap.values) {
        if (reading.timestamp != null) {
          if (lastSeenTime == null || reading.timestamp!.isAfter(lastSeenTime)) {
            lastSeenTime = reading.timestamp;
          }
        }
      }
    }

    return DeviceState(
      deviceId: (data['deviceId'] ?? deviceId).toString(),
      lastSeen: lastSeenTime,
      reportedStatus: reportedStatus,
      firmwareVersion: firmware,
      ipAddress: ip,
      sensors: sensorsMap,
    );
  }
}
