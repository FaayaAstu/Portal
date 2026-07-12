import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';

class AutoLaunchPage extends StatelessWidget {
  static const String routeName = "auto_launch_panel";

  const AutoLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Auto-Launch on Boot', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: Consumer2<SettingsService, AppsService>(
            builder: (context, settings, apps, _) {
              final current = settings.autoLaunchPackage;
              final list = apps.applications;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    FocusableSettingsTile(
                      autofocus: current == null,
                      leading: const Icon(Icons.block),
                      title: Text('None', style: Theme.of(context).textTheme.bodyMedium),
                      trailing: current == null
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onPressed: () => settings.setAutoLaunchPackage(null),
                    ),
                    for (final app in list)
                      FocusableSettingsTile(
                        autofocus: current == app.packageName,
                        leading: const Icon(Icons.apps),
                        title: Text(app.name, style: Theme.of(context).textTheme.bodyMedium),
                        trailing: current == app.packageName
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onPressed: () => settings.setAutoLaunchPackage(app.packageName),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
