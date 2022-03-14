import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../data/network/client_events.dart';
import '../../data/network/client_repository.dart';
import '../../data/soundboard/soundboard.dart';
import 'events.dart';
import 'state.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final ClientRepository _clientRepository;
  late final StreamSubscription<WebsocketMessage> _subscription;

  final Uuid uuid = const Uuid();

  BoardBloc(this._clientRepository) : super(const BoardState(null, null)) {
    // Start listening to the host events. We are mainly insterested in events related to soundboard state, for example creation or deletion of a Tile.
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<WebsocketEvent>((event, emit) {
      switch (event.message.type) {
        /**/
      }
    });
    on<PlayTileById>((event, emit) {
      Tile? tile =
          state.soundboard?.tiles.firstWhere((tile) => tile?.id == event.id);

      if (tile != null) {
        return _clientRepository.playFile(tile.filePath, tile.volume);
      }
    });
    on<AddNewTile>((event, emit) => emit(
          state.copyWith(
            dialog: () => const NewTileDialog(null, null),
          ),
        ));
    on<PickTilePath>((event, emit) async {
      String? path = await _clientRepository.pickFilePath();

      emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(
          tilePath: () => path,
          shouldOverwritePath: () => true,
        ),
      ));
    });
    on<NewTileDialogClosed>(
        (event, emit) => emit(state.copyWith(dialog: () => null)));
    on<NewTileDialogSubmitted>((event, emit) async {
      String? nameError, pathError;

      if (state.dialog?.tileName == null) {
        nameError = 'Name can\'t be empty';
      }

      if (state.dialog?.tilePath == null) {
        pathError = 'Path can\'t be empty';
      } else if (!(await _clientRepository.fileExists(state.dialog?.tilePath) ??
          false)) {
        pathError = 'File doesn\'t exist';
      }

      if (nameError != null || pathError != null) {
        emit(state.copyWith(
          dialog: () => state.dialog?.copyWith(
            tileNameError: () => nameError,
            tilePathError: () => pathError,
          ),
        ));
      } else {
        final Tile tile = Tile(
          state.dialog!.tilePath,
          state.dialog!.tileName,
          uuid.v1(),
          state.dialog?.tileVolume ?? 1,
        );

        if (state.soundboard == null) {
          emit(state.copyWith(
            soundboard: () => Soundboard(<Tile>[tile]),
            dialog: () => null,
          ));
        } else {
          state.soundboard!.tiles.add(tile);

          emit(state.copyWith(
            dialog: () => null,
            soundboard: () => state.soundboard?.copyWith(
              tiles: () => List.of(state.soundboard?.tiles ?? const <Tile?>[])
                ..add(tile),
            ),
          ));
        }
      }
    });
    on<NewTileNameChanged>((event, emit) => emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(tileName: () => event.name))));
    on<NewTilePathChanged>((event, emit) => emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(tilePath: () => event.path))));
    on<NewTileVolumeChanged>((event, emit) => emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(tileVolume: () => event.volume))));
    on<StopAllSound>((event, emit) => _clientRepository.stopAllSounds());
    on<TileRightClick>((event, emit) {
      if (state.rightClickedTile != event.id) {
        emit(state.copyWith(rightClickedTile: () => event.id));
      } else {
        emit(state.copyWith(rightClickedTile: () => null));
      }
    });
    on<DeleteTile>((event, emit) => emit(state.copyWith(
        soundboard: () => state.soundboard?.copyWith(
            tiles: () => List.of(state.soundboard!.tiles)
              ..removeWhere((Tile? tile) => tile?.id == event.id)))));
    on<EncodeAHKHandle>((event, emit) {
      String handle = Uri.encodeComponent(event.id ?? '');
      Clipboard.setData(ClipboardData(text: handle));
      emit(state.copyWith(encodedAHKHandle: () => handle));
    });
    on<SaveSoundboard>((event, emit) => _clientRepository.saveFile(
        'Json File (*.json)|*.json', 'json', state.soundboard?.toJson()));
    on<LoadSoundboard>((event, emit) async {
      Soundboard soundboard = Soundboard.fromJson(
          await _clientRepository.loadFile('Json File (*.json)|*.json') ??
              '{}');

      emit(state.copyWith(soundboard: () => soundboard));
    });
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
