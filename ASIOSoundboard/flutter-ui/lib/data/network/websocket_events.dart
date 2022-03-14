import 'dart:convert';

import 'package:quiver/collection.dart';

/// Encapsulates the type and the data of a message received from the host.
class WebsocketMessage {
  final WebsocketMessageType type;
  final WebsocketMessageData? data;

  WebsocketMessage(this.type, this.data);
}

enum WebsocketMessageType {
  unknown,
  audioEngineStatus,
  error,
  fileError,
  fileResampleNeeded,
}

final BiMap<String, WebsocketMessageType> websocketEventsConverter =
    BiMap<String, WebsocketMessageType>()
      ..addAll(<String, WebsocketMessageType>{
        'unknown': WebsocketMessageType.unknown,
        'audio_engine_status': WebsocketMessageType.audioEngineStatus,
        'error': WebsocketMessageType.error,
        'file_error': WebsocketMessageType.fileError,
        'file_resample_nedeed': WebsocketMessageType.fileResampleNeeded,
      });

/// Holds the data of a message.
///
/// The fields of this class represent all possible data that could be sent from the host. In a specfic message, only a few of them will contain the actual data. When composing a message, we choose a named constructor that corresponds to the message type.
///
/// NOTE: The JSON serialization was initally generated using an extension called 'Dart Data Class Generator'. Any further modifications should be done manually, since the nullable fields are handled incorrectly by that extension.
class WebsocketMessageData {
  bool? active;

  Error? error;

  WebsocketMessageData({
    this.active,
    this.error,
  });

  WebsocketMessageData.audioEngineStatus(this.active);
  WebsocketMessageData.error(this.error);

  Map<String, dynamic> toMap() => {
        'active': active,
        'error': error?.toMap(),
      };

  factory WebsocketMessageData.fromMap(Map<String, dynamic> map) =>
      WebsocketMessageData(
        active: map['active'],
        error: map['error'] == null ? null : Error.fromJson(map['error']),
      );

  String toJson() {
    Map<String, dynamic> result = toMap();
    result.removeWhere((key, value) => value == null);

    return json.encode(result);
  }

  factory WebsocketMessageData.fromJson(String source) =>
      WebsocketMessageData.fromMap(json.decode(source));
}

class Error {
  final String? error;
  final String? description;
  final String? file;
  final int? sampleRate;

  const Error({
    this.error,
    this.description,
    this.file,
    this.sampleRate,
  });

  Map<String, dynamic> toMap() => {
        'error': error,
        'description': description,
        'file': file,
        'sample_rate': sampleRate,
      };

  factory Error.fromMap(Map<String, dynamic> map) => Error(
        error: map['error'],
        description: map['description'],
        file: map['file'],
        sampleRate: map['sample_rate']?.toInt(),
      );

  String toJson() => json.encode(toMap());

  factory Error.fromJson(String source) => Error.fromMap(json.decode(source));
}
