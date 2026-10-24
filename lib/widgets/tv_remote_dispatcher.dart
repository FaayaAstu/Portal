import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/remote_event.dart';
import 'package:flauncher/providers/tv_remote_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Receives RemoteEvents from the Faayaverse phone remote and drives Portal.
// Navigation keys are routed through Flutter's FocusManager / Actions chain so
// the behaviour matches a real D-pad press. Keyboard characters are injected
// via the standard `flutter/keyevent` platform channel.
class TvRemoteDispatcher extends StatefulWidget {
  final Widget child;
  const TvRemoteDispatcher({super.key, required this.child});

  @override
  State<TvRemoteDispatcher> createState() => _TvRemoteDispatcherState();
}

class _TvRemoteDispatcherState extends State<TvRemoteDispatcher> {
  StreamSubscription? _subscription;
  final FLauncherChannel _channel = FLauncherChannel();

  @override
  void initState() {
    super.initState();
    final service = Provider.of<TvRemoteService>(context, listen: false);
    _subscription = service.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onEvent(RemoteEvent event) {
    if (!mounted) return;
    switch (event) {
      case DPadEvent():
        _moveFocus(event.direction);
      case SelectEvent():
        _activate();
      case BackEvent():
        _back();
      case MenuEvent():
        _invoke(const ActivateIntent());
      case KeyboardEvent():
        _onKeyboard(event);
      case NavigateEvent():
        _onNavigate(event);
      case HomeEvent():
      case PlayPauseEvent():
      case VolumeUpEvent():
      case VolumeDownEvent():
      case MuteEvent():
      case ChannelUpEvent():
      case ChannelDownEvent():
      case SearchEvent():
      case PowerEvent():
      case InfoEvent():
      case VoiceEvent():
      case RawEvent():
        break;
    }
  }

  void _moveFocus(RemoteDirection direction) {
    final focus = FocusManager.instance.primaryFocus;
    switch (direction) {
      case RemoteDirection.up:
        focus?.focusInDirection(TraversalDirection.up);
      case RemoteDirection.down:
        focus?.focusInDirection(TraversalDirection.down);
      case RemoteDirection.left:
        focus?.focusInDirection(TraversalDirection.left);
      case RemoteDirection.right:
        focus?.focusInDirection(TraversalDirection.right);
    }
  }

  void _activate() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context ?? context;
    Actions.maybeInvoke<ActivateIntent>(ctx, const ActivateIntent());
  }

  void _back() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context ?? context;
    final nav = Navigator.maybeOf(ctx);
    if (nav != null && nav.canPop()) {
      nav.maybePop();
    }
  }

  void _invoke(Intent intent) {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context ?? context;
    Actions.maybeInvoke(ctx, intent);
  }

  void _onKeyboard(KeyboardEvent event) {
    final c = event.keyChar;
    if (c != null && c.isNotEmpty) {
      for (final rune in c.runes) {
        _injectAndroidKey(_androidKeyCodeForCodePoint(rune), rune);
      }
      return;
    }
    // Raw Android keyCodes for the common text-editing keys.
    _injectAndroidKey(event.keyCode, 0);
  }

  // Resolve an Android KeyEvent keyCode for a Unicode code point. We only need
  // digits + a-z here; everything else falls back to 0 and relies on
  // `codePoint` to carry the character through to EditableText.
  int _androidKeyCodeForCodePoint(int cp) {
    if (cp >= 0x30 && cp <= 0x39) return 7 + (cp - 0x30); // 0..9 → KEYCODE_0..9
    if (cp >= 0x61 && cp <= 0x7A) return 29 + (cp - 0x61); // a..z → KEYCODE_A..Z
    if (cp >= 0x41 && cp <= 0x5A) return 29 + (cp - 0x41); // A..Z
    if (cp == 0x20) return 62; // space
    return 0;
  }

  // Post a key-down + key-up pair onto `flutter/keyevent`, which is the same
  // channel the Android embedder uses for hardware keys. Flutter's own
  // KeyEventManager picks it up and routes through Focus/Shortcuts.
  void _injectAndroidKey(int keyCode, int codePoint) {
    for (final type in ['keydown', 'keyup']) {
      final msg = <String, dynamic>{
        'keymap': 'android',
        'flags': 0,
        'codePoint': codePoint,
        'keyCode': keyCode,
        'plainCodePoint': codePoint,
        'scanCode': 0,
        'metaState': 0,
        'source': 0x101, // SOURCE_KEYBOARD
        'deviceId': 0,
        'repeatCount': 0,
        'type': type,
      };
      final data = const JSONMessageCodec().encodeMessage(msg);
      ServicesBinding.instance.channelBuffers.push(
        'flutter/keyevent',
        data,
        (_) {},
      );
    }
  }

  Future<void> _onNavigate(NavigateEvent event) async {
    switch (event.screen) {
      case 'portal.android_settings':
        await _channel.openSettings();
      case 'portal.app_info':
        final pkg = event.params['package'];
        if (pkg != null && pkg.isNotEmpty) {
          await _channel.openAppInfo(pkg);
        }
      case 'portal.portal_settings':
      case 'portal.settings':
        await _channel.openDefaultLauncherSettings();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
