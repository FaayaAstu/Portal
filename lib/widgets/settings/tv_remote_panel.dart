import 'package:flauncher/providers/tv_remote_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';

class TvRemotePanelPage extends StatelessWidget {
  static const String routeName = "tv_remote_panel";

  const TvRemotePanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('TV Remote', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: Consumer<TvRemoteService>(
            builder: (context, service, _) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FocusableSettingsTile(
                    autofocus: true,
                    leading: const Icon(Icons.settings_remote),
                    title: Text('Enable remote', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Text(
                      service.enabled ? (service.running ? 'On' : 'Starting…') : 'Off',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: service.enabled && service.running ? Colors.green : Colors.grey,
                          ),
                    ),
                    onPressed: () => service.setEnabled(!service.enabled),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Device name', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(service.deviceName, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Text('Device ID', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(service.deviceId, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Text('Port', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('${service.port}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Text(
                          'Pair this device from the Faayaverse phone app → TV switcher.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
