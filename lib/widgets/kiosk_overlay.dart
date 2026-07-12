import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Blocks the launcher when kiosk mode is on. Auto-returns to the target
/// after a short window; the operator can enter the PIN to disable kiosk.
class KioskOverlay extends StatefulWidget {
  /// Called when the operator enters the correct PIN. Caller decides
  /// what "unlocked" means — one-shot bypass, permanent disable, etc.
  final VoidCallback onUnlock;

  const KioskOverlay({super.key, required this.onUnlock});

  @override
  State<KioskOverlay> createState() => _KioskOverlayState();
}

class _KioskOverlayState extends State<KioskOverlay> with WidgetsBindingObserver {
  static const _autoReturnDelay = Duration(seconds: 15);

  final _channel = FLauncherChannel();
  final _scopeNode = FocusScopeNode(debugLabel: 'KioskOverlay');
  String _entered = '';
  String? _error;
  Timer? _autoReturn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleAutoReturn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).setFirstFocus(_scopeNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoReturn?.cancel();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't try to relaunch target from the background — Android blocks it.
    if (state != AppLifecycleState.resumed) {
      _autoReturn?.cancel();
    } else {
      _scheduleAutoReturn();
    }
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
    final settings = context.read<SettingsService>();
    setState(() {
      _entered = _entered + d;
      _error = null;
    });
    _scheduleAutoReturn();
    if (_entered.length >= settings.kioskPin.length) {
      _submit();
    }
  }

  void _submit() {
    final settings = context.read<SettingsService>();
    if (_entered == settings.kioskPin) {
      _autoReturn?.cancel();
      widget.onUnlock();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _entered = '';
      });
      _scheduleAutoReturn();
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
    _scheduleAutoReturn();
  }

  @override
  Widget build(BuildContext context) {
    final pinLength = context.watch<SettingsService>().kioskPin.length;
    return FocusScope(
      node: _scopeNode,
      autofocus: true,
      child: Material(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 56, color: Colors.white70),
              const SizedBox(height: 12),
              Text('Kiosk Mode',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Enter PIN to unlock',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white54)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.white : Colors.transparent,
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 20,
                child: _error != null
                    ? Text(_error!,
                        style: const TextStyle(color: Colors.redAccent))
                    : null,
              ),
              const SizedBox(height: 12),
              FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: _numpad(),
              ),
              const SizedBox(height: 16),
              _PadButton(
                label: 'Return to app',
                icon: Icons.arrow_back,
                onPressed: _returnToTarget,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _numpad() {
    Widget cell(Widget child) => SizedBox(width: 80, height: 56, child: child);
    Widget digit(String d, {bool autofocus = false}) => cell(
          _PadButton(
            label: d,
            autofocus: autofocus,
            onPressed: () => _onDigit(d),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          digit('1', autofocus: true),
          digit('2'),
          digit('3'),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          digit('4'),
          digit('5'),
          digit('6'),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          digit('7'),
          digit('8'),
          digit('9'),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          cell(_PadButton(
            label: '⌫',
            onPressed: _backspace,
          )),
          digit('0'),
          cell(_PadButton(
            label: 'Clear',
            onPressed: () {
              setState(() => _entered = '');
              _scheduleAutoReturn();
            },
          )),
        ]),
      ],
    );
  }
}

class _PadButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool autofocus;

  const _PadButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.autofocus = false,
  });

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA ||
        k == LogicalKeyboardKey.space) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final active = _focused;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: _onKey,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? Colors.white : Colors.white24,
                width: 2,
              ),
            ),
            child: widget.icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon,
                          color: active ? Colors.black : Colors.white,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(widget.label,
                          style: TextStyle(
                            color: active ? Colors.black : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  )
                : Text(widget.label,
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ),
      ),
    );
  }
}
