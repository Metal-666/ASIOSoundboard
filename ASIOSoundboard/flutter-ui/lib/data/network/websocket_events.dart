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
  connectionEstablished,
  appLoaded,
  audioEngineStatus,
  error,
  requestSoundByName,
}

final BiMap<String, WebsocketMessageType> websocketEventsConverter =
    BiMap<String, WebsocketMessageType>()
      ..addAll(<String, WebsocketMessageType>{
        'unknown': WebsocketMessageType.unknown,
        'connection_established': WebsocketMessageType.connectionEstablished,
        'app_loaded': WebsocketMessageType.appLoaded,
        'audio_engine_status': WebsocketMessageType.audioEngineStatus,
        'error': WebsocketMessageType.error,
        'request_sound_by_name': WebsocketMessageType.requestSoundByName,
      });

/// Holds the data of a message.
///
/// The fields of this class represent all possible data that could be sent from the host. In a specfic message, only a few of them will contain the actual data. When composing a message, we choose a named constructor that corresponds to the message type.
///
/// NOTE: The JSON serialization was initally generated using an extension called 'Dart Data Class Generator'. Any further modifications should be done manually, since the nullable fields are handled incorrectly by that extension.
class WebsocketMessageData {
  bool? active;

  ServerError? error;

  String? name;

  WebsocketMessageData({
    this.active,
    this.error,
    this.name,
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
        error: map['error'] == null ? null : ServerError.fromMap(map['error']),
        name: map['name'],
      );

  String toJson() {
    Map<String, dynamic> result = toMap();
    result.removeWhere((key, value) => value == null);

    return json.encode(result);
  }

  factory WebsocketMessageData.fromJson(String source) =>
      WebsocketMessageData.fromMap(json.decode(source));
}

class ServerError {
  final String? category;
  final String? subject;
  final String? error;
  final String? description;
  final String? device;
  final String? path;
  final int? sampleRate;

  const ServerError({
    this.category,
    this.subject,
    this.error,
    this.description,
    this.device,
    this.path,
    this.sampleRate,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'subject': subject,
        'error': error,
        'description': description,
        'device': device,
        'path': path,
        'sample_rate': sampleRate,
      };

  factory ServerError.fromMap(Map<String, dynamic> map) => ServerError(
        category: map['category'],
        subject: map['subject'],
        error: map['error'],
        description: map['description'],
        device: map['device'],
        path: map['path'],
        sampleRate: map['sample_rate']?.toInt(),
      );

  String toJson() => json.encode(toMap());

  factory ServerError.fromJson(String source) =>
      ServerError.fromMap(json.decode(source));
}
