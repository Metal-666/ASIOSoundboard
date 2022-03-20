import 'package:quiver/collection.dart';

enum CoreGetRequest {
  unknown,
  audioDevices,
  sampleRates,
  pickFile,
  loadFile,
  fileExists,
}

enum CorePostRequest {
  unknown,
  globalVolume,
  startAudioEngine,
  stopAudioEngine,
  fileResampleNeeded,
  saveFile,
  resampleFile,
  reload,
}

enum PublicPostRequest {
  unknown,
  play,
  stop,
}

final BiMap<String, CoreGetRequest> coreGetRequestConverter =
    BiMap<String, CoreGetRequest>()
      ..addAll(<String, CoreGetRequest>{
        'unknown': CoreGetRequest.unknown,
        'audio-devices': CoreGetRequest.audioDevices,
        'sample-rates': CoreGetRequest.sampleRates,
        'pick-file': CoreGetRequest.pickFile,
        'load-file': CoreGetRequest.loadFile,
        'file-exists': CoreGetRequest.fileExists,
      });

final BiMap<String, CorePostRequest> corePostRequestConverter =
    BiMap<String, CorePostRequest>()
      ..addAll(<String, CorePostRequest>{
        'unknown': CorePostRequest.unknown,
        'global-volume': CorePostRequest.globalVolume,
        'start-audio-engine': CorePostRequest.startAudioEngine,
        'stop-audio-engine': CorePostRequest.stopAudioEngine,
        'save-file': CorePostRequest.saveFile,
        'resample-file': CorePostRequest.resampleFile,
        'reload': CorePostRequest.reload,
      });

final BiMap<String, PublicPostRequest> publicPostRequestConverter =
    BiMap<String, PublicPostRequest>()
      ..addAll(<String, PublicPostRequest>{
        'unknown': PublicPostRequest.unknown,
        'play': PublicPostRequest.play,
        'stop': PublicPostRequest.stop,
      });
