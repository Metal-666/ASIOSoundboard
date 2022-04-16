import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../../data/network/websocket_events.dart';
import '../../data/settings/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/network/client_repository.dart';
import '../../main.dart';
import 'events.dart';
import 'state.dart';

import '../../util/extensions.dart';

const String githubRepo = 'https://github.com/Metal-666/ASIOSoundboard';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ClientRepository _clientRepository;
  final SettingsRepository _settingsRepository;

  late final StreamSubscription<WebsocketMessage> _subscription;

  SettingsBloc(
    this._clientRepository,
    this._settingsRepository,
  ) : super(SettingsState(
          null,
          <int>[],
          null,
          <String>[],
          _settingsRepository.getGlobalVolume(),
          _settingsRepository.getAutoStartEngine(),
          SettingsState
                  .accentModeConverter[_settingsRepository.getAccentMode()] ??
              AccentMode.original,
          null,
          null,
          false,
        )) {
    // Start listening to the host events. We mainly want to know when the lists requested above arrive and when an Audio Device or Sample Rate updates are processed by the server.
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<PageLoaded>(
        (event, emit) async => _clientRepository.notifyBlocLoaded(this));
    on<WebsocketEvent>((event, emit) async {
      switch (event.message.type) {
        case WebsocketMessageType.appLoaded:
          {
            final List<String>? audioDevices =
                await _clientRepository.listAudioDevices();
            final List<int>? sampleRates =
                await _clientRepository.listSampleRates();

            emit(state.copyWith(
              asioDevices: () => audioDevices,
              sampleRates: () => sampleRates,
              asioDevice: () => _settingsRepository.getAudioDevice(),
              sampleRate: () => _settingsRepository.getSampleRate(),
            ));

            break;
          }
        default:
      }
    });
    on<OpenGithub>((event, emit) async => await launch(githubRepo));
    on<ShowGithubActions>(
        (event, emit) => emit(state.copyWith(showGithubActions: () => true)));
    on<HideGithubActions>(
        (event, emit) => emit(state.copyWith(showGithubActions: () => false)));
    on<OpenGithubIssues>(
        (event, emit) async => await launch(githubRepo + '/issues'));
    on<OpenGithubWiki>(
        (event, emit) async => await launch(githubRepo + '/wiki'));
    on<ASIODeviceChanged>((event, emit) async {
      if (event.asioDevice != null) {
        log('Changing Audio Device to ${event.asioDevice}');

        emit(state.copyWith(asioDevice: () => event.asioDevice));

        await _settingsRepository.setAudioDevice(event.asioDevice);
      } else {
        log('Can\'t change Audio Device: null selected');
      }
    });
    on<SampleRateChanged>((event, emit) async {
      log('Changing Sample Rate to ${event.sampleRate}');

      emit(state.copyWith(sampleRate: () => event.sampleRate));

      await _settingsRepository.setSampleRate(event.sampleRate);
    });
    on<VolumeChanged>((event, emit) async {
      if (state.volume != event.volume) {
        log('Changing global volume to ${event.volume}');

        emit(state.copyWith(volume: () => event.volume));

        await _clientRepository.setGlobalVolume(event.volume);
      }
    });
    on<VolumeChangedFinal>((event, emit) async =>
        await _settingsRepository.setGlobalVolume(event.volume));
    on<AutoStartEngineChanged>((event, emit) async {
      log('Changing autoStartEngine to ${event.autoStart}');

      emit(state.copyWith(autoStartEngine: () => event.autoStart));

      await _settingsRepository.setAutoStartEngine(event.autoStart);
    });
    on<AccentModeChanged>((event, emit) async {
      log('Changing accent mode to ${event.accentMode}');

      if (event.accentMode != null && state.accentMode != event.accentMode) {
        await _settingsRepository.setAccentMode(
            SettingsState.accentModeConverter.inverse[event.accentMode]);

        exit(1);
      }
    });
    on<PickCustomAccentColor>((event, emit) {
      log('Picking accent color');

      emit(state.copyWith(
          pickingAccentColor: () => _settingsRepository
                      .getCustomAccentColor() ==
                  null
              ? originalAccentColor
              : HexColor.fromHex(_settingsRepository.getCustomAccentColor()!)));
    });
    on<UpdateCustomAccentColor>((event, emit) =>
        emit(state.copyWith(pickingAccentColor: () => event.color)));
    on<FinishedPickingCustomAccentColor>((event, emit) async {
      if (state.pickingAccentColor != null) {
        await _settingsRepository
            .setCustomAccentColor(state.pickingAccentColor!.toHex());

        exit(1);
      }
    });
    on<CancelPickingCustomAccentColor>(
        (event, emit) => emit(state.copyWith(pickingAccentColor: () => null)));
    on<BecomeDeveloper>((event, emit) => emit(state.copyWith(
        attemptsToBecomeADeveloper: () =>
            state.attemptsToBecomeADeveloper == null
                ? 0
                : state.attemptsToBecomeADeveloper! + 1)));
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
