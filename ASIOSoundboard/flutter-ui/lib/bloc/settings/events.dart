import 'dart:ui';

import 'package:asio_soundboard/bloc/settings/state.dart';

import '../../data/network/websocket_events.dart';

abstract class SettingsEvent {}

class PageLoaded extends SettingsEvent {}

class WebsocketEvent extends SettingsEvent {
  final WebsocketMessage message;

  WebsocketEvent(this.message);
}

class OpenGithub extends SettingsEvent {}

class ShowGithubActions extends SettingsEvent {}

class HideGithubActions extends SettingsEvent {}

class OpenGithubIssues extends SettingsEvent {}

class OpenGithubWiki extends SettingsEvent {}

class ASIODeviceChanged extends SettingsEvent {
  final String? asioDevice;

  ASIODeviceChanged(this.asioDevice);
}

class SampleRateChanged extends SettingsEvent {
  final int? sampleRate;

  SampleRateChanged(this.sampleRate);
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

class AutoStartEngineChanged extends SettingsEvent {
  final bool autoStart;

  AutoStartEngineChanged(this.autoStart);
}

class AccentModeChanged extends SettingsEvent {
  final AccentMode? accentMode;

  AccentModeChanged(this.accentMode);
}

class PickCustomAccentColor extends SettingsEvent {}

class UpdateCustomAccentColor extends SettingsEvent {
  final Color color;

  UpdateCustomAccentColor(this.color);
}

class FinishedPickingCustomAccentColor extends SettingsEvent {}

class CancelPickingCustomAccentColor extends SettingsEvent {}

class BecomeDeveloper extends SettingsEvent {}
