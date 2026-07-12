import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auto_launch_page.dart';
import 'focusable_settings_tile.dart';

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
                      settings.kioskEnabled ? 'On' : 'Off',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: settings.kioskEnabled ? Colors.green : Colors.grey,
                          ),
                    ),
                    onPressed: () => _confirmEnableKiosk(context, settings),
                  ),
                ),
                Consumer<SettingsService>(
                  builder: (context, settings, _) => FocusableSettingsTile(
                    leading: const Icon(Icons.pin),
                    title: Text('Change Kiosk PIN', style: Theme.of(context).textTheme.bodyMedium),
                    onPressed: () => _changePinDialog(context, settings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmEnableKiosk(BuildContext context, SettingsService settings) async {
    if (settings.kioskEnabled) return;
    final target = settings.autoLaunchPackage;
    if (target == null || target.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set Auto-Launch first'),
          content: const Text('Kiosk Mode requires an auto-launch app. Pick one under "Auto-Launch on Boot".'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Kiosk Mode?'),
        content: Text(
          'Once enabled, the launcher will only be reachable by entering the PIN. '
          'Current PIN: ${settings.kioskPin} (change under "Change Kiosk PIN").',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enable')),
        ],
      ),
    );
    if (ok == true) {
      await settings.setKioskEnabled(true);
    }
  }

  Future<void> _changePinDialog(BuildContext context, SettingsService settings) async {
    final controller = TextEditingController();
    String? error;
    final ok = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Change Kiosk PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New PIN (4-8 digits)'),
              ),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final v = controller.text;
                if (v.length < 4 || v.length > 8 || int.tryParse(v) == null) {
                  setState(() => error = 'PIN must be 4-8 digits');
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != null) await settings.setKioskPin(ok);
  }
}
