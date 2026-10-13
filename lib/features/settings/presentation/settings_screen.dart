import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _deviceController;
  late TextEditingController _customPathController;

  @override
  void initState() {
    super.initState();
    final deviceId = ref.read(deviceIdProvider);
    final customPath = ref.read(customPathProvider);
    _deviceController = TextEditingController(text: deviceId);
    _customPathController = TextEditingController(text: customPath);
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _customPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final themeMode = ref.watch(themeModeProvider);
    final heartbeatTimeout = ref.watch(heartbeatTimeoutProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Appearance
          _buildSectionHeader('APPEARANCE', textSecondary),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined, size: 16),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (newSelection) {
                  ref.read(themeModeProvider.notifier).setTheme(newSelection.first);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Section: Hardware Configuration
          _buildSectionHeader('HARDWARE CONNECTION', textSecondary),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Device Identifier',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Database path: devices/{deviceId}/current',
                  style: AppTypography.caption.copyWith(color: textSecondary),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deviceController,
                  decoration: InputDecoration(
                    hintText: 'e.g. esp32_gas_01',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () {
                        ref
                            .read(deviceIdProvider.notifier)
                            .setDeviceId(_deviceController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Device ID updated')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Custom RTDB Path Override (Optional)',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave blank to use default devices/{deviceId}/current',
                  style: AppTypography.caption.copyWith(color: textSecondary),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customPathController,
                  decoration: InputDecoration(
                    hintText: 'e.g. current or gas_monitor',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () {
                        ref.read(customPathProvider.notifier).setPath(
                            _customPathController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Custom path updated')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heartbeat Threshold', style: AppTypography.bodyMedium),
                          Text(
                            'Mark offline if no signal received',
                            style: AppTypography.caption.copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: heartbeatTimeout,
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('60 sec')),
                        DropdownMenuItem(value: 90, child: Text('90 sec')),
                        DropdownMenuItem(value: 180, child: Text('3 min')),
                        DropdownMenuItem(value: 300, child: Text('5 min')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(heartbeatTimeoutProvider.notifier).setTimeout(val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section: Notifications
          _buildSectionHeader('NOTIFICATIONS', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: SwitchListTile(
              title: const Text('Safety Notifications'),
              subtitle: Text(
                'Receive alerts when threshold limits are triggered',
                style: AppTypography.caption.copyWith(color: textSecondary),
              ),
              value: notificationsEnabled,
              onChanged: (val) {
                ref.read(notificationsEnabledProvider.notifier).setEnabled(val);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Section: About & Specifications
          _buildSectionHeader('BACKEND & SPECIFICATIONS', textSecondary),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoLine(
                  'Project ID',
                  'gasmonitoringsystem-77db2',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  'RTDB Endpoint',
                  'gasmonitoringsystem-77db2-default-rtdb',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  'Supported Hardware',
                  'ESP32 + MQ-2 + MQ-7 + MQ-135',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  'Policy',
                  'Zero Demo Data Policy Enforced',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  'App Version',
                  '1.0.0 (Release Build)',
                  textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfoLine(String label, String value, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoLabel.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
