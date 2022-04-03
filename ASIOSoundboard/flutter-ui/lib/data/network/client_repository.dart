import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';

import '../../main.dart';
import 'http_events.dart';
import 'websocket_events.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This class acts as a client for the UI. It is used for connecting, disconnecting, sending and receiving messages from the host.
class ClientRepository {
  WebSocketChannel? _channel;
  final Client _client = Client();

  // This event bus is subscribed to by the blocs and is used for handling UI updates coming from the server.
  final StreamController<WebsocketMessage> eventStream =
      StreamController<WebsocketMessage>.broadcast();

  void initWebsockets() {
    log('Attempting to connect to the websocket server');

    if (_channel == null || _channel?.closeCode != null) {
      try {
        _channel = WebSocketChannel.connect(
            Uri.parse('ws://localhost:29873/websockets'));
        // When we are connected to the host, any message received will be deserialized from JSON and an event with the message type and data will be sent to the event bus.
        _channel?.stream.listen(
          (json) {
            log('Received a message: $json');

            final Map<String, dynamic> message = jsonDecode(json);
            final WebsocketMessageData messageData =
                WebsocketMessageData.fromMap(message['data']);

            final WebsocketMessageType type =
                websocketEventsConverter[message['type']] ??
                    WebsocketMessageType.unknown;

            eventStream.add(WebsocketMessage(type, messageData));
          },
          onError: (error) => log('WebSocket channel emitted an error: $error'),
        );
      } catch (e) {
        log('WebSocket connection failed - $e');
      }
    } else {
      log('WebSocket connection failed - client is null or already connected');
    }
  }

  void notifyBlocLoaded(Bloc bloc) {
    if (!(loadedBlocs[bloc] ?? false)) {
      loadedBlocs[bloc] = true;

      if (!loadedBlocs.values.contains(false)) {
        _sendWebsocketMessage(WebsocketMessageType.appLoaded);
      }
    }
  }

  Future<List<String>?> listAudioDevices() {
    log('Retrieving audio devices...');

    return _makeCoreGetRequest(CoreGetRequest.audioDevices)
        .then((value) => (value?['devices'] as List<dynamic>?)?.cast<String>());
  }

  Future<List<int>?> listSampleRates() {
    log('Retrieving sample rates...');

    return _makeCoreGetRequest(CoreGetRequest.sampleRates)
        .then((value) => (value?['rates'] as List<dynamic>?)?.cast<int>());
  }

  Future<String?> pickFilePath() {
    log('Picking file...');

    return _makeCoreGetRequest(CoreGetRequest.pickFile)
        .then((value) => value?['file'] as String);
  }

  Future<String?> loadFile(String? filter) {
    log('Loading file...');

    return _makeCoreGetRequest(
      CoreGetRequest.loadFile,
      <String, String?>{
        'filter': filter,
      },
    ).then((value) => value?['content'] as String?);
  }

  Future<String?> readFile(String? path) {
    log('Reading file ($path)...');

    return _makeCoreGetRequest(
      CoreGetRequest.readFile,
      <String, String?>{
        'path': path,
      },
    ).then((value) => value?['content'] as String?);
  }

  Future<bool?> fileExists(String? path) {
    log('Checking if file exists...');

    return _makeCoreGetRequest(
      CoreGetRequest.fileExists,
      <String, String?>{
        'path': path,
      },
    ).then((value) => value?['exists'] as bool?);
  }

  Future<void> setGlobalVolume(double glbablVolume) {
    log('Setting Global Volume...');

    return _makeCorePostRequest(
      CorePostRequest.globalVolume,
      <String, String>{'volume': glbablVolume.toString()},
    );
  }

  Future<void> startAudioEngine(
    String? audioDevice,
    int? sampleRate,
    double? globalVolume,
  ) {
    log('Starting Audio Engine with AudioDevice=$audioDevice, SampleRate=$sampleRate and GlobalVolume=$globalVolume');

    return _makeCorePostRequest(
        CorePostRequest.startAudioEngine, <String, String>{
      'device': audioDevice.toString(),
      'rate': sampleRate.toString(),
      'volume': globalVolume.toString(),
    });
  }

  Future<void> stopAudioEngine() {
    log('Stopping Audio Engine...');

    return _makeCorePostRequest(CorePostRequest.stopAudioEngine);
  }

  Future<void> resampleFile(String file, int sampleRate) {
    log('Requesting file resample ($file)');

    return _makeCorePostRequest(
      CorePostRequest.resampleFile,
      <String, String>{
        'file': file,
        'rate': sampleRate.toString(),
      },
    );
  }

  Future<void> reloadApp() {
    log('Reloading app...');

    return _makeCorePostRequest(CorePostRequest.reload);
  }

  Future<String?> saveFile(String filter, String defaultExt, String content) {
    log('Saving a file...');

    return _makeCorePostRequest(
      CorePostRequest.saveFile,
      <String, String>{
        'filter': filter,
        'ext': defaultExt,
        'content': content,
      },
    ).then((value) => value['path'] as String?);
  }

  Future<void> playFile(String file, double? volume) {
    log('Playing file: $file');

    return _makePublicPostRequest(
      PublicPostRequest.play,
      <String, String>{
        'file': file,
        'volume': (volume ?? 1).toString(),
      },
    );
  }

  Future<void> stopAllSounds() {
    log('Stopping all sounds...');

    return _makePublicPostRequest(PublicPostRequest.stop);
  }

  void _sendWebsocketMessage(
    WebsocketMessageType type, {
    WebsocketMessageData? data,
  }) {
    if (_channel?.closeCode == null) {
      final String eventType = websocketEventsConverter.inverse[type] ??
          websocketEventsConverter.inverse[WebsocketMessageType.unknown]!;
      final String? jsonData = data?.toJson();

      _channel?.sink.add(jsonEncode({
        'event': eventType,
        'data': jsonData,
      }));
      log('Sent a message: "$eventType", data: $jsonData');
    } else {
      log('Failed to send a message - client is null or not connected');
    }
  }

  Future<dynamic> _makeCoreGetRequest(
    CoreGetRequest request, [
    Map<String, dynamic>? queryParameters,
  ]) async {
    final Response response = await _makeGetRequest(
      Uri.http(
        'localhost:29873',
        '/controller/core/' +
            (coreGetRequestConverter.inverse[request] ??
                coreGetRequestConverter.inverse[CoreGetRequest.unknown]!),
        queryParameters,
      ),
    );

    final String body = response.body;

    log('Received a response: $body');

    if (response.statusCode == 200 && body.isNotEmpty) {
      return jsonDecode(body);
    } else {
      log('Host responded with an error!');

      return null;
    }
  }

  Future<dynamic> _makeCorePostRequest(
    CorePostRequest request, [
    Map<String, String>? body,
  ]) async {
    final Response response = await _makePostRequest(
      Uri.http(
        'localhost:29873',
        '/controller/core/' +
            (corePostRequestConverter.inverse[request] ??
                corePostRequestConverter.inverse[CorePostRequest.unknown]!),
      ),
      body: body,
    );

    final String responseBody = response.body;

    log('Received a response: $body');

    if (response.statusCode == 200) {
      if (responseBody.isNotEmpty) {
        return jsonDecode(responseBody);
      }

      return null;
    } else {
      log('Host responded with an error!');

      return null;
    }
  }

  Future<dynamic> _makePublicPostRequest(
    PublicPostRequest request, [
    Map<String, String>? body,
  ]) async {
    final Response response = await _makePostRequest(
      Uri.http(
        'localhost:29873',
        '/controller/public/' +
            (publicPostRequestConverter.inverse[request] ??
                publicPostRequestConverter.inverse[PublicPostRequest.unknown]!),
      ),
      body: body,
    );

    final String responseBody = response.body;

    log('Received a response: $body');

    if (response.statusCode == 200) {
      if (responseBody.isNotEmpty) {
        return jsonDecode(responseBody);
      }

      return null;
    } else {
      log('Host responded with an error!');

      return null;
    }
  }

  Future<Response> _makeGetRequest(Uri uri) {
    return _client.get(uri).then((value) {
      log('Made a GET request to $uri');

      return value;
    });
  }

  Future<Response> _makePostRequest(Uri uri, {Object? body}) {
    return _client.post(uri, body: body).then((value) {
      log('Made a POST request to $uri');

      return value;
    });
  }
}
