import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:uuid/uuid.dart';

import 'http_events.dart';
import 'websocket_events.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This class acts as a client for the UI. It is used for connecting, disconnecting, sending and receiving messages from the host.
class ClientRepository {
  WebSocketChannel? _channel;
  final Client _client = Client();

  // This event bus is subscribed to by the blocs and is used for handling UI updates coming from the server.
  final StreamController<WebsocketMessage> eventStream =
      StreamController<WebsocketMessage>.broadcast();

  void init() {
    debugPrint('Attempting to connect to the server');

    if (_channel == null || _channel?.closeCode != null) {
      _channel = WebSocketChannel.connect(
          Uri.parse('ws://localhost:29873/websockets'));
      // When we are connected to the host, any message received will be deserialized from JSON and an event with the message type and data will be sent to the event bus.
      _channel?.stream.listen((json) {
        debugPrint('Received a message: $json');

        final Map<String, dynamic> message = jsonDecode(json);
        final WebsocketMessageData messageData =
            WebsocketMessageData.fromMap(message['data']);

        final WebsocketMessageType type =
            websocketEventsConverter[message['type']] ??
                WebsocketMessageType.unknown;

        eventStream.add(WebsocketMessage(type, messageData));
      });
    } else {
      debugPrint('Connection failed - client is null or already connected');
    }
  }

  Future<List<String>?> listAudioDevices() {
    debugPrint('Retrieving audio devices...');

    return _makeCoreGetRequest(CoreGetRequest.audioDevices)
        .then((value) => (value as List<dynamic>).cast<String>());
  }

  Future<List<int>?> listSampleRates() {
    debugPrint('Retrieving sample rates...');

    return _makeCoreGetRequest(CoreGetRequest.sampleRates)
        .then((value) => (value as List<dynamic>).cast<int>());
  }

  Future<String?> pickFilePath() {
    debugPrint('Picking file...');

    return _makeCoreGetRequest(CoreGetRequest.pickFile)
        .then((value) => value as String);
  }

  Future<String?> loadFile(String? filter) {
    debugPrint('Loading file...');

    return _makeCoreGetRequest(
      CoreGetRequest.loadFile,
      <String, String?>{
        'filter': filter,
      },
    ).then((value) => value as String);
  }

  Future<bool?> fileExists(String? path) {
    debugPrint('Checking if file exists...');

    return _makeCoreGetRequest(
      CoreGetRequest.fileExists,
      <String, String?>{
        'path': path,
      },
    ).then((value) => value as bool);
  }

  Future<void> setAudioDevice(String? audioDevice) {
    debugPrint('Setting Audio Device...');

    return _makeCorePostRequest(
      CorePostRequest.audioDevice,
      <String, String?>{'device': audioDevice},
    );
  }

  Future<void> setSampleRate(int sampleRate) {
    debugPrint('Setting Sample Rate...');

    return _makeCorePostRequest(
      CorePostRequest.audioDevice,
      <String, int>{'rate': sampleRate},
    );
  }

  Future<void> setGlobalVolume(double glbablVolume) {
    debugPrint('Setting Global Volume...');

    return _makeCorePostRequest(
      CorePostRequest.audioDevice,
      <String, double>{'volume': glbablVolume},
    );
  }

  Future<void> toggleAudioEngine() {
    debugPrint('Toggling Audio Engine...');

    return _makeCorePostRequest(CorePostRequest.toggleAudioEngine);
  }

  Future<void> resampleFile(String? file, int? sampleRate) {
    debugPrint('Requesting file resample ($file)');

    return _makeCorePostRequest(
      CorePostRequest.resampleFile,
      <String, dynamic>{
        'file': file,
        'rate': sampleRate,
      },
    );
  }

  Future<void> saveFile(String? filter, String? defaultExt, String? content) {
    debugPrint('Saving a file...');

    return _makeCorePostRequest(
      CorePostRequest.saveFile,
      <String, String?>{
        'filter': filter,
        'default_ext': defaultExt,
        'content': content
      },
    );
  }

  Future<void> playFile(String? file, double? volume) {
    debugPrint('Playing file: $file');

    return _makePublicPostRequest(
      PublicPostRequest.play,
      <String, dynamic>{
        'file': file,
        'volume': volume,
      },
    );
  }

  Future<void> stopAllSounds() {
    debugPrint('Stopping all sounds...');

    return _makePublicPostRequest(PublicPostRequest.stop);
  }

  void _sendWebsocketMessage(WebsocketMessageType type,
      {WebsocketMessageData? data}) {
    if (_channel?.closeCode == null) {
      final String eventType = websocketEventsConverter.inverse[type] ??
          websocketEventsConverter.inverse[WebsocketMessageType.unknown]!;
      final String? jsonData = data?.toJson();

      _channel?.sink.add(jsonEncode({'event': eventType, 'data': jsonData}));
      debugPrint('Sent a message: "$eventType", data: $jsonData');
    } else {
      debugPrint('Failed to send a message - client is null or not connected');
    }
  }

  Future<dynamic> _makeCoreGetRequest(CoreGetRequest request,
      [Map<String, dynamic>? queryParameters]) async {
    Response response = await _client.get(Uri.http(
        'localhost:29873',
        '/controller/core/' +
            (coreGetRequestConverter.inverse[request] ??
                coreGetRequestConverter.inverse[CoreGetRequest.unknown]!),
        queryParameters));
    if (response.statusCode == 200) {
      String body = response.body;

      debugPrint('Received a response: $body');

      return jsonDecode(body);
    }
    debugPrint('Host responded with an error!');
    return null;
  }

  Future<void> _makeCorePostRequest(CorePostRequest request,
          [Map<String, dynamic>? body]) async =>
      _client.post(
          Uri.http(
              'localhost:29873',
              '/controller/core/' +
                  (corePostRequestConverter.inverse[request] ??
                      corePostRequestConverter
                          .inverse[CorePostRequest.unknown]!)),
          body: body);

  Future<void> _makePublicPostRequest(PublicPostRequest request,
          [Map<String, dynamic>? body]) async =>
      _client.post(
          Uri.http(
              'localhost:29873',
              '/controller/public/' +
                  (publicPostRequestConverter.inverse[request] ??
                      publicPostRequestConverter
                          .inverse[PublicPostRequest.unknown]!)),
          body: body);
}
