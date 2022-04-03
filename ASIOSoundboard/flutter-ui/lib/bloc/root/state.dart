import '../../data/network/websocket_events.dart';

class RootState {
  final int viewIndex;
  final ServerError? error;
  final bool isAudioEngineRunning;

  final double tileSize;

  const RootState(
    this.viewIndex,
    this.error,
    this.isAudioEngineRunning, {
    this.tileSize = 1,
  });

  RootState copyWith({
    int Function()? viewIndex,
    ServerError? Function()? error,
    bool Function()? isAudioEngineRunning,
    double Function()? tileSize,
  }) =>
      RootState(
        viewIndex == null ? this.viewIndex : viewIndex.call(),
        error?.call(),
        isAudioEngineRunning == null
            ? this.isAudioEngineRunning
            : isAudioEngineRunning.call(),
        tileSize: tileSize == null ? this.tileSize : tileSize.call(),
      );
}
