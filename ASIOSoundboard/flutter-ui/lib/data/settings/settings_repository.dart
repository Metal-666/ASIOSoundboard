import 'package:shared_preferences/shared_preferences.dart';

// Acts like a wrapper to SharedPreferences. Used by almost all blocs to store and retrieve data
class SettingsRepository {
  late SharedPreferences preferences;

  Future<void> init() async =>
      preferences = await SharedPreferences.getInstance();

  String? get audioDevice => preferences.getString(_Settings.audioDevice);

  set audioDevice(String? audioDevice) {
    if (audioDevice == null) {
      preferences.remove(_Settings.audioDevice);
    } else {
      preferences.setString(_Settings.audioDevice, audioDevice);
    }
  }

  int? get sampleRate => preferences.getInt(_Settings.sampleRate);

  set sampleRate(int? sampleRate) {
    if (sampleRate == null) {
      preferences.remove(_Settings.sampleRate);
    } else {
      preferences.setInt(_Settings.sampleRate, sampleRate);
    }
  }

  double get globalVolume => preferences.getDouble(_Settings.globalVolume) ?? 1;

  set globalVolume(double? globalVolume) {
    if (globalVolume == null) {
      preferences.remove(_Settings.globalVolume);
    } else {
      preferences.setDouble(_Settings.globalVolume, globalVolume);
    }
  }

  double get tileSize => preferences.getDouble(_Settings.tileSize) ?? 1;

  set tileSize(double? tileSize) {
    if (tileSize == null) {
      preferences.remove(_Settings.tileSize);
    } else {
      preferences.setDouble(_Settings.tileSize, tileSize);
    }
  }
}

class _Settings {
  static const String audioDevice = 'audioDevice',
      sampleRate = 'sampleRate',
      globalVolume = 'globalVolume',
      tileSize = 'tileSize';
}
