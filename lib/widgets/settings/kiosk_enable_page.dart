import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';

class KioskEnablePage extends StatelessWidget {
  const KioskEnablePage({super.key});

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
        title: const Text('Enable Kiosk for...'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: FocusTraversalGroup(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _tile(context, '15 minutes', const Duration(minutes: 15), autofocus: true),
                _tile(context, '1 hour', const Duration(hours: 1)),
                _tile(context, '4 hours', const Duration(hours: 4)),
                _tile(context, 'Lock', null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, Duration? duration,
      {bool autofocus = false}) {
    return FocusableSettingsTile(
      autofocus: autofocus,
      leading: Icon(duration == null ? Icons.lock : Icons.timer_outlined),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      onPressed: () async {
        final settings = context.read<SettingsService>();
        if (duration == null) {
          await settings.setKioskEnabled(true);
        } else {
          await settings.setKioskEnabled(true, expiresAt: DateTime.now().add(duration));
        }
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
