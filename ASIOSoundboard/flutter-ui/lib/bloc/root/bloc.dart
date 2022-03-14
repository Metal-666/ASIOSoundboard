import 'dart:async';

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

  RootBloc(this._clientRepository, this._settingsRepository)
      : super(
            RootState(0, null, false, tileSize: _settingsRepository.tileSize)) {
    //_clientRepository.restoreTileSize();

    // Start listening to the host events. We are mainly interested in global changes like stopping and starting the Audio Engine, and also errors and other notifications.
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<WebsocketEvent>((event, emit) {
      switch (event.message.type) {
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
                      error: error.error, description: error.description)));
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
                      sampleRate: error.sampleRate)));
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
    on<AudioEngineToggled>(
        (event, emit) => _clientRepository.toggleAudioEngine());
    on<FileResampleRequested>((event, emit) =>
        _clientRepository.resampleFile(event.file, event.sampleRate));
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
