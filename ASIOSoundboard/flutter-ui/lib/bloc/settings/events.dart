import 'package:asio_soundboard/data/network/client_events.dart'
    as client_events;

abstract class SettingsEvent {}

class ClientEvent extends SettingsEvent {
  final client_events.ClientEvent event;

  ClientEvent(this.event);
}

class SampleRateChanged extends SettingsEvent {
  final int? sampleRate;

  SampleRateChanged(this.sampleRate);
}

class ASIODeviceChanged extends SettingsEvent {
  final String? asioDevice;

  ASIODeviceChanged(this.asioDevice);
}

abstract class VolumeEvent extends SettingsEvent {
  final double volume;

  VolumeEvent(this.volume);
}

class VolumeChanged extends VolumeEvent {
  VolumeChanged(double volume) : super(volume);
}

class VolumeChangedFinal extends VolumeEvent {
  VolumeChangedFinal(double volume) : super(volume);
}
