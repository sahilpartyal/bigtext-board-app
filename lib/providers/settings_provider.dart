import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import '../models/display_mode.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final settings = _loadFromPrefs();
    _applyWakelock(settings.keepScreenAwake);
    return settings;
  }

  AppSettings _loadFromPrefs() {
    final modeStr = _prefs.getString('displayMode') ?? 'simple';
    final mode = DisplayMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => DisplayMode.simple,
    );

    return AppSettings(
      displayMode: mode,
      passengerName: _prefs.getString('passengerName') ?? '',
      companyName: _prefs.getString('companyName') ?? '',
      fontFamily: _prefs.getString('fontFamily') ?? 'Inter',
      textColor: Color(_prefs.getInt('textColor') ?? 0xFFFFFFFF),
      backgroundColor: Color(_prefs.getInt('backgroundColor') ?? 0xFF000000),
      showCompanyName: _prefs.getBool('showCompanyName') ?? false,
      showLogo: _prefs.getBool('showLogo') ?? false,
      hapticFeedback: _prefs.getBool('hapticFeedback') ?? true,
      keepScreenAwake: _prefs.getBool('keepScreenAwake') ?? true,
      companyNameFontSize: _prefs.getDouble('companyNameFontSize') ?? 24.0,
      passengerNameFontSize:
          _prefs.getDouble('passengerNameFontSize') ?? 100.0,
      subtitle: _prefs.getString('subtitle') ?? '',
      subtitleColor: Color(_prefs.getInt('subtitleColor') ?? 0xFFFFFFFF),
      subtitleFontFamily: _prefs.getString('subtitleFontFamily') ?? 'Inter',
      subtitleFontSize: _prefs.getDouble('subtitleFontSize') ?? 32.0,
      titleFontSize: _prefs.getDouble('titleFontSize') ?? 80.0,
      titleColor: Color(_prefs.getInt('titleColor') ?? 0xFFFFFFFF),
      logoPosition: _safeLogoPosition(_prefs.getInt('logoPosition')),
      logoScale: _prefs.getDouble('logoScale') ?? 1.0,
      customLogoBase64: _prefs.getString('customLogoBase64'),
      autoAdvanceSeconds: _prefs.getDouble('autoAdvanceSeconds') ?? 5.0,
    );
  }

  LogoPosition _safeLogoPosition(int? index) {
    if (index == null || index < 0 || index >= LogoPosition.values.length) {
      return LogoPosition.topCenter;
    }
    return LogoPosition.values[index];
  }

  void _applyWakelock(bool enabled) {
    if (enabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> setCustomLogo(String base64) async {
    await update((s) => s.copyWith(customLogoBase64: () => base64));
  }

  Future<void> clearCustomLogo() async {
    await update((s) => s.copyWith(customLogoBase64: () => null));
  }

  Future<void> update(AppSettings Function(AppSettings) updater) async {
    final oldSettings = state;
    final newSettings = updater(state);
    state = newSettings;
    await _saveToPrefs(newSettings);

    if (newSettings.keepScreenAwake != oldSettings.keepScreenAwake) {
      _applyWakelock(newSettings.keepScreenAwake);
    }
  }

  Future<void> _saveToPrefs(AppSettings s) async {
    await _prefs.setString('displayMode', s.displayMode.name);
    await _prefs.setString('passengerName', s.passengerName);
    await _prefs.setString('companyName', s.companyName);
    await _prefs.setString('fontFamily', s.fontFamily);
    await _prefs.setInt('textColor', s.textColor.toARGB32());
    await _prefs.setInt('backgroundColor', s.backgroundColor.toARGB32());
    await _prefs.setBool('showCompanyName', s.showCompanyName);
    await _prefs.setBool('showLogo', s.showLogo);
    await _prefs.setBool('hapticFeedback', s.hapticFeedback);
    await _prefs.setBool('keepScreenAwake', s.keepScreenAwake);
    await _prefs.setDouble('companyNameFontSize', s.companyNameFontSize);
    await _prefs.setDouble('passengerNameFontSize', s.passengerNameFontSize);
    await _prefs.setString('subtitle', s.subtitle);
    await _prefs.setInt('subtitleColor', s.subtitleColor.toARGB32());
    await _prefs.setString('subtitleFontFamily', s.subtitleFontFamily);
    await _prefs.setDouble('subtitleFontSize', s.subtitleFontSize);
    await _prefs.setDouble('titleFontSize', s.titleFontSize);
    await _prefs.setInt('titleColor', s.titleColor.toARGB32());
    await _prefs.setInt('logoPosition', s.logoPosition.index);
    await _prefs.setDouble('logoScale', s.logoScale);
    if (s.customLogoBase64 != null) {
      await _prefs.setString('customLogoBase64', s.customLogoBase64!);
    } else {
      await _prefs.remove('customLogoBase64');
    }
    await _prefs.setDouble('autoAdvanceSeconds', s.autoAdvanceSeconds);
  }
}
