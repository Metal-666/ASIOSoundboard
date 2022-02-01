import 'dart:async';

import 'package:asio_soundboard/data/network/client_events.dart'
    as client_events;
import 'package:asio_soundboard/data/soundboard/soundboard.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';

import '../../data/network/client_repository.dart';
import 'events.dart';
import 'states.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final ClientRepository _clientRepository;
  late final StreamSubscription<client_events.ClientEvent> _subscription;

  BoardBloc(this._clientRepository) : super(BoardState(null, null)) {
    // Start listening to the host events. We are mainly insterested in events related to soundboard state, for example creation or deletion of a Tile.
    _subscription = _clientRepository.eventStream.stream
        .listen((client_events.ClientEvent event) => add(ClientEvent(event)));

    on<ClientEvent>((event, emit) {
      switch (event.event.type) {
        case client_events.EventTypes.getSoundboard:
          {
            emit(state.setSoundboard(event.event.data?.soundboard));
            break;
          }
        case client_events.EventTypes.validateNewTile:
          {
            bool isNameValid = event.event.data?.name != null,
                isPathValid = event.event.data?.file != null,
                isIdPresent = event.event.data?.id != null;
            if (isNameValid && isPathValid && isIdPresent) {
              final Tile tile = Tile(
                  event.event.data!.file,
                  event.event.data!.name,
                  event.event.data!.id,
                  event.event.data?.volume);
              if (state.soundboard == null) {
                emit(state
                    .setSoundboard(Soundboard(<Tile>[tile]))
                    .setDialog(null));
              } else {
                state.soundboard!.tiles.add(tile);
                emit(state.setDialog(null));
              }
            } else {
              emit(state.setDialog(state.dialog
                  ?.changeValidity(isNameValid, isPathValid, true)));
            }
            break;
          }
        case client_events.EventTypes.pickTilePath:
          {
            emit(state
                .setDialog(state.dialog?.changePath(event.event.data?.file)));
            break;
          }
        case client_events.EventTypes.deleteTile:
          {
            state.soundboard!.tiles
                .removeWhere((Tile? tile) => tile?.id == event.event.data?.id);
            emit(state.setSoundboard(state.soundboard));
            break;
          }
        default:
      }
    });
    on<PlayTileById>((event, emit) => _clientRepository.playTileById(event.id));
    on<AddNewTile>(
        (event, emit) => emit(state.setDialog(NewTileDialog(null, null))));
    on<PickTilePath>((event, emit) => _clientRepository.pickTilePath());
    on<NewTileDialogClosed>((event, emit) => emit(state.setDialog(null)));
    on<NewTileDialogSubmitted>((event, emit) {
      _clientRepository.validateNewTile(state.dialog?.tileName,
          state.dialog?.tilePath, state.dialog?.tileVolume ?? 1);
    });
    on<NewTileNameChanged>((event, emit) =>
        emit(state.setDialog(state.dialog?.changeName(event.name))));
    on<NewTilePathChanged>((event, emit) =>
        emit(state.setDialog(state.dialog?.changePath(event.path))));
    on<NewTileVolumeChanged>((event, emit) =>
        emit(state.setDialog(state.dialog?.changeVolume(event.volume))));
    on<StopAllSound>((event, emit) => _clientRepository.stopAllSound());
    on<TileRightClick>((event, emit) {
      if (state.rightClickedTile != event.id) {
        emit(state.setRightClickedTile(event.id));
      } else {
        emit(state.setRightClickedTile(null));
      }
    });
    on<DeleteTile>((event, emit) => _clientRepository.deleteTile(event.id));
    on<EncodeAHKHandle>((event, emit) {
      String handle = Uri.encodeComponent(event.id ?? '');
      Clipboard.setData(ClipboardData(text: handle));
      emit(state.setEncodedAHKHandle(handle));
    });
    on<SaveSoundboard>((event, emit) => _clientRepository.saveSoundboard());
    on<LoadSoundboard>((event, emit) => _clientRepository.loadSoundboard());
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
