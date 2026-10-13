enum SensorType {
  mq2,
  mq7,
  mq135;

  String get key {
    switch (this) {
      case SensorType.mq2:
        return 'mq2';
      case SensorType.mq7:
        return 'mq7';
      case SensorType.mq135:
        return 'mq135';
    }
  }

  String get displayName {
    switch (this) {
      case SensorType.mq2:
        return 'MQ-2';
      case SensorType.mq7:
        return 'MQ-7';
      case SensorType.mq135:
        return 'MQ-135';
    }
  }

  String get targetGasLabel {
    switch (this) {
      case SensorType.mq2:
        return 'Combustible Gas & Smoke';
      case SensorType.mq7:
        return 'Carbon Monoxide (CO)';
      case SensorType.mq135:
        return 'Air Quality Indicator';
    }
  }

  String get technicalRole {
    switch (this) {
      case SensorType.mq2:
        return 'Detects LPG, propane, methane, alcohol, and smoke particulates through tin dioxide (SnO2) sensing element.';
      case SensorType.mq7:
        return 'High sensitivity to Carbon Monoxide using cyclic heating (high temperature clean, low temperature read). Raw ADC must be distinguished from validated ppm.';
      case SensorType.mq135:
        return 'Responds to benzene, ammonia (NH3), alcohol, and smoke for general indoor air quality tracking.';
    }
  }

  static SensorType fromKey(String? key) {
    final lower = key?.toLowerCase().trim() ?? '';
    if (lower.contains('mq2') || lower.contains('mq-2')) return SensorType.mq2;
    if (lower.contains('mq7') || lower.contains('mq-7')) return SensorType.mq7;
    if (lower.contains('mq135') || lower.contains('mq-135')) return SensorType.mq135;
    return SensorType.mq2;
  }
}

class SensorReading {
  final SensorType type;
  final num? value;
  final num? rawValue;
  final num? calibratedValue;
  final String measurementType;
  final DateTime? timestamp;
  final bool valid;
  final String? statusClassification;

  const SensorReading({
    required this.type,
    this.value,
    this.rawValue,
    this.calibratedValue,
    this.measurementType = 'Raw ADC',
    this.timestamp,
    this.valid = false,
    this.statusClassification,
  });

  bool get hasData => value != null && valid;

  String get displayValue {
    if (value == null) return 'No data';
    if (value is int || value == value!.roundToDouble()) {
      return value!.toInt().toString();
    }
    return value!.toStringAsFixed(1);
  }

  String get displayType {
    if (measurementType.trim().isEmpty) return 'Raw ADC';
    return measurementType;
  }

  factory SensorReading.fromMap(SensorType type, dynamic data) {
    if (data == null) {
      return SensorReading(type: type, valid: false);
    }

    // Direct numeric value case (e.g. { "mq2": 320 })
    if (data is num) {
      return SensorReading(
        type: type,
        value: data,
        rawValue: data,
        measurementType: 'Raw ADC',
        timestamp: DateTime.now(),
        valid: true,
      );
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final rawVal = map['raw'] ?? map['rawValue'] ?? map['raw_adc'];
      final mainVal = map['value'] ?? map['reading'] ?? map['val'] ?? rawVal;
      final calVal = map['calibrated'] ?? map['ppm'] ?? map['calibratedValue'];

      num? parsedValue;
      if (mainVal != null) {
        parsedValue = num.tryParse(mainVal.toString());
      }

      num? parsedRaw;
      if (rawVal != null) {
        parsedRaw = num.tryParse(rawVal.toString());
      }

      num? parsedCal;
      if (calVal != null) {
        parsedCal = num.tryParse(calVal.toString());
      }

      final typeStr = (map['measurementType'] ??
              map['unit'] ??
              map['type'] ??
              (parsedCal != null ? 'ppm' : 'Raw ADC'))
          .toString();

      DateTime? parsedTime;
      final ts = map['timestamp'] ?? map['time'] ?? map['ts'];
      if (ts != null) {
        if (ts is int) {
          // Could be seconds or milliseconds
          parsedTime = ts > 1000000000000
              ? DateTime.fromMillisecondsSinceEpoch(ts)
              : DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        } else if (ts is String) {
          parsedTime = DateTime.tryParse(ts);
        }
      }

      final bool isValid = map['valid'] == true ||
          (map['valid'] == null && parsedValue != null);

      String? statusStr = map['status']?.toString() ??
          map['classification']?.toString() ??
          map['airQuality']?.toString();

      if (type == SensorType.mq135 && parsedValue != null) {
        if (parsedValue <= 90) {
          statusStr = 'GOOD';
        } else if (parsedValue <= 129) {
          statusStr = 'MEDIUM';
        } else {
          statusStr = 'BAD';
        }
      }

      return SensorReading(
        type: type,
        value: parsedValue,
        rawValue: parsedRaw ?? parsedValue,
        calibratedValue: parsedCal,
        measurementType: typeStr,
        timestamp: parsedTime,
        valid: isValid,
        statusClassification: statusStr,
      );
    }

    return SensorReading(type: type, valid: false);
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'rawValue': rawValue,
      'calibratedValue': calibratedValue,
      'measurementType': measurementType,
      'timestamp': timestamp?.toIso8601String(),
      'valid': valid,
      'statusClassification': statusClassification,
    };
  }
}
