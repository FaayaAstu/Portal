import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/apps_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Simple, elegant kiosk-first home. Brand + one big CTA that launches
/// the auto-launch target. Corner cluster: clock, network, settings.
class KioskHome extends StatefulWidget {
  const KioskHome({super.key});

  @override
  State<KioskHome> createState() => _KioskHomeState();
}

class _KioskHomeState extends State<KioskHome> {
  final _channel = FLauncherChannel();
  Timer? _clockTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTicker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  void _openTarget() {
    final settings = context.read<SettingsService>();
    final pkg = settings.autoLaunchPackage;
    if (pkg != null && pkg.isNotEmpty) {
      _channel.launchApp(pkg);
    }
  }

  void _openSettings() {
    showDialog(context: context, builder: (_) => const SettingsPanel());
  }

  void _openAllApps() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final brand = settings.brandName;
    final hasTarget = (settings.autoLaunchPackage ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: 20,
            right: 24,
            child: _CornerCluster(
              now: _now,
              onSettings: _openSettings,
              onAllApps: _openAllApps,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  brand,
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                if (hasTarget)
                  _OpenButton(
                    label: 'Open $brand',
                    onPressed: _openTarget,
                  )
                else
                  Text(
                    'Set an auto-launch app in Kiosk settings.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerCluster extends StatelessWidget {
  final DateTime now;
  final VoidCallback onSettings;
  final VoidCallback onAllApps;

  const _CornerCluster({
    required this.now,
    required this.onSettings,
    required this.onAllApps,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(now);
    return Row(
      children: [
        Text(
          time,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        Consumer<NetworkService>(
          builder: (_, net, __) => Icon(
            _networkIcon(net),
            size: 18,
            color: Colors.white.withValues(alpha: net.hasInternetAccess ? 0.7 : 0.3),
          ),
        ),
        const SizedBox(width: 12),
        _IconButton(icon: Icons.apps, onPressed: onAllApps),
        const SizedBox(width: 4),
        _IconButton(icon: Icons.settings_outlined, onPressed: onSettings),
      ],
    );
  }

  IconData _networkIcon(NetworkService net) {
    if (!net.hasInternetAccess) return Icons.signal_wifi_off;
    switch (net.networkType) {
      case NetworkType.Wifi:
        return Icons.wifi;
      case NetworkType.Wired:
        return Icons.settings_ethernet;
      case NetworkType.Cellular:
        return Icons.signal_cellular_alt;
      case NetworkType.Vpn:
        return Icons.vpn_key;
      case NetworkType.Unknown:
        return Icons.signal_wifi_statusbar_null;
    }
  }
}

class _OpenButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _OpenButton({required this.label, required this.onPressed});

  @override
  State<_OpenButton> createState() => _OpenButtonState();
}

class _OpenButtonState extends State<_OpenButton> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final active = _focused;
    return Focus(
      autofocus: true,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 22),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? Colors.white : Colors.white24,
              width: 2,
            ),
            boxShadow: active
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded,
                  color: active ? Colors.black : Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: active ? Colors.black : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _focused ? Colors.white : Colors.transparent,
            border: Border.all(
              color: _focused ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: _focused ? Colors.black : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
