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

import 'package:flauncher/widgets/settings/back_button_actions.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

const _appHighlightAnimationEnabledKey = "app_highlight_animation_enabled";
const _appKeyClickEnabledKey = "app_key_click_enabled";
const _autoHideAppBarKey = "auto_hide_app_bar";
const _gradientUuidKey = "gradient_uuid";
const _backButtonActionKey = "back_button_action";
const _dateFormatKey = "date_format";
const _showCategoryTitlesKey = "show_category_titles";
const _showAppNamesBelowIconsKey = "show_app_names_below_icons";
const _themesKey = "app_banner_shape";
const _hideHighlightOutlineOnHomescreenKey = "hide_highlight_outline_on_homescreen";
const _appSelectorTransitionAnimationEnabledKey = "app_selector_transition_animation_enabled";
const _showDateInStatusBarKey = "show_date_in_status_bar";
const _showTimeInStatusBarKey = "show_time_in_status_bar";
const _timeFormatKey = "time_format";
const _dataUsagePeriodKey = "wifi_usage_period";
const _showDataWidgetInStatusBarKey = "show_wifi_widget_in_status_bar";
const String _showNetworkIndicatorInStatusBarKey = "show_network_indicator_in_status_bar";
const String _accentColorKey = "accent_color";
const String _screensaverClockStyleKey = "screensaver_clock_style";
const String _timeBasedWallpaperEnabledKey = "time_based_wallpaper_enabled";
const String _showInputsWidgetInStatusBarKey = "show_inputs_widget_in_status_bar";
const String _showContinueWatchingKey = "show_continue_watching";
const String _showNotificationsWidgetInStatusBarKey = "show_notifications_widget_in_status_bar";
const String _autoHideNotificationsWidgetKey = "auto_hide_notifications_widget";
const String _orientationKey = "orientation";
const String _keepScreenOnKey = "keep_screen_on";
const String _autoLaunchPackageKey = "auto_launch_package";
const String _kioskEnabledKey = "kiosk_enabled";
const String _kioskPinKey = "kiosk_pin";
const String _kioskExpiresAtKey = "kiosk_expires_at";
const String _kioskDefaultPin = "0000";

const String ORIENTATION_LANDSCAPE = "landscape";
const String ORIENTATION_PORTRAIT = "portrait";

// WiFi usage period options
const String DATA_USAGE_DAILY = "daily";
const String DATA_USAGE_WEEKLY = "weekly";
const String DATA_USAGE_MONTHLY = "monthly";

// Accent color presets (hex values)
const String ACCENT_COLOR_PURPLE = "7C4DFF";
const String ACCENT_COLOR_TEAL = "00BFA5";
const String ACCENT_COLOR_BLUE = "2979FF";
const String ACCENT_COLOR_ORANGE = "FF6D00";
const String ACCENT_COLOR_PINK = "F50057";
const String ACCENT_COLOR_GREEN = "00C853";
const String ACCENT_COLOR_WHITE = "FFFFFF";
const String ACCENT_COLOR_YELLOW = "FFD600";
const String ACCENT_COLOR_RED = "D50000";
const String ACCENT_COLOR_CYAN = "00E5FF";
const String ACCENT_COLOR_INDIGO = "536DFE";
const String ACCENT_COLOR_LIME = "AEEA00";
const String ACCENT_COLOR_AMBER = "FFAB00";
const String ACCENT_COLOR_ROSE = "FF4081";
const String ACCENT_COLOR_ICE_BLUE = "80D8FF";

class SettingsService extends ChangeNotifier {
  static final defaultDateFormat = "EEEE d";
  static final defaultTimeFormat = "H:mm";
  final SharedPreferences _sharedPreferences;

  late bool _appHighlightAnimationEnabled;
  late bool _appKeyClickEnabled;
  late bool _autoHideAppBarEnabled;
  late bool _showCategoryTitles;
  late bool _showAppNamesBelowIcons;
  late String _themes;
  late bool _hideHighlightOutlineOnHomescreen;
  late bool _appSelectorTransitionAnimationEnabled;
  late bool _showDateInStatusBar;
  late bool _showTimeInStatusBar;
  late String? _gradientUuid;
  late String _backButtonAction;
  late String _dateFormat;
  late String _timeFormat;
  late String _dataUsagePeriod;
  late bool _showDataWidgetInStatusBar;
  late bool _showNetworkIndicatorInStatusBar;
  late String _accentColorHex;
  late String _screensaverClockStyle;
  late bool _timeBasedWallpaperEnabled;
  late bool _showInputsWidgetInStatusBar;
  late bool _showContinueWatching;
  late bool _showNotificationsWidgetInStatusBar;
  late bool _autoHideNotificationsWidget;
  late String _orientation;
  late bool _keepScreenOn;
  String? _autoLaunchPackage;
  late bool _kioskEnabled;
  late String _kioskPin;
  int _kioskExpiresAt = 0; // ms since epoch; 0 = no expiry

  bool get appHighlightAnimationEnabled => _appHighlightAnimationEnabled;

  bool get appKeyClickEnabled => _appKeyClickEnabled;

  bool get autoHideAppBarEnabled => _autoHideAppBarEnabled;

  bool get showCategoryTitles => _showCategoryTitles;

  bool get showAppNamesBelowIcons => _showAppNamesBelowIcons;

  String get themes => _themes;

  bool get hideHighlightOutlineOnHomescreen => _hideHighlightOutlineOnHomescreen;

  bool get appSelectorTransitionAnimationEnabled => _appSelectorTransitionAnimationEnabled;

  bool get showDateInStatusBar => _showDateInStatusBar;

  bool get showTimeInStatusBar => _showTimeInStatusBar;

  String? get gradientUuid => _gradientUuid;

  String get backButtonAction => _backButtonAction;

  String get dateFormat => _dateFormat;

  String get timeFormat => _timeFormat;

  String get dataUsagePeriod => _dataUsagePeriod;

  bool get showDataWidgetInStatusBar => _showDataWidgetInStatusBar;

  bool get showNetworkIndicatorInStatusBar => _showNetworkIndicatorInStatusBar;

  bool get showInputsWidgetInStatusBar => _showInputsWidgetInStatusBar;
  bool get showContinueWatching => _showContinueWatching;
  bool get showNotificationsWidgetInStatusBar => _showNotificationsWidgetInStatusBar;
  bool get autoHideNotificationsWidget => _autoHideNotificationsWidget;

  String get orientation => _orientation;
  bool get keepScreenOn => _keepScreenOn;
  String? get autoLaunchPackage => _autoLaunchPackage;
  bool get kioskEnabled => _kioskEnabled;
  String get kioskPin => _kioskPin;
  DateTime? get kioskExpiresAt =>
      _kioskExpiresAt == 0 ? null : DateTime.fromMillisecondsSinceEpoch(_kioskExpiresAt);

  String get accentColorHex => _accentColorHex;

  String get screensaverClockStyle => _screensaverClockStyle;

  Color get accentColor {
    final hex = accentColorHex;
    return Color(int.parse("0xFF$hex"));
  }

  SettingsService(this._sharedPreferences) {
    reload();
  }

  void reload() {
    _appHighlightAnimationEnabled = _sharedPreferences.getBool(_appHighlightAnimationEnabledKey) ?? true;
    _appKeyClickEnabled = _sharedPreferences.getBool(_appKeyClickEnabledKey) ?? true;
    _autoHideAppBarEnabled = _sharedPreferences.getBool(_autoHideAppBarKey) ?? false;
    _showCategoryTitles = _sharedPreferences.getBool(_showCategoryTitlesKey) ?? true;
    _showAppNamesBelowIcons = _sharedPreferences.getBool(_showAppNamesBelowIconsKey) ?? false;
    _themes = _sharedPreferences.getString(_themesKey) ?? "modern";
    _hideHighlightOutlineOnHomescreen = _sharedPreferences.getBool(_hideHighlightOutlineOnHomescreenKey) ?? false;
    _appSelectorTransitionAnimationEnabled = _sharedPreferences.getBool(_appSelectorTransitionAnimationEnabledKey) ?? true;
    _showDateInStatusBar = _sharedPreferences.getBool(_showDateInStatusBarKey) ?? true;
    _showTimeInStatusBar = _sharedPreferences.getBool(_showTimeInStatusBarKey) ?? true;
    _gradientUuid = _sharedPreferences.getString(_gradientUuidKey);
    _backButtonAction = _sharedPreferences.getString(_backButtonActionKey) ?? BACK_BUTTON_ACTION_NOTHING;
    _dateFormat = _sharedPreferences.getString(_dateFormatKey) ?? defaultDateFormat;
    _timeFormat = _sharedPreferences.getString(_timeFormatKey) ?? defaultTimeFormat;
    _dataUsagePeriod = _sharedPreferences.getString(_dataUsagePeriodKey) ?? DATA_USAGE_DAILY;
    _showDataWidgetInStatusBar = _sharedPreferences.getBool(_showDataWidgetInStatusBarKey) ?? true;
    _showNetworkIndicatorInStatusBar = _sharedPreferences.getBool(_showNetworkIndicatorInStatusBarKey) ?? true;
    _accentColorHex = _sharedPreferences.getString(_accentColorKey) ?? ACCENT_COLOR_PURPLE;
    _screensaverClockStyle = _sharedPreferences.getString(_screensaverClockStyleKey) ?? "minimal";
    _timeBasedWallpaperEnabled = _sharedPreferences.getBool(_timeBasedWallpaperEnabledKey) ?? false;
    _showInputsWidgetInStatusBar = _sharedPreferences.getBool(_showInputsWidgetInStatusBarKey) ?? true;
    _showContinueWatching = _sharedPreferences.getBool(_showContinueWatchingKey) ?? true;
    _showNotificationsWidgetInStatusBar = _sharedPreferences.getBool(_showNotificationsWidgetInStatusBarKey) ?? true;
    _autoHideNotificationsWidget = _sharedPreferences.getBool(_autoHideNotificationsWidgetKey) ?? false;
    _orientation = _sharedPreferences.getString(_orientationKey) ?? ORIENTATION_LANDSCAPE;
    _keepScreenOn = _sharedPreferences.getBool(_keepScreenOnKey) ?? true;
    _autoLaunchPackage = _sharedPreferences.getString(_autoLaunchPackageKey);
    _kioskEnabled = _sharedPreferences.getBool(_kioskEnabledKey) ?? false;
    _kioskPin = _sharedPreferences.getString(_kioskPinKey) ?? _kioskDefaultPin;
    _kioskExpiresAt = _sharedPreferences.getInt(_kioskExpiresAtKey) ?? 0;
    notifyListeners();
  }

  /// Enable kiosk permanently or until [expiresAt]. Pass null / omit to
  /// keep it on until manually disabled.
  Future<void> setKioskEnabled(bool value, {DateTime? expiresAt}) async {
    await _sharedPreferences.setBool(_kioskEnabledKey, value);
    _kioskEnabled = value;
    final expiryMs = value && expiresAt != null ? expiresAt.millisecondsSinceEpoch : 0;
    await _sharedPreferences.setInt(_kioskExpiresAtKey, expiryMs);
    _kioskExpiresAt = expiryMs;
    notifyListeners();
  }

  /// If a timed-kiosk expiry has passed, flip the state off and persist.
  /// Returns true if the check caused a state change.
  Future<bool> enforceKioskExpiry() async {
    if (!_kioskEnabled || _kioskExpiresAt == 0) return false;
    if (DateTime.now().millisecondsSinceEpoch < _kioskExpiresAt) return false;
    await setKioskEnabled(false);
    return true;
  }

  Future<void> setKioskPin(String value) async {
    await _sharedPreferences.setString(_kioskPinKey, value);
    _kioskPin = value;
    notifyListeners();
  }

  Future<void> setAutoLaunchPackage(String? value) async {
    if (value == null || value.isEmpty) {
      await _sharedPreferences.remove(_autoLaunchPackageKey);
      _autoLaunchPackage = null;
    } else {
      await _sharedPreferences.setString(_autoLaunchPackageKey, value);
      _autoLaunchPackage = value;
    }
    notifyListeners();
  }

  Future<void> setOrientation(String value) async {
    await _sharedPreferences.setString(_orientationKey, value);
    _orientation = value;
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    await _sharedPreferences.setBool(_keepScreenOnKey, value);
    _keepScreenOn = value;
    notifyListeners();
  }

  Future<void> setAppHighlightAnimationEnabled(bool value) async {
    await _sharedPreferences.setBool(_appHighlightAnimationEnabledKey, value);
    _appHighlightAnimationEnabled = value;
    notifyListeners();
  }

  Future<void> setAppKeyClickEnabled(bool value) async {
    await _sharedPreferences.setBool(_appKeyClickEnabledKey, value);
    _appKeyClickEnabled = value;
    notifyListeners();
  }

  Future<void> setAutoHideAppBarEnabled(bool value) async {
    await _sharedPreferences.setBool(_autoHideAppBarKey, value);
    _autoHideAppBarEnabled = value;
    notifyListeners();
  }

  Future<void> setGradientUuid(String value) async {
    await _sharedPreferences.setString(_gradientUuidKey, value);
    _gradientUuid = value;
    notifyListeners();
  }

  Future<void> setBackButtonAction(String value) async {
    await _sharedPreferences.setString(_backButtonActionKey, value);
    _backButtonAction = value;
    notifyListeners();
  }

  Future<void> setDateTimeFormat(String dateFormatString, String timeFormatString) async {
    await Future.wait([
      _sharedPreferences.setString(_dateFormatKey, dateFormatString),
      _sharedPreferences.setString(_timeFormatKey, timeFormatString)
    ]);
    _dateFormat = dateFormatString;
    _timeFormat = timeFormatString;
    notifyListeners();
  }

  Future<void> setShowCategoryTitles(bool show) async {
    await _sharedPreferences.setBool(_showCategoryTitlesKey, show);
    _showCategoryTitles = show;
    notifyListeners();
  }

  Future<void> setShowAppNamesBelowIcons(bool show) async {
    await _sharedPreferences.setBool(_showAppNamesBelowIconsKey, show);
    _showAppNamesBelowIcons = show;
    notifyListeners();
  }

  Future<void> setThemes(String shape) async {
    await _sharedPreferences.setString(_themesKey, shape);
    _themes = shape;
    notifyListeners();
  }

  Future<void> setHideHighlightOutlineOnHomescreen(bool enabled) async {
    await _sharedPreferences.setBool(_hideHighlightOutlineOnHomescreenKey, enabled);
    _hideHighlightOutlineOnHomescreen = enabled;
    notifyListeners();
  }

  Future<void> setAppSelectorTransitionAnimationEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_appSelectorTransitionAnimationEnabledKey, enabled);
    _appSelectorTransitionAnimationEnabled = enabled;
    notifyListeners();
  }

  Future<void> setShowDateInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showDateInStatusBarKey, show);
    _showDateInStatusBar = show;
    notifyListeners();
  }

  Future<void> setShowTimeInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showTimeInStatusBarKey, show);
    _showTimeInStatusBar = show;
    notifyListeners();
  }

  Future<void> setDataUsagePeriod(String period) async {
    await _sharedPreferences.setString(_dataUsagePeriodKey, period);
    _dataUsagePeriod = period;
    notifyListeners();
  }

  Future<void> setShowDataWidgetInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showDataWidgetInStatusBarKey, show);
    _showDataWidgetInStatusBar = show;
    notifyListeners();
  }

  Future<void> setShowNetworkIndicatorInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showNetworkIndicatorInStatusBarKey, show);
    _showNetworkIndicatorInStatusBar = show;
    notifyListeners();
  }

  Future<void> setAccentColor(String colorHex) async {
    await _sharedPreferences.setString(_accentColorKey, colorHex);
    _accentColorHex = colorHex;
    notifyListeners();
  }

  Future<void> setScreensaverClockStyle(String style) async {
    await _sharedPreferences.setString(_screensaverClockStyleKey, style);
    _screensaverClockStyle = style;
    notifyListeners();
  }

  bool get timeBasedWallpaperEnabled => _timeBasedWallpaperEnabled;

  Future<void> setTimeBasedWallpaperEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_timeBasedWallpaperEnabledKey, enabled);
    _timeBasedWallpaperEnabled = enabled;
    notifyListeners();
  }

  Future<void> setShowInputsWidgetInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showInputsWidgetInStatusBarKey, show);
    _showInputsWidgetInStatusBar = show;
    notifyListeners();
  }

  Future<void> setShowContinueWatching(bool show) async {
    await _sharedPreferences.setBool(_showContinueWatchingKey, show);
    _showContinueWatching = show;
    notifyListeners();
  }

  Future<void> setShowNotificationsWidgetInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showNotificationsWidgetInStatusBarKey, show);
    _showNotificationsWidgetInStatusBar = show;
    notifyListeners();
  }

  Future<void> setAutoHideNotificationsWidget(bool value) async {
    await _sharedPreferences.setBool(_autoHideNotificationsWidgetKey, value);
    _autoHideNotificationsWidget = value;
    notifyListeners();
  }
}
