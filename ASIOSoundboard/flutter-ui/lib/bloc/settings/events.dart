import '../../data/network/client_events.dart';

abstract class SettingsEvent {}

class PageLoaded extends SettingsEvent {}

class WebsocketEvent extends SettingsEvent {
  final WebsocketMessage message;

  WebsocketEvent(this.message);
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
