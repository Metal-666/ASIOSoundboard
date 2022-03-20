import 'dart:ui';

import 'package:quiver/collection.dart';

class SettingsState {
  final int? sampleRate;
  final List<int?>? sampleRates;
  final String? asioDevice;
  final List<String>? asioDevices;

  final double volume;

  final bool autoStartEngine;

  final Color? pickingAccentColor;

  final AccentMode accentMode;
  static final BiMap<String, AccentMode> accentModeConverter =
      BiMap<String, AccentMode>()
        ..addAll(<String, AccentMode>{
          'original': AccentMode.original,
          'system': AccentMode.system,
          'custom': AccentMode.custom,
        });

  const SettingsState(
    this.sampleRate,
    this.sampleRates,
    this.asioDevice,
    this.asioDevices,
    this.volume,
    this.autoStartEngine,
    this.accentMode,
    this.pickingAccentColor,
  );

  SettingsState copyWith({
    int? Function()? sampleRate,
    List<int?>? Function()? sampleRates,
    String? Function()? asioDevice,
    List<String>? Function()? asioDevices,
    double Function()? volume,
    bool Function()? autoStartEngine,
    AccentMode Function()? accentMode,
    Color? Function()? pickingAccentColor,
  }) =>
      SettingsState(
        sampleRate == null ? this.sampleRate : sampleRate.call(),
        sampleRates == null ? this.sampleRates : sampleRates.call(),
        asioDevice == null ? this.asioDevice : asioDevice.call(),
        asioDevices == null ? this.asioDevices : asioDevices.call(),
        volume == null ? this.volume : volume.call(),
        autoStartEngine == null ? this.autoStartEngine : autoStartEngine.call(),
        accentMode == null ? this.accentMode : accentMode.call(),
        pickingAccentColor == null
            ? this.pickingAccentColor
            : pickingAccentColor.call(),
      );
}

enum AccentMode {
  original,
  system,
  custom,
}
