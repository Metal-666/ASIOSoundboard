import 'package:asio_soundboard/data/network/client_events.dart'
    as client_events;

abstract class RootEvent {}

class ClientEvent extends RootEvent {
  final client_events.ClientEvent event;

  ClientEvent(this.event);
}

class ViewChanged extends RootEvent {
  final int viewIndex;

  ViewChanged(this.viewIndex);
}

class AudioEngineToggled extends RootEvent {}

class AudioEngineErrorDismissed extends RootEvent {}

class FileResampleRequested extends RootEvent {
  final String file;
  final int sampleRate;

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
