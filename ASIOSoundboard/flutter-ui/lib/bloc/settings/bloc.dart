import 'dart:async';
import 'dart:developer';

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
          _settingsRepository.globalVolume,
          _settingsRepository.autoStartEngine,
          SettingsState.accentModeConverter[_settingsRepository.accentMode] ??
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
              asioDevice: () => _settingsRepository.audioDevice,
              sampleRate: () => _settingsRepository.sampleRate,
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
    on<ASIODeviceChanged>((event, emit) {
      if (event.asioDevice != null) {
        log('Changing Audio Device to ${event.asioDevice}');

        emit(state.copyWith(asioDevice: () => event.asioDevice));

        _settingsRepository.audioDevice = event.asioDevice;
      } else {
        log('Can\'t change Audio Device: null selected');
      }
    });
    on<SampleRateChanged>((event, emit) {
      log('Changing Sample Rate to ${event.sampleRate}');

      emit(state.copyWith(sampleRate: () => event.sampleRate));

      _settingsRepository.sampleRate = event.sampleRate;
    });
    on<VolumeChanged>((event, emit) {
      if (state.volume != event.volume) {
        log('Changing global volume to ${event.volume}');

        emit(state.copyWith(volume: () => event.volume));

        _clientRepository.setGlobalVolume(event.volume);
      }
    });
    on<VolumeChangedFinal>(
        (event, emit) => _settingsRepository.globalVolume = event.volume);
    on<AutoStartEngineChanged>((event, emit) {
      log('Changing autoStartEngine to ${event.autoStart}');

      emit(state.copyWith(autoStartEngine: () => event.autoStart));

      _settingsRepository.autoStartEngine = event.autoStart;
    });
    on<AccentModeChanged>((event, emit) {
      log('Changing accent mode to ${event.accentMode}');

      if (event.accentMode != null && state.accentMode != event.accentMode) {
        _settingsRepository.accentMode =
            SettingsState.accentModeConverter.inverse[event.accentMode];

        _clientRepository.reloadApp();
      }
    });
    on<PickCustomAccentColor>((event, emit) {
      log('Picking accent color');

      emit(state.copyWith(
          pickingAccentColor: () =>
              _settingsRepository.customAccentColor == null
                  ? originalAccentColor
                  : HexColor.fromHex(_settingsRepository.customAccentColor!)));
    });
    on<UpdateCustomAccentColor>((event, emit) =>
        emit(state.copyWith(pickingAccentColor: () => event.color)));
    on<FinishedPickingCustomAccentColor>((event, emit) {
      if (state.pickingAccentColor != null) {
        _settingsRepository.customAccentColor =
            state.pickingAccentColor!.toHex();

        _clientRepository.reloadApp();

        emit(state.copyWith(pickingAccentColor: () => null));
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
