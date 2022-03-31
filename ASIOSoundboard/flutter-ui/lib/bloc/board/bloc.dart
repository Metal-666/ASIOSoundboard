import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';

import '../../data/network/client_repository.dart';
import '../../data/network/websocket_events.dart';
import '../../data/settings/settings_repository.dart';
import '../../data/soundboard/soundboard.dart';
import 'events.dart';
import 'state.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final ClientRepository _clientRepository;
  final SettingsRepository _settingsRepository;

  late final StreamSubscription<WebsocketMessage> _subscription;

  BoardBloc(this._clientRepository, this._settingsRepository)
      : super(const BoardState(null, null)) {
    // Start listening to the host events. We are mainly insterested in events related to soundboard state, for example creation or deletion of a Tile.
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<PageLoaded>(
        (event, emit) async => _clientRepository.notifyBlocLoaded(this));
    on<WebsocketEvent>((event, emit) async {
      switch (event.message.type) {
        case WebsocketMessageType.appLoaded:
          {
            if (_settingsRepository.defaultSoundboard != null) {
              String? content = await _clientRepository
                  .readFile(_settingsRepository.defaultSoundboard);

              if (content != null) {
                emit(state.copyWith(
                    soundboard: () => Soundboard.fromJson(content)));
              }
            }

            break;
          }
        case WebsocketMessageType.requestSoundByName:
          {
            if (state.soundboard != null) {
              for (Tile tile in state.soundboard!.tiles.where((element) =>
                  element.filePath != null &&
                  element.name == event.message.data?.name)) {
                _clientRepository.playFile(
                  tile.filePath!,
                  tile.volume,
                );
              }
            }
            break;
          }
        default:
      }
    });
    on<PlayTile>((event, emit) async {
      if (event.tile.filePath != null) {
        await _clientRepository.playFile(
          event.tile.filePath!,
          event.tile.volume,
        );
      }
    });
    on<AddNewTile>((event, emit) => emit(state.copyWith(
          dialog: () => const TileDialog(null, null),
        )));
    on<PickTilePath>((event, emit) async {
      String? path = await _clientRepository.pickFilePath();

      emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(
          tilePath: () => path,
          shouldOverwritePath: () => true,
        ),
      ));
    });
    on<TileDialogClosed>(
        (event, emit) => emit(state.copyWith(dialog: () => null)));
    on<TileDialogSubmitted>((event, emit) async {
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
          state.dialog?.tileVolume ?? 1,
        );
        if (state.dialog?.editedTile == null) {
          if (state.soundboard == null) {
            emit(state.copyWith(
              soundboard: () => Soundboard(<Tile>[tile]),
              dialog: () => null,
            ));
          } else {
            emit(state.copyWith(
              dialog: () => null,
              soundboard: () => state.soundboard?.copyWith(
                tiles: () => List.of(state.soundboard!.tiles)..add(tile),
              ),
            ));
          }
        } else {
          emit(state.copyWith(
            dialog: () => null,
            soundboard: () => state.soundboard?.copyWith(
                tiles: () => List.of(state.soundboard!.tiles)
                  ..insert(
                      state.soundboard!.tiles
                          .indexOf(state.dialog!.editedTile!),
                      tile)
                  ..remove(state.dialog?.editedTile)),
          ));
        }
      }
    });
    on<TileDialogNameChanged>((event, emit) => emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(tileName: () => event.name))));
    on<TileDialogPathChanged>((event, emit) => emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(tilePath: () => event.path))));
    on<TileDialogVolumeChanged>((event, emit) => emit(state.copyWith(
        dialog: () => state.dialog?.copyWith(tileVolume: () => event.volume))));
    on<StopAllSound>((event, emit) => _clientRepository.stopAllSounds());
    on<TileRightClick>((event, emit) {
      if (state.rightClickedTile != event.tile) {
        emit(state.copyWith(rightClickedTile: () => event.tile));
      } else {
        emit(state.copyWith(rightClickedTile: () => null));
      }
    });
    on<DeleteTile>((event, emit) => emit(state.copyWith(
        soundboard: () => state.soundboard?.copyWith(
            tiles: () =>
                List.of(state.soundboard!.tiles)..remove(event.tile)))));
    on<EditTile>((event, emit) => emit(state.copyWith(
          dialog: () => TileDialog(
            event.tile.name,
            event.tile.filePath,
            tileVolume: event.tile.volume ?? 1,
            shouldOverwriteName: true,
            shouldOverwritePath: true,
            editedTile: event.tile,
          ),
        )));
    on<SaveSoundboard>((event, emit) async {
      if (state.soundboard != null) {
        log('Saving soundboard...');

        String? path = await _clientRepository.saveFile(
          'Json File (*.json)|*.json',
          'json',
          state.soundboard!.toJson(),
        );

        if (path != null) {
          _settingsRepository.defaultSoundboard = path;
        }
      } else {
        log('Can\'t save soundboard - it\'s null');
      }
    });
    on<LoadSoundboard>((event, emit) async {
      String? content =
          await _clientRepository.loadFile('Json File (*.json)|*.json');

      if (content != null) {
        emit(state.copyWith(soundboard: () => Soundboard.fromJson(content)));
      }
    });
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
