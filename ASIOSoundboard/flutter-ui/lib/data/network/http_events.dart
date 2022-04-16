import 'package:quiver/collection.dart';

enum CoreGetRequest {
  unknown,
  audioDevices,
  sampleRates,
  pickFile,
  loadFile,
  readFile,
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
        'read-file': CoreGetRequest.readFile,
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
      });

final BiMap<String, PublicPostRequest> publicPostRequestConverter =
    BiMap<String, PublicPostRequest>()
      ..addAll(<String, PublicPostRequest>{
        'unknown': PublicPostRequest.unknown,
        'play': PublicPostRequest.play,
        'stop': PublicPostRequest.stop,
      });
