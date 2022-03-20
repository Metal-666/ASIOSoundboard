import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/network/client_repository.dart';
import '../../data/network/websocket_events.dart';
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

    on<PageLoaded>((event, emit) {
      /**/
    });
    on<WebsocketEvent>((event, emit) {
      switch (event.message.type) {
        case WebsocketMessageType.requestSoundByName:
          {
            if (state.soundboard != null) {
              for (Tile tile in state.soundboard!.tiles.where((element) =>
                  element.filePath != null &&
                  element.name == event.message.data?.name)) {
                _clientRepository.playFile(tile.filePath!, tile.volume);
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
            event.tile.filePath!, event.tile.volume);
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
          state.dialog?.tileVolume ?? 1,
        );

        if (state.soundboard == null) {
          emit(state.copyWith(
            soundboard: () => Soundboard(<Tile>[tile]),
            dialog: () => null,
          ));
        } else {
          emit(state.copyWith(
            dialog: () => null,
            soundboard: () => state.soundboard?.copyWith(
              tiles: () =>
                  List.of(state.soundboard?.tiles ?? const <Tile>[])..add(tile),
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
    on<EncodeAHKHandle>((event, emit) {
      //String handle = Uri.encodeComponent(event.id ?? '');
      //Clipboard.setData(ClipboardData(text: handle));

      //emit(state.copyWith(encodedAHKHandle: () => handle));
    });
    on<SaveSoundboard>((event, emit) async {
      if (state.soundboard != null) {
        log('Saving soundboard...');

        await _clientRepository.saveFile(
            'Json File (*.json)|*.json', 'json', state.soundboard!.toJson());
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
