import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/alert_item.dart';
import '../../dashboard/providers/device_providers.dart';

class AlertFilterSeverityNotifier extends Notifier<AlertSeverity?> {
  @override
  AlertSeverity? build() => null;

  void setSeverity(AlertSeverity? severity) => state = severity;
}

final alertFilterSeverityProvider =
    NotifierProvider<AlertFilterSeverityNotifier, AlertSeverity?>(
        AlertFilterSeverityNotifier.new);

class AlertFilterResolvedNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setResolved(bool? resolved) => state = resolved;
}

final alertFilterResolvedProvider =
    NotifierProvider<AlertFilterResolvedNotifier, bool?>(
        AlertFilterResolvedNotifier.new);

final filteredAlertsProvider = Provider<List<AlertItem>>((ref) {
  final alertsAsync = ref.watch(alertsStreamProvider);
  final severityFilter = ref.watch(alertFilterSeverityProvider);
  final resolvedFilter = ref.watch(alertFilterResolvedProvider);

  final allAlerts = alertsAsync.value ?? [];

  return allAlerts.where((alert) {
    if (severityFilter != null && alert.severity != severityFilter) {
      return false;
    }
    if (resolvedFilter != null && alert.resolved != resolvedFilter) {
      return false;
    }
    return true;
  }).toList();
});
