import '../../data/network/websocket_events.dart';
import '../../data/soundboard/soundboard.dart';

abstract class BoardEvent {}

abstract class TileEvent extends BoardEvent {
  final Tile tile;

  TileEvent(this.tile);
}

class PageLoaded extends BoardEvent {}

class WebsocketEvent extends BoardEvent {
  final WebsocketMessage message;

  WebsocketEvent(this.message);
}

class PlayTile extends TileEvent {
  PlayTile(Tile tile) : super(tile);
}

class AddNewTile extends BoardEvent {}

class PickTilePath extends BoardEvent {}

class TileDialogClosed extends BoardEvent {}

class TileDialogSubmitted extends BoardEvent {}

class CloseTileTutorial extends BoardEvent {}

class TileDialogNameChanged extends BoardEvent {
  final String? name;

  TileDialogNameChanged(this.name);
}

class TileDialogPathChanged extends BoardEvent {
  final String? path;

  TileDialogPathChanged(this.path);
}

class TileDialogVolumeChanged extends BoardEvent {
  final double volume;

  TileDialogVolumeChanged(this.volume);
}

class StopAllSound extends BoardEvent {}

class TileRightClick extends TileEvent {
  TileRightClick(Tile tile) : super(tile);
}

class DeleteTile extends TileEvent {
  DeleteTile(Tile tile) : super(tile);
}

class EditTile extends TileEvent {
  EditTile(Tile tile) : super(tile);
}

class SaveSoundboard extends BoardEvent {}

class LoadSoundboard extends BoardEvent {}
