import 'package:shared_preferences/shared_preferences.dart';

/// Acts like a wrapper to SharedPreferences. Very ugly wrapper. Used by blocs to store and retrieve data.
class SettingsRepository {
  late SharedPreferences _preferences;

  Future<void> init() async =>
      _preferences = await SharedPreferences.getInstance();

  Future<bool> _applyStringPreference(String key, String? value) =>
      value == null
          ? _preferences.remove(key)
          : _preferences.setString(key, value);

  Future<bool> _applyDoublePreference(String key, double? value) =>
      value == null
          ? _preferences.remove(key)
          : _preferences.setDouble(key, value);

  String? getAudioDevice() => _preferences.getString(_Settings.audioDevice);

  Future<bool> setAudioDevice(String? audioDevice) async =>
      _applyStringPreference(_Settings.audioDevice, audioDevice);

  int? getSampleRate() => _preferences.getInt(_Settings.sampleRate);

  Future<bool> setSampleRate(int? sampleRate) async => sampleRate == null
      ? _preferences.remove(_Settings.sampleRate)
      : _preferences.setInt(_Settings.sampleRate, sampleRate);

  double getGlobalVolume() =>
      _preferences.getDouble(_Settings.globalVolume) ?? 1;

  Future<bool> setGlobalVolume(double? globalVolume) async =>
      _applyDoublePreference(_Settings.globalVolume, globalVolume);

  double getTileSize() => _preferences.getDouble(_Settings.tileSize) ?? 1;

  Future<bool> setTileSize(double? tileSize) async =>
      _applyDoublePreference(_Settings.tileSize, tileSize);

  bool getAutoStartEngine() =>
      _preferences.getBool(_Settings.autoStartEngine) ?? false;

  Future<bool> setAutoStartEngine(bool autoStartEngine) async =>
      await _preferences.setBool(_Settings.autoStartEngine, autoStartEngine);

  String? getAccentMode() => _preferences.getString(_Settings.accentMode);

  Future<bool> setAccentMode(String? accentMode) async =>
      _applyStringPreference(_Settings.accentMode, accentMode);

  String? getCustomAccentColor() =>
      _preferences.getString(_Settings.customAccentColor);

  Future<bool> setCustomAccentColor(String? customAccentColor) async =>
      _applyStringPreference(_Settings.customAccentColor, customAccentColor);

  String? getDefaultSoundboard() =>
      _preferences.getString(_Settings.defaultSoundboard);

  Future<bool> setDefaultSoundboard(String? defaultSoundboard) async =>
      _applyStringPreference(_Settings.defaultSoundboard, defaultSoundboard);

  bool getSeenTileTutorial() =>
      _preferences.getBool(_Settings.seenTileTutorial) ?? false;

  Future<bool> setSeenTileTutorial(bool seenTileTutorial) async =>
      _preferences.setBool(_Settings.seenTileTutorial, seenTileTutorial);
}

class _Settings {
  static const String audioDevice = 'audioDevice',
      sampleRate = 'sampleRate',
      globalVolume = 'globalVolume',
      tileSize = 'tileSize',
      autoStartEngine = 'autoStartEngine',
      accentMode = 'accentMode',
      customAccentColor = 'customAccentColor',
      defaultSoundboard = 'defaultSoundboard',
      seenTileTutorial = 'seenTileTutorial';
}
