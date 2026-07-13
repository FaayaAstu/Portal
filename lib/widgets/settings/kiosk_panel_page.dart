import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'auto_launch_page.dart';
import 'brand_name_page.dart';
import 'focusable_settings_tile.dart';
import 'kiosk_enable_page.dart';
import 'pin_change_page.dart';

class KioskPanelPage extends StatelessWidget {
  static const String routeName = "kiosk_panel";

  const KioskPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Kiosk', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Consumer<SettingsService>(
                  builder: (context, settings, _) => FocusableSettingsTile(
                    autofocus: true,
                    leading: const Icon(Icons.rocket_launch),
                    title: Text('Auto-Launch on Boot', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Text(
                      settings.autoLaunchPackage ?? 'None',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onPressed: () => Navigator.of(context).pushNamed(AutoLaunchPage.routeName),
                  ),
                ),
                Consumer<SettingsService>(
                  builder: (context, settings, _) => FocusableSettingsTile(
                    leading: const Icon(Icons.lock),
                    title: Text('Kiosk Mode', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Text(
                      _kioskStatus(settings),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: settings.kioskEnabled ? Colors.green : Colors.grey,
                          ),
                    ),
                    onPressed: () => settings.kioskEnabled
                        ? _confirmDisableKiosk(context, settings)
                        : _pickDurationAndEnable(context, settings),
                  ),
                ),
                Consumer<SettingsService>(
                  builder: (context, settings, _) => FocusableSettingsTile(
                    leading: const Icon(Icons.pin),
                    title: Text('Change Kiosk PIN', style: Theme.of(context).textTheme.bodyMedium),
                    onPressed: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const PinChangePage()),
                    ),
                  ),
                ),
                Consumer<SettingsService>(
                  builder: (context, settings, _) => FocusableSettingsTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text('Brand Name', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Text(
                      settings.brandName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onPressed: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const BrandNamePage()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _kioskStatus(SettingsService settings) {
    if (!settings.kioskEnabled) return 'Off';
    final expiresAt = settings.kioskExpiresAt;
    if (expiresAt == null) return 'On';
    return 'On until ${DateFormat.jm().format(expiresAt.toLocal())}';
  }

  Future<void> _pickDurationAndEnable(BuildContext context, SettingsService settings) async {
    final target = settings.autoLaunchPackage;
    if (target == null || target.isEmpty) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const _NeedsAutoLaunchPage()),
      );
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const KioskEnablePage()),
    );
  }

  Future<void> _confirmDisableKiosk(BuildContext context, SettingsService settings) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const _DisableKioskPage()),
    );
  }
}

class _NeedsAutoLaunchPage extends StatelessWidget {
  const _NeedsAutoLaunchPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Set Auto-Launch first'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kiosk Mode requires an auto-launch app. Pick one under "Auto-Launch on Boot".',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FocusableActionButton(
              autofocus: true,
              label: 'OK',
              primary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisableKioskPage extends StatelessWidget {
  const _DisableKioskPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Disable Kiosk Mode?'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'The launcher will be reachable without a PIN until you re-enable kiosk.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FocusableActionButton(
                      autofocus: true,
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FocusableActionButton(
                      label: 'Disable',
                      primary: true,
                      onPressed: () async {
                        await context.read<SettingsService>().setKioskEnabled(false);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
