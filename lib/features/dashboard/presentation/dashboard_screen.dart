import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/sensor_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/data_freshness_indicator.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_state_view.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/models/device_state.dart';
import '../providers/device_providers.dart';
import '../../settings/providers/settings_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceId = ref.watch(deviceIdProvider);
    final heartbeatTimeout = ref.watch(heartbeatTimeoutProvider);
    final deviceStateAsync = ref.watch(deviceStateStreamProvider);
    final latestAlert = ref.watch(latestActiveAlertProvider);
    final isConnectedAsync = ref.watch(databaseConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GAS MONITOR',
              style: AppTypography.sectionTitle.copyWith(
                letterSpacing: 0.5,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Device: $deviceId',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isConnectedAsync.value ?? false)
                        ? AppColors.statusNormal
                        : AppColors.statusOffline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  (isConnectedAsync.value ?? false) ? 'RTDB Live' : 'Connecting',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Device Status',
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => context.push('/device-status'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: deviceStateAsync.when(
        data: (deviceState) {
          final connectionStatus = deviceState.getConnectionStatus(
            heartbeatTimeoutSeconds: heartbeatTimeout,
          );
          final mq2 = deviceState.sensors[SensorType.mq2] ??
              const SensorReading(type: SensorType.mq2, valid: false);
          final mq7 = deviceState.sensors[SensorType.mq7] ??
              const SensorReading(type: SensorType.mq7, valid: false);
          final mq135 = deviceState.sensors[SensorType.mq135] ??
              const SensorReading(type: SensorType.mq135, valid: false);

          final hasAnyData = mq2.hasData || mq7.hasData || mq135.hasData;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(deviceStateStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Top Telemetry Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge.fromConnectionStatus(
                            connectionStatus,
                            isDarkMode: isDark,
                          ),
                          DataFreshnessIndicator(
                            lastSeen: deviceState.lastSeen,
                            isOffline:
                                connectionStatus == DeviceConnectionStatus.offline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last Sync:',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              deviceState.lastSeen != null
                                  ? DateFormatter.formatShortDateTime(deviceState.lastSeen)
                                  : 'Waiting for initial signal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTypography.monoLabel.copyWith(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Latest Active Alert Banner (Section 10.2: Latest active alert, if one exists)
                if (latestAlert != null) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.go('/alerts'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.statusCriticalBgDark.withValues(alpha: 0.3)
                            : AppColors.statusCriticalBgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.statusCritical.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.statusCritical,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACTIVE ALERT: ${latestAlert.message}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.statusCritical,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (latestAlert.recordedValue != null)
                                  Text(
                                    'Value: ${latestAlert.recordedValue} ${latestAlert.measurementType ?? ""}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.statusCritical,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.statusCritical,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Section Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE SENSORS',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '3 Configured',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // If completely empty with zero data received
                if (!hasAnyData &&
                    connectionStatus == DeviceConnectionStatus.unknown) ...[
                  EmptyStateView.waitingForDevice(
                    deviceId: deviceId,
                    onRefresh: () => ref.invalidate(deviceStateStreamProvider),
                  ),
                ] else ...[
                  // 3 Sensor Cards
                  SensorCard(
                    reading: mq2,
                    onTap: () => context.push('/sensor/mq2'),
                  ),
                  const SizedBox(height: 12),
                  SensorCard(
                    reading: mq7,
                    onTap: () => context.push('/sensor/mq7'),
                  ),
                  const SizedBox(height: 12),
                  SensorCard(
                    reading: mq135,
                    onTap: () => context.push('/sensor/mq135'),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const LoadingStateView(
          message: 'Connecting to ESP32 telemetry stream...',
        ),
        error: (err, stack) => ErrorStateView(
          title: 'Database Sync Error',
          message: err.toString(),
          onRetry: () => ref.invalidate(deviceStateStreamProvider),
        ),
      ),
    );
  }
}
