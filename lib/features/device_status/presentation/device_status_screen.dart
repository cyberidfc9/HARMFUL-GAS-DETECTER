import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/data_freshness_indicator.dart';
import '../../../data/models/device_state.dart';
import '../../../data/models/sensor_reading.dart';
import '../../dashboard/providers/device_providers.dart';
import '../../settings/providers/settings_providers.dart';

class DeviceStatusScreen extends ConsumerWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final deviceId = ref.watch(deviceIdProvider);
    final heartbeatTimeout = ref.watch(heartbeatTimeoutProvider);
    final deviceStateAsync = ref.watch(deviceStateStreamProvider);
    final isConnectedAsync = ref.watch(databaseConnectionProvider);

    final deviceState = deviceStateAsync.value ?? DeviceState.empty(deviceId);
    final connectionStatus = deviceState.getConnectionStatus(
      heartbeatTimeoutSeconds: heartbeatTimeout,
    );
    final isRtdbConnected = isConnectedAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Status'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Device Identity Card
          Container(
            padding: const EdgeInsets.all(18),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'DEVICE TELEMETRY',
                        style: AppTypography.caption.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.fromConnectionStatus(
                      connectionStatus,
                      isDarkMode: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  deviceState.deviceId,
                  style: AppTypography.measurementMedium.copyWith(
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                DataFreshnessIndicator(
                  lastSeen: deviceState.lastSeen,
                  isOffline: connectionStatus == DeviceConnectionStatus.offline,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Diagnostic Attributes Card
          Container(
            padding: const EdgeInsets.all(18),
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
                Text(
                  'CONNECTIVITY & HEARTBEAT',
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),

                // RTDB WebSocket State
                _buildInfoRow(
                  label: 'Firebase RTDB Client',
                  value: isRtdbConnected ? 'Connected (Live Socket)' : 'Connecting / Idle',
                  valueColor: isRtdbConnected ? AppColors.statusNormal : AppColors.statusWarning,
                  textSecondary: textSecondary,
                ),
                const Divider(height: 20),

                // Heartbeat Last Seen
                _buildInfoRow(
                  label: 'Last Recorded Heartbeat',
                  value: deviceState.lastSeen != null
                      ? DateFormatter.formatShortDateTime(deviceState.lastSeen)
                      : 'None recorded',
                  textSecondary: textSecondary,
                ),
                const Divider(height: 20),

                // Heartbeat Timeout Window
                _buildInfoRow(
                  label: 'Heartbeat Timeout Window',
                  value: '$heartbeatTimeout seconds',
                  textSecondary: textSecondary,
                ),
                const Divider(height: 20),

                // Firmware Version
                _buildInfoRow(
                  label: 'Firmware Version',
                  value: deviceState.firmwareVersion ?? 'ESP32 GasSense v1.0.0',
                  textSecondary: textSecondary,
                ),
                if (deviceState.ipAddress != null) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    label: 'Local Network IP',
                    value: deviceState.ipAddress!,
                    textSecondary: textSecondary,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Attached Sensor Hardware Status
          Container(
            padding: const EdgeInsets.all(18),
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
                Text(
                  'SENSOR SUBSYSTEM STATUS',
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),

                // MQ-2
                _buildSensorRow(
                  sensor: SensorType.mq2,
                  reading: deviceState.sensors[SensorType.mq2],
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
                const Divider(height: 20),

                // MQ-7
                _buildSensorRow(
                  sensor: SensorType.mq7,
                  reading: deviceState.sensors[SensorType.mq7],
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
                const Divider(height: 20),

                // MQ-135
                _buildSensorRow(
                  sensor: SensorType.mq135,
                  reading: deviceState.sensors[SensorType.mq135],
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppTypography.bodyRegular.copyWith(
              color: textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorRow({
    required SensorType sensor,
    required SensorReading? reading,
    required bool isDark,
    required Color textSecondary,
  }) {
    final hasData = reading != null && reading.hasData;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sensor.displayName,
                style: AppTypography.cardTitle.copyWith(fontSize: 14),
              ),
              Text(
                sensor.targetGasLabel,
                style: AppTypography.caption.copyWith(
                  color: textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge.sensorState(
          hasData: hasData,
          classification: reading?.statusClassification,
          isDarkMode: isDark,
        ),
      ],
    );
  }
}
