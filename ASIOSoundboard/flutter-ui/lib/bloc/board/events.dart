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

class NewTileDialogClosed extends BoardEvent {}

class NewTileDialogSubmitted extends BoardEvent {}

class NewTileNameChanged extends BoardEvent {
  final String? name;

  NewTileNameChanged(this.name);
}

class NewTilePathChanged extends BoardEvent {
  final String? path;

  NewTilePathChanged(this.path);
}

class NewTileVolumeChanged extends BoardEvent {
  final double volume;

  NewTileVolumeChanged(this.volume);
}

class StopAllSound extends BoardEvent {}

class TileRightClick extends TileEvent {
  TileRightClick(Tile tile) : super(tile);
}

class DeleteTile extends TileEvent {
  DeleteTile(Tile tile) : super(tile);
}

class EncodeAHKHandle extends TileEvent {
  EncodeAHKHandle(Tile tile) : super(tile);
}

class SaveSoundboard extends BoardEvent {}

class LoadSoundboard extends BoardEvent {}
