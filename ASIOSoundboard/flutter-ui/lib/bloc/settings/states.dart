class SettingsState {
  final int? sampleRate;
  final List<int?>? sampleRates;
  final String? asioDevice;
  final List<String>? asioDevices;

  final double volume;

  SettingsState(this.sampleRate, this.sampleRates, this.asioDevice,
      this.asioDevices, this.volume);

  SettingsState changeSampleRate(int? sampleRate) =>
      SettingsState(sampleRate, sampleRates, asioDevice, asioDevices, volume);

  SettingsState changeASIODevice(String? asioDevice) =>
      SettingsState(sampleRate, sampleRates, asioDevice, asioDevices, volume);

  SettingsState changeGlobalVolume(double volume) =>
      SettingsState(sampleRate, sampleRates, asioDevice, asioDevices, volume);

  SettingsState populateSampleRates(List<int>? sampleRates) =>
      SettingsState(sampleRate, sampleRates, asioDevice, asioDevices, volume);

  SettingsState populateASIODevices(List<String>? asioDevices) =>
      SettingsState(sampleRate, sampleRates, asioDevice, asioDevices, volume);
}
