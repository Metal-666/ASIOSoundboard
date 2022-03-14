import '../../data/network/client_events.dart';

abstract class BoardEvent {}

abstract class IdEvent extends BoardEvent {
  final String? id;

  IdEvent(this.id);
}

class WebsocketEvent extends BoardEvent {
  final WebsocketMessage message;

  WebsocketEvent(this.message);
}

class PlayTileById extends IdEvent {
  PlayTileById(String? id) : super(id);
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

class TileRightClick extends IdEvent {
  TileRightClick(String? id) : super(id);
}

class DeleteTile extends IdEvent {
  DeleteTile(String? id) : super(id);
}

class EncodeAHKHandle extends IdEvent {
  EncodeAHKHandle(String? id) : super(id);
}

class SaveSoundboard extends BoardEvent {}

class LoadSoundboard extends BoardEvent {}
