import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Blocks the launcher when kiosk mode is on. Auto-returns to the target
/// after a short window; the operator can enter the PIN to disable kiosk.
class KioskOverlay extends StatefulWidget {
  const KioskOverlay({super.key});

  @override
  State<KioskOverlay> createState() => _KioskOverlayState();
}

class _KioskOverlayState extends State<KioskOverlay> {
  static const _autoReturnDelay = Duration(seconds: 15);

  final FocusNode _focusNode = FocusNode();
  final _channel = FLauncherChannel();
  String _entered = '';
  String? _error;
  Timer? _autoReturn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _scheduleAutoReturn();
  }

  @override
  void dispose() {
    _autoReturn?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleAutoReturn() {
    _autoReturn?.cancel();
    _autoReturn = Timer(_autoReturnDelay, _returnToTarget);
  }

  void _returnToTarget() {
    final settings = context.read<SettingsService>();
    final pkg = settings.autoLaunchPackage;
    if (pkg != null && pkg.isNotEmpty) {
      _channel.launchApp(pkg);
    }
  }

  void _onDigit(String d) {
    _autoReturn?.cancel();
    setState(() {
      _entered = (_entered + d);
      _error = null;
    });
    final settings = context.read<SettingsService>();
    if (_entered.length >= settings.kioskPin.length) {
      _submit();
    } else {
      _scheduleAutoReturn();
    }
  }

  void _submit() {
    final settings = context.read<SettingsService>();
    if (_entered == settings.kioskPin) {
      settings.setKioskEnabled(false);
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _entered = '';
      });
      _scheduleAutoReturn();
    }
  }

  void _clear() {
    setState(() => _entered = '');
    _scheduleAutoReturn();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final settings = context.read<SettingsService>();
    final key = event.logicalKey;

    if (key.keyLabel.length == 1 &&
        key.keyLabel.codeUnitAt(0) >= 0x30 &&
        key.keyLabel.codeUnitAt(0) <= 0x39) {
      _onDigit(key.keyLabel);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      if (_entered.isNotEmpty) {
        setState(() => _entered = _entered.substring(0, _entered.length - 1));
        _scheduleAutoReturn();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      _returnToTarget();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      if (_entered.length == settings.kioskPin.length) _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final pinLength = context.watch<SettingsService>().kioskPin.length;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              Text('Kiosk Mode', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Enter PIN to unlock',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.white : Colors.transparent,
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 1; i <= 9; i++) _digitButton('$i'),
                  const SizedBox(width: 60, height: 40),
                  _digitButton('0'),
                  SizedBox(
                    width: 60,
                    child: TextButton(
                      onPressed: _clear,
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _returnToTarget,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to app'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digitButton(String d) => SizedBox(
        width: 60,
        height: 40,
        child: OutlinedButton(
          onPressed: () => _onDigit(d),
          child: Text(d, style: const TextStyle(fontSize: 18)),
        ),
      );
}
