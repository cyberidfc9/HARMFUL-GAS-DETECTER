import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_state_view.dart';
import '../../../data/models/alert_item.dart';
import '../providers/alerts_providers.dart';
import '../../dashboard/providers/device_providers.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);
    final activeSeverity = ref.watch(alertFilterSeverityProvider);
    final activeResolved = ref.watch(alertFilterResolvedProvider);
    final filteredAlerts = ref.watch(filteredAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Alerts'),
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // All Filter
                FilterChip(
                  label: const Text('All'),
                  selected: activeSeverity == null && activeResolved == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(alertFilterSeverityProvider.notifier).setSeverity(null);
                      ref.read(alertFilterResolvedProvider.notifier).setResolved(null);
                    }
                  },
                  labelStyle: AppTypography.caption.copyWith(
                    fontWeight: (activeSeverity == null && activeResolved == null)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),

                // Critical Filter
                FilterChip(
                  label: const Text('Critical'),
                  selected: activeSeverity == AlertSeverity.critical,
                  onSelected: (selected) {
                    ref.read(alertFilterSeverityProvider.notifier).setSeverity(
                        selected ? AlertSeverity.critical : null);
                    ref.read(alertFilterResolvedProvider.notifier).setResolved(null);
                  },
                  labelStyle: AppTypography.caption.copyWith(
                    color: activeSeverity == AlertSeverity.critical
                        ? AppColors.statusCritical
                        : null,
                    fontWeight: activeSeverity == AlertSeverity.critical
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),

                // Warning Filter
                FilterChip(
                  label: const Text('Warning'),
                  selected: activeSeverity == AlertSeverity.warning,
                  onSelected: (selected) {
                    ref.read(alertFilterSeverityProvider.notifier).setSeverity(
                        selected ? AlertSeverity.warning : null);
                    ref.read(alertFilterResolvedProvider.notifier).setResolved(null);
                  },
                  labelStyle: AppTypography.caption.copyWith(
                    color: activeSeverity == AlertSeverity.warning
                        ? AppColors.statusWarning
                        : null,
                    fontWeight: activeSeverity == AlertSeverity.warning
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),

                // Resolved Filter
                FilterChip(
                  label: const Text('Resolved'),
                  selected: activeResolved == true,
                  onSelected: (selected) {
                    ref.read(alertFilterResolvedProvider.notifier).setResolved(
                        selected ? true : null);
                    ref.read(alertFilterSeverityProvider.notifier).setSeverity(null);
                  },
                  labelStyle: AppTypography.caption.copyWith(
                    color: activeResolved == true ? AppColors.statusNormal : null,
                    fontWeight:
                        activeResolved == true ? FontWeight.w600 : FontWeight.w400,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(),

          // Alerts List
          Expanded(
            child: alertsAsync.when(
              data: (_) {
                if (filteredAlerts.isEmpty) {
                  return EmptyStateView.noAlerts();
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredAlerts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return AlertCard(alert: filteredAlerts[index]);
                  },
                );
              },
              loading: () => const LoadingStateView(
                message: 'Fetching alert records...',
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading alerts: $err',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.statusCritical,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
