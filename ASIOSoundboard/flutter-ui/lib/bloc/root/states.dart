class RootState {
  final int viewIndex;
  final Error? error;
  final bool isAudioEngineRunning;

  final double tileSize;

  RootState(this.viewIndex, this.error, this.isAudioEngineRunning,
      {this.tileSize = 1});

  RootState changeError(Error? error) =>
      RootState(viewIndex, error, isAudioEngineRunning, tileSize: tileSize);

  RootState changeViewIndex(int viewIndex) =>
      RootState(viewIndex, null, isAudioEngineRunning, tileSize: tileSize);

  RootState changeAudioEngine(bool isAudioEngineRunning) =>
      RootState(viewIndex, null, isAudioEngineRunning, tileSize: tileSize);

  RootState changeTileSize(double tileSize) =>
      RootState(viewIndex, null, isAudioEngineRunning, tileSize: tileSize);
}

class Error {
  final String? error;
  final String? description;
  final String? resampleFile;
  final int? sampleRate;

  Error(this.error, this.description, {this.resampleFile, this.sampleRate});
}
