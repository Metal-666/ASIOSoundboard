class RootState {
  final int viewIndex;
  final ErrorDialog? errorDialog;
  final bool isAudioEngineRunning;

  final double tileSize;

  const RootState(this.viewIndex, this.errorDialog, this.isAudioEngineRunning,
      {this.tileSize = 1});

  RootState copyWith(
          {int Function()? viewIndex,
          ErrorDialog? Function()? errorDialog,
          bool Function()? isAudioEngineRunning,
          double Function()? tileSize}) =>
      RootState(
          viewIndex == null ? this.viewIndex : viewIndex.call(),
          errorDialog?.call(),
          isAudioEngineRunning == null
              ? this.isAudioEngineRunning
              : isAudioEngineRunning.call(),
          tileSize: tileSize == null ? this.tileSize : tileSize.call());
}

class ErrorDialog {
  final String? error;
  final String? description;

  ErrorDialog({
    this.error = 'GENERIC ERROR',
    this.description = 'Something went wrong',
  });
}

class FileErrorDialog extends ErrorDialog {
  final String? file;

  FileErrorDialog({
    this.file,
    String? error = 'GENERIC FILE ERROR',
    String? description,
  }) : super(
          error: error,
          description: description,
        );
}

class ResampleNeededDialog extends FileErrorDialog {
  final int? sampleRate;

  ResampleNeededDialog({
    this.sampleRate,
    String? file,
    String? error = 'GENERIC RESAMPLING ERROR',
    String? description,
  }) : super(
          file: file,
          error: error,
          description: description,
        );
}
