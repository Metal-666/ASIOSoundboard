import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/network/client_repository.dart';
import '../../data/network/websocket_events.dart';
import '../../data/settings/settings_repository.dart';
import 'events.dart';
import 'state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final ClientRepository _clientRepository;
  final SettingsRepository _settingsRepository;

  final bool preventAutostart;

  late final StreamSubscription<WebsocketMessage> _subscription;

  RootBloc(
    this._clientRepository,
    this._settingsRepository, {
    this.preventAutostart = false,
  }) : super(RootState(
          0,
          null,
          false,
          tileSize: _settingsRepository.getTileSize(),
        )) {
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<AppLoaded>(
        (event, emit) async => _clientRepository.notifyBlocLoaded(this));
    on<WebsocketEvent>((event, emit) async {
      switch (event.message.type) {
        case WebsocketMessageType.appLoaded:
          {
            await _clientRepository
                .setGlobalVolume(_settingsRepository.getGlobalVolume());

            if (_settingsRepository.getAutoStartEngine() && !preventAutostart) {
              await _clientRepository.startAudioEngine(
                _settingsRepository.getAudioDevice(),
                _settingsRepository.getSampleRate(),
                _settingsRepository.getGlobalVolume(),
              );
            }

            break;
          }
        case WebsocketMessageType.audioEngineStatus:
          {
            bool? active = event.message.data?.active;

            if (active != null) {
              emit(state.copyWith(isAudioEngineRunning: () => active));
            }

            break;
          }
        case WebsocketMessageType.error:
          {
            emit(state.copyWith(error: () => event.message.data?.error));

            break;
          }
        default:
      }
    });
    on<ViewChanged>((event, emit) =>
        emit(state.copyWith(viewIndex: () => event.viewIndex)));
    on<AudioEngineToggled>((event, emit) async {
      if (state.isAudioEngineRunning) {
        await _clientRepository.stopAudioEngine();
      } else {
        await _clientRepository.startAudioEngine(
          _settingsRepository.getAudioDevice(),
          _settingsRepository.getSampleRate(),
          _settingsRepository.getGlobalVolume(),
        );
      }
    });
    on<CopyErrorStackTrace>((event, emit) =>
        Clipboard.setData(ClipboardData(text: state.error?.description)));
    on<FileResampleRequested>((event, emit) async {
      if (state.error?.path != null && state.error?.sampleRate != null) {
        log('Resampling file (${state.error?.path} => ${state.error?.sampleRate})');

        await _clientRepository.resampleFile(
          state.error!.path!,
          state.error!.sampleRate!,
        );
      } else {
        log('Can\'t resample file - path or sample rate is null');
      }
    });
    on<TileSizeChanged>(
        (event, emit) => emit(state.copyWith(tileSize: () => event.tileSize)));
    on<TileSizeChangedFinal>((event, emit) async =>
        await _settingsRepository.setTileSize(event.tileSize));
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
