import 'sensor_reading.dart';

enum AlertSeverity {
  warning,
  critical,
  info;

  String get label {
    switch (this) {
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.info:
        return 'Notice';
    }
  }

  static AlertSeverity fromString(String? val) {
    final lower = val?.toLowerCase() ?? '';
    if (lower.contains('crit') || lower.contains('danger') || lower.contains('high')) {
      return AlertSeverity.critical;
    }
    if (lower.contains('warn') || lower.contains('elevated') || lower.contains('med')) {
      return AlertSeverity.warning;
    }
    return AlertSeverity.info;
  }
}

class AlertItem {
  final String id;
  final String deviceId;
  final SensorType? sensorType;
  final AlertSeverity severity;
  final String message;
  final num? recordedValue;
  final String? measurementType;
  final DateTime timestamp;
  final bool resolved;

  const AlertItem({
    required this.id,
    required this.deviceId,
    this.sensorType,
    required this.severity,
    required this.message,
    this.recordedValue,
    this.measurementType,
    required this.timestamp,
    this.resolved = false,
  });

  factory AlertItem.fromMap(String key, dynamic raw) {
    if (raw == null || raw is! Map) {
      return AlertItem(
        id: key,
        deviceId: 'unknown',
        severity: AlertSeverity.warning,
        message: 'Alert event',
        timestamp: DateTime.now(),
      );
    }

    final data = Map<String, dynamic>.from(raw);

    DateTime alertTime = DateTime.now();
    final tsRaw = data['timestamp'] ?? data['time'] ?? data['ts'];
    if (tsRaw != null) {
      if (tsRaw is int) {
        alertTime = tsRaw > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(tsRaw)
            : DateTime.fromMillisecondsSinceEpoch(tsRaw * 1000);
      } else if (tsRaw is String) {
        alertTime = DateTime.tryParse(tsRaw) ?? DateTime.now();
      }
    }

    final sensorStr = data['sensorId'] ?? data['sensor'] ?? data['sensorType'];
    SensorType? st;
    if (sensorStr != null) {
      st = SensorType.fromKey(sensorStr.toString());
    }

    final sev = AlertSeverity.fromString(data['severity']?.toString());
    final val = num.tryParse(
      (data['recordedValue'] ?? data['triggeringMeasurement'] ?? data['value'])
              ?.toString() ??
          '',
    );

    return AlertItem(
      id: key,
      deviceId: data['deviceId']?.toString() ?? 'device',
      sensorType: st,
      severity: sev,
      message: data['message']?.toString() ??
          data['ruleId']?.toString() ??
          'Threshold limit exceeded',
      recordedValue: val,
      measurementType: data['measurementType']?.toString() ?? data['unit']?.toString(),
      timestamp: alertTime,
      resolved: data['resolved'] == true ||
          data['resolutionState'] == 'resolved' ||
          data['status'] == 'resolved',
    );
  }
}
