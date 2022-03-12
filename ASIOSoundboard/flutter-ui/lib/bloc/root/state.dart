class RootState {
  final int viewIndex;
  final Error? error;
  final bool isAudioEngineRunning;

  final double tileSize;

  const RootState(this.viewIndex, this.error, this.isAudioEngineRunning,
      {this.tileSize = 1});

  RootState copyWith(
          {int Function()? viewIndex,
          Error? Function()? error,
          bool Function()? isAudioEngineRunning,
          double Function()? tileSize}) =>
      RootState(
          viewIndex == null ? this.viewIndex : viewIndex.call(),
          error?.call(),
          isAudioEngineRunning == null
              ? this.isAudioEngineRunning
              : isAudioEngineRunning.call(),
          tileSize: tileSize == null ? this.tileSize : tileSize.call());
}

class Error {
  final String? error;
  final String? description;
  final String? resampleFile;
  final int? sampleRate;

  const Error(this.error, this.description,
      {this.resampleFile, this.sampleRate});
}
