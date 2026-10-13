import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/device_state.dart';
import '../../../data/models/alert_item.dart';
import '../../../data/repositories/gas_monitor_repository.dart';
import '../../settings/providers/settings_providers.dart';

final gasMonitorRepositoryProvider = Provider<GasMonitorRepository>((ref) {
  return GasMonitorRepositoryImpl();
});

final deviceStateStreamProvider = StreamProvider<DeviceState>((ref) {
  final repo = ref.watch(gasMonitorRepositoryProvider);
  final deviceId = ref.watch(deviceIdProvider);
  final customPath = ref.watch(customPathProvider);

  return repo.watchDeviceState(
    deviceId: deviceId,
    customPath: customPath.isEmpty ? null : customPath,
  );
});

final databaseConnectionProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(gasMonitorRepositoryProvider);
  return repo.watchDatabaseConnection();
});

final alertsStreamProvider = StreamProvider<List<AlertItem>>((ref) {
  final repo = ref.watch(gasMonitorRepositoryProvider);
  final deviceId = ref.watch(deviceIdProvider);
  return repo.watchAlerts(deviceId: deviceId);
});

final latestActiveAlertProvider = Provider<AlertItem?>((ref) {
  final alertsAsync = ref.watch(alertsStreamProvider);
  return alertsAsync.when(
    data: (alerts) {
      if (alerts.isEmpty) return null;
      // Find latest unresolved alert
      final active = alerts.where((a) => !a.resolved).toList();
      return active.isNotEmpty ? active.first : null;
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});
