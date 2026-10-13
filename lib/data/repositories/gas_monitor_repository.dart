import '../models/device_state.dart';
import '../models/historical_record.dart';
import '../models/alert_item.dart';
import '../services/firebase_service.dart';

abstract class GasMonitorRepository {
  Stream<DeviceState> watchDeviceState({required String deviceId, String? customPath});
  Stream<List<HistoricalRecord>> watchHistory({required String deviceId});
  Stream<List<AlertItem>> watchAlerts({required String deviceId});
  Stream<bool> watchDatabaseConnection();
}

class GasMonitorRepositoryImpl implements GasMonitorRepository {
  final FirebaseService _service;

  GasMonitorRepositoryImpl({FirebaseService? service})
      : _service = service ?? FirebaseService();

  @override
  Stream<DeviceState> watchDeviceState({required String deviceId, String? customPath}) {
    return _service.streamDeviceState(deviceId: deviceId, customPath: customPath);
  }

  @override
  Stream<List<HistoricalRecord>> watchHistory({required String deviceId}) {
    return _service.streamHistory(deviceId: deviceId);
  }

  @override
  Stream<List<AlertItem>> watchAlerts({required String deviceId}) {
    return _service.streamAlerts(deviceId: deviceId);
  }

  @override
  Stream<bool> watchDatabaseConnection() {
    return _service.connectivityStream;
  }
}
