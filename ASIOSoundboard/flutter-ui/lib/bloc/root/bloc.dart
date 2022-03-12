import 'dart:async';

import 'package:asio_soundboard/data/network/client_events.dart'
    as client_events;
import 'package:asio_soundboard/data/network/client_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'events.dart';
import 'state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final ClientRepository _clientRepository;
  late final StreamSubscription<client_events.ClientEvent> _subscription;

  RootBloc(this._clientRepository) : super(const RootState(0, null, false)) {
    // When the bloc is created (which means that the UI is almost loaded), connect to the host.
    _clientRepository.connect();

    _clientRepository.restoreTileSize();

    // Start listening to the host events. We are mainly interested in global changes like stopping and starting the Audio Engine, and also errors and other notifications.
    _subscription = _clientRepository.eventStream.stream
        .listen((client_events.ClientEvent event) => add(ClientEvent(event)));

    on<ClientEvent>((event, emit) {
      switch (event.event.type) {
        case client_events.EventTypes.audioEngineError:
          {
            emit(state.copyWith(
                error: () => Error(
                    event.event.data?.error, event.event.data?.description)));
            break;
          }
        case client_events.EventTypes.startedAudioEngine:
          {
            emit(state.copyWith(isAudioEngineRunning: () => true));
            break;
          }
        case client_events.EventTypes.stoppedAudioEngine:
          {
            emit(state.copyWith(isAudioEngineRunning: () => false));
            break;
          }
        case client_events.EventTypes.fileResampleNeeded:
          {
            emit(state.copyWith(
                error: () => Error(
                    event.event.data?.error, event.event.data?.description,
                    resampleFile: event.event.data?.file,
                    sampleRate: event.event.data?.sampleRate)));
            break;
          }
        case client_events.EventTypes.restoreTileSize:
          {
            emit(state.copyWith(tileSize: () => event.event.data?.size ?? 1));
            break;
          }
        default:
      }
    });
    on<ViewChanged>((event, emit) =>
        emit(state.copyWith(viewIndex: () => event.viewIndex)));
    on<AudioEngineErrorDismissed>(
        (event, emit) => emit(state.copyWith(error: () => null)));
    on<AudioEngineToggled>(
        (event, emit) => _clientRepository.toggleAudioEngine());
    on<FileResampleRequested>((event, emit) =>
        _clientRepository.resampleFile(event.file, event.sampleRate));
    on<TileSizeChanged>(
        (event, emit) => emit(state.copyWith(tileSize: () => event.tileSize)));
    on<TileSizeChangedFinal>(
        (event, emit) => _clientRepository.saveTileSize(event.tileSize));
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
