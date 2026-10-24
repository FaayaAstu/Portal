import 'dart:async';
import 'dart:convert';

import 'package:flauncher/models/remote_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Faayaverse TV-remote server, wrapped. Lifecycle + device metadata live natively
// (see TvRemoteController.kt); this class is the Dart handle Flutter widgets talk to.
class TvRemoteService extends ChangeNotifier {
  static const _method = MethodChannel('me.efesser.flauncher/tv_remote');
  static const _events = EventChannel('me.efesser.flauncher/tv_remote_events');
  static const _enabledKey = 'tv_remote_enabled';

  final SharedPreferences _prefs;
  final StreamController<RemoteEvent> _controller = StreamController.broadcast();
  StreamSubscription? _subscription;

  bool _enabled;
  bool _running = false;
  String _deviceId = '';
  String _deviceName = '';
  int _port = 8080;

  TvRemoteService(this._prefs) : _enabled = _prefs.getBool(_enabledKey) ?? true {
    _init();
  }

  Stream<RemoteEvent> get events => _controller.stream;
  bool get enabled => _enabled;
  bool get running => _running;
  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  int get port => _port;

  Future<void> _init() async {
    _subscription = _events.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object e) => debugPrint('tv_remote stream error: $e'),
    );
    await _refreshInfo();
    if (_enabled) {
      await _startNative();
    }
  }

  void _onNativeEvent(dynamic payload) {
    if (payload is! String) return;
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      _controller.add(RemoteEvent.fromJson(decoded));
    } catch (e) {
      debugPrint('tv_remote decode failed: $e');
    }
  }

  Future<void> _refreshInfo() async {
    try {
      final info = await _method.invokeMapMethod<String, dynamic>('getDeviceInfo');
      if (info == null) return;
      _deviceId = info['deviceId'] as String? ?? '';
      _deviceName = info['deviceName'] as String? ?? '';
      _port = (info['port'] as int?) ?? 8080;
      _running = info['running'] as bool? ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('getDeviceInfo failed: $e');
    }
  }

  Future<void> _startNative() async {
    try {
      await _method.invokeMethod('start');
      await _refreshInfo();
    } catch (e) {
      debugPrint('tv_remote start failed: $e');
    }
  }

  Future<void> _stopNative() async {
    try {
      await _method.invokeMethod('stop');
      await _refreshInfo();
    } catch (e) {
      debugPrint('tv_remote stop failed: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    await _prefs.setBool(_enabledKey, value);
    if (value) {
      await _startNative();
    } else {
      await _stopNative();
    }
    notifyListeners();
  }

  Future<void> setDeviceName(String name) async {
    try {
      await _method.invokeMethod('setDeviceName', name);
      await _refreshInfo();
    } catch (e) {
      debugPrint('setDeviceName failed: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }
}
