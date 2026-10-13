import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  factory EmptyStateView.waitingForDevice({
    required String deviceId,
    VoidCallback? onRefresh,
  }) {
    return EmptyStateView(
      icon: Icons.sensors_off_outlined,
      title: 'Waiting for Sensor Telemetry',
      message:
          'No readings have been received from ESP32 ($deviceId). Ensure the device is powered, connected to Wi-Fi, and publishing to Firebase.',
      action: onRefresh != null
          ? OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Check Connection'),
            )
          : null,
    );
  }

  factory EmptyStateView.noHistory({required String sensorName}) {
    return EmptyStateView(
      icon: Icons.show_chart_rounded,
      title: 'Insufficient Historical Data',
      message:
          'No valid $sensorName records were recorded within the selected time window. Charts and analytics will automatically plot when new telemetry arrives.',
    );
  }

  factory EmptyStateView.noAlerts() {
    return const EmptyStateView(
      icon: Icons.notifications_none_rounded,
      title: 'No Alerts Recorded',
      message:
          'No threshold violations or safety alert records have been published by the monitoring rules.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyRegular.copyWith(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
