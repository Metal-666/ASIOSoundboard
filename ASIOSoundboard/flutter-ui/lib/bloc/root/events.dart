import '../../data/network/websocket_events.dart';

abstract class RootEvent {}

class AppLoaded extends RootEvent {}

class WebsocketEvent extends RootEvent {
  final WebsocketMessage message;

  WebsocketEvent(this.message);
}

class ViewChanged extends RootEvent {
  final int viewIndex;

  ViewChanged(this.viewIndex);
}

class AudioEngineToggled extends RootEvent {}

class ErrorDialogDismissed extends RootEvent {}

class FileResampleRequested extends RootEvent {
  final String? file;
  final int? sampleRate;

  FileResampleRequested(this.file, this.sampleRate);
}

abstract class TileSizeEvent extends RootEvent {
  final double tileSize;

  TileSizeEvent(this.tileSize);
}

class TileSizeChanged extends TileSizeEvent {
  TileSizeChanged(double tileSize) : super(tileSize);
}

class TileSizeChangedFinal extends TileSizeEvent {
  TileSizeChangedFinal(double tileSize) : super(tileSize);
}
