import 'dart:convert';

import '../soundboard/soundboard.dart';

/// Encapsulates the type and the data of a message received from the host.
class ClientEvent {
  final EventTypes type;
  final EventData? data;

  ClientEvent(this.type, this.data);
}

enum EventTypes {
  unknown,
  startedAudioEngine,
  stoppedAudioEngine,
  toggleAudioEngine,
  audioEngineError,
  invalidSampleRateError,
  listAudioDevices,
  listSampleRates,
  setAudioDevice,
  setSampleRate,
  setGlobalVolume,
  getSoundboard,
  playTileById,
  validateNewTile,
  pickTilePath,
  fileResampleNeeded,
  stopAllSounds,
  deleteTile,
  saveSoundboard,
  loadSoundboard,
  saveTileSize,
  restoreTileSize,
  saveGlobalVolume,
  restoreGlobalVolume,
  restoreAudioDevice,
  restoreSampleRate
}

/// Holds the data of a message.
///
/// The fields of this class represent all possible data that could be sent from the host. In a specfic message, only a few of them will contain the actual data. When composing a message, we choose a named constructor that corresponds to the message type.
///
/// NOTE: The JSON serialization was initally generated using an extension called 'Dart Data Class Generator'. Any further modifications should be done manually, since the nullable fields aree handled incorrectly by that extension.
class EventData {
  String? error;
  String? description;

  String? file;

  List<int>? sampleRates;
  int? sampleRate;

  List<String>? audioDevices;
  String? audioDevice;

  Soundboard? soundboard;

  String? name;
  String? id;

  double? volume;
  double? size;

  EventData(
      {this.error,
      this.description,
      this.file,
      this.sampleRates,
      this.sampleRate,
      this.audioDevices,
      this.audioDevice,
      this.soundboard,
      this.name,
      this.id,
      this.volume,
      this.size});

  EventData.audioEngineError(this.error, this.description);
  EventData.listAudioDevices(this.audioDevices);
  EventData.listSampleRates(this.sampleRates);
  EventData.setAudioDevice(this.audioDevice);
  EventData.setSampleRate(this.sampleRate);
  EventData.tile(this.id);
  EventData.validateNewTile(this.file, this.name, this.volume);
  EventData.resampleFile(this.file, this.sampleRate);
  EventData.setGlobalVolume(this.volume);
  EventData.setTileSize(this.size);

  Map<String, dynamic> toMap() => {
        'error': error,
        'description': description,
        'file': file,
        'sample_rates': sampleRates,
        'sample_rate': sampleRate,
        'audio_devices': audioDevices,
        'audio_device': audioDevice,
        'soundboard': soundboard?.toMap(),
        'name': name,
        'id': id,
        'volume': volume,
        'size': size
      };

  factory EventData.fromMap(Map<String, dynamic> map) => EventData(
      error: map['error'],
      description: map['description'],
      file: map['file'],
      sampleRates: List<int>.from(map['sample_rates'] ?? const []),
      sampleRate: map['sample_rate'],
      audioDevices: List<String>.from(map['audio_devices'] ?? const []),
      audioDevice: map['audio_device'],
      soundboard: map['soundboard'] != null
          ? Soundboard.fromMap(map['soundboard'])
          : null,
      name: map['name'],
      id: map['id'],
      volume: map['volume']?.toDouble(),
      size: map['size']?.toDouble());

  String toJson() {
    Map<String, dynamic> result = toMap();
    result.removeWhere((key, value) => value == null);

    return json.encode(result);
  }

  factory EventData.fromJson(String source) =>
      EventData.fromMap(json.decode(source));
}
