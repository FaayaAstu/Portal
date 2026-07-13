/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */


import 'dart:async';

import 'package:flauncher/actions.dart';
import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/kiosk_home.dart';
import 'package:flauncher/widgets/kiosk_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FLauncher extends StatefulWidget {
  const FLauncher({super.key});

  @override
  State<FLauncher> createState() => _FLauncherState();
}

class _FLauncherState extends State<FLauncher> with WidgetsBindingObserver {
  final GlobalKey<FocusAwareAppBarState> _appBarKey = GlobalKey();
  static bool _coldBootHandled = false;
  bool _kioskBypassed = false;

  Timer? _kioskExpiryTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsService>(context, listen: false);
      settings.enforceKioskExpiry();
      if (!_coldBootHandled) {
        _coldBootHandled = true;
        final pkg = settings.autoLaunchPackage;
        if (pkg != null && pkg.isNotEmpty) {
          FLauncherChannel().launchApp(pkg);
        }
      }
    });
    _kioskExpiryTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      Provider.of<SettingsService>(context, listen: false).enforceKioskExpiry();
    });
  }

  @override
  void dispose() {
    _kioskExpiryTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Kiosk timer may have expired while we were backgrounded.
    Provider.of<SettingsService>(context, listen: false).enforceKioskExpiry();
    // Re-arm the overlay after any return from an app.
    if (_kioskBypassed) {
      setState(() => _kioskBypassed = false);
    }
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      MoveFocusToSettingsIntent: CallbackAction<MoveFocusToSettingsIntent>(
        onInvoke: (_) => _appBarKey.currentState?.focusSettings(),
      ),
    },
    child: FocusTraversalGroup(
      policy: RowByRowTraversalPolicy(),
      child: Stack(
        children: [
          RepaintBoundary(
            child: Consumer<WallpaperService>(
              builder: (_, wallpaperService, __) => _wallpaper(context, wallpaperService)
            ),
          ),
          const KioskHome(),
          Consumer<SettingsService>(
            builder: (_, settings, __) => (settings.kioskEnabled && !_kioskBypassed)
                ? Positioned.fill(
                    child: KioskOverlay(
                      onUnlock: () => setState(() => _kioskBypassed = true),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ]
      )
    ),
  );

  Widget _wallpaper(BuildContext context, WallpaperService wallpaperService) {
    if (wallpaperService.wallpaper != null) {
      final physicalSize = MediaQuery.sizeOf(context);
      return Image(
        image: wallpaperService.wallpaper!,
        key: Key("background_${wallpaperService.version}"),
        fit: BoxFit.cover,
        height: physicalSize.height,
        width: physicalSize.width
      );
    }
    else {
      return Container(key: const Key("background"), decoration: BoxDecoration(gradient: wallpaperService.gradient.gradient));
    }
  }
}
