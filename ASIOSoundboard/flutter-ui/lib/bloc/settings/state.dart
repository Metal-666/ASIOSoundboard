class SettingsState {
  final int? sampleRate;
  final List<int?>? sampleRates;
  final String? asioDevice;
  final List<String>? asioDevices;

  final double volume;

  const SettingsState(this.sampleRate, this.sampleRates, this.asioDevice,
      this.asioDevices, this.volume);

  SettingsState copyWith(
          {int? Function()? sampleRate,
          List<int?>? Function()? sampleRates,
          String? Function()? asioDevice,
          List<String>? Function()? asioDevices,
          double Function()? volume}) =>
      SettingsState(
          sampleRate == null ? this.sampleRate : sampleRate.call(),
          sampleRates == null ? this.sampleRates : sampleRates.call(),
          asioDevice == null ? this.asioDevice : asioDevice.call(),
          asioDevices == null ? this.asioDevices : asioDevices.call(),
          volume == null ? this.volume : volume.call());
}
