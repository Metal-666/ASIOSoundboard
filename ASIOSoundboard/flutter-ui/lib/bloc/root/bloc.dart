import 'dart:async';
import 'dart:developer';

import '../../data/settings/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/network/websocket_events.dart';
import '../../data/network/client_repository.dart';
import 'events.dart';
import 'state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final ClientRepository _clientRepository;
  final SettingsRepository _settingsRepository;

  late final StreamSubscription<WebsocketMessage> _subscription;

  RootBloc(
    this._clientRepository,
    this._settingsRepository,
  ) : super(RootState(
          0,
          null,
          false,
          tileSize: _settingsRepository.tileSize,
        )) {
    // Start listening to the host events. We are mainly interested in global changes like stopping and starting the Audio Engine, and also errors and other notifications.
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<AppLoaded>(
        (event, emit) async => _clientRepository.notifyBlocLoaded(this));
    on<WebsocketEvent>((event, emit) async {
      switch (event.message.type) {
        case WebsocketMessageType.appLoaded:
          {
            await _clientRepository
                .setGlobalVolume(_settingsRepository.globalVolume);

            if (_settingsRepository.autoStartEngine) {
              await _clientRepository.startAudioEngine(
                _settingsRepository.audioDevice,
                _settingsRepository.sampleRate,
                _settingsRepository.globalVolume,
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
            Error? error = event.message.data?.error;

            if (error != null) {
              emit(state.copyWith(
                  errorDialog: () => ErrorDialog(
                        error: error.error,
                        description: error.description,
                      )));
            }
            break;
          }
        case WebsocketMessageType.fileError:
          {
            Error? error = event.message.data?.error;

            if (error != null) {
              emit(state.copyWith(
                  errorDialog: () => FileErrorDialog(
                        error: error.error,
                        description: error.description,
                        file: error.file,
                      )));
            }
            break;
          }
        case WebsocketMessageType.fileResampleNeeded:
          {
            Error? error = event.message.data?.error;

            if (error != null) {
              emit(state.copyWith(
                  errorDialog: () => ResampleNeededDialog(
                        error: error.error,
                        description: error.description,
                        file: error.file,
                        sampleRate: error.sampleRate,
                      )));
            }
            break;
          }
        default:
      }
    });
    on<ViewChanged>((event, emit) =>
        emit(state.copyWith(viewIndex: () => event.viewIndex)));
    on<ErrorDialogDismissed>(
        (event, emit) => emit(state.copyWith(errorDialog: () => null)));
    on<AudioEngineToggled>((event, emit) async {
      if (state.isAudioEngineRunning) {
        await _clientRepository.stopAudioEngine();
      } else {
        await _clientRepository.startAudioEngine(
          _settingsRepository.audioDevice,
          _settingsRepository.sampleRate,
          _settingsRepository.globalVolume,
        );
      }
    });
    on<FileResampleRequested>((event, emit) async {
      if (event.file != null && event.sampleRate != null) {
        log('Resampling file (${event.file} => ${event.sampleRate})');

        await _clientRepository.resampleFile(
          event.file!,
          event.sampleRate!,
        );
      } else {
        log('Can\'t resample file - path or sample rate is null');
      }
    });
    on<TileSizeChanged>(
        (event, emit) => emit(state.copyWith(tileSize: () => event.tileSize)));
    on<TileSizeChangedFinal>(
        (event, emit) => _settingsRepository.tileSize = event.tileSize);
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
