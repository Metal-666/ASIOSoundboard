import 'dart:async';
import 'dart:convert';

import 'client_events.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This class acts as a client for the UI. It is used for connecting, disconnecting, sending and receiving messages from the host.
class ClientRepository {
  WebSocketChannel? _channel;

  // This event bus is subscribed to by the blocs and is used for handling UI updates coming from the server.
  final StreamController<ClientEvent> eventStream =
      StreamController<ClientEvent>.broadcast();

  void connect() {
    debugPrint('Attempting to connect to the server');
    if (_channel == null || _channel?.closeCode != null) {
      _channel = WebSocketChannel.connect(
          Uri.parse('ws://localhost:29873/websockets'));
      // When we are connected to the host, any message received will be deserialized from JSON and an event with the message type and data will be sent to the event bus.
      _channel?.stream.listen((json) {
        debugPrint('Received a message: $json');

        final Map<String, dynamic> message = jsonDecode(json);
        final EventData messageData = EventData.fromMap(message['data']);

        final EventTypes type =
            eventTypeConverter[message['type']] ?? EventTypes.unknown;

        eventStream.add(ClientEvent(type, messageData));
      });
    } else {
      debugPrint('Connection failed - client is null or already connected');
    }
  }

  void toggleAudioEngine() {
    debugPrint('Toggling Audio Engine...');
    _sendMessage(EventTypes.toggleAudioEngine);
  }

  void listAudioDevices() {
    debugPrint('Retrieving audio devices...');
    _sendMessage(EventTypes.listAudioDevices);
  }

  void listSampleRates() {
    debugPrint('Retrieving sample rates...');
    _sendMessage(EventTypes.listSampleRates);
  }

  void setASIODevice(String? audioDevice) {
    debugPrint('Settings audio device...');
    _sendMessage(EventTypes.setAudioDevice,
        data: EventData.setAudioDevice(audioDevice));
  }

  void setSampleRate(int sampleRate) {
    debugPrint('Settings sample rate...');
    _sendMessage(EventTypes.setSampleRate,
        data: EventData.setSampleRate(sampleRate));
  }

  void setGlobalVolume(double volume) {
    debugPrint('Setting global volume...');
    _sendMessage(EventTypes.setGlobalVolume,
        data: EventData.setGlobalVolume(volume));
  }

  void playTileById(String? id) {
    debugPrint('Playing tile by id: $id');
    _sendMessage(EventTypes.playTileById, data: EventData.tile(id));
  }

  void validateNewTile(String? name, String? path, double volume) {
    debugPrint('Validating new tile (name: $name, path: $path)');
    _sendMessage(EventTypes.validateNewTile,
        data: EventData.validateNewTile(path, name, volume));
  }

  void pickTilePath() {
    debugPrint('Launching File Picker Dialog');
    _sendMessage(EventTypes.pickTilePath);
  }

  void resampleFile(String file, int sampleRate) {
    debugPrint('Requesting file resample ($file)');
    _sendMessage(EventTypes.fileResampleNeeded,
        data: EventData.resampleFile(file, sampleRate));
  }

  void stopAllSound() {
    debugPrint('Stopping all sound...');
    _sendMessage(EventTypes.stopAllSounds);
  }

  void deleteTile(String? id) {
    debugPrint('Deleting tile: $id');
    _sendMessage(EventTypes.deleteTile, data: EventData.tile(id));
  }

  void saveSoundboard() {
    debugPrint('Saving soundboard...');
    _sendMessage(EventTypes.saveSoundboard);
  }

  void loadSoundboard() {
    debugPrint('Loading soundboard...');
    _sendMessage(EventTypes.loadSoundboard);
  }

  void saveTileSize(double tileSize) {
    debugPrint('Saving tile size...');
    _sendMessage(EventTypes.saveTileSize,
        data: EventData.setTileSize(tileSize));
  }

  void restoreTileSize() {
    debugPrint('Restoring tile size...');
    _sendMessage(EventTypes.restoreTileSize);
  }

  void saveGlobalVolume(double volume) {
    debugPrint('Saving global volume...');
    _sendMessage(EventTypes.saveGlobalVolume,
        data: EventData.setGlobalVolume(volume));
  }

  void restoreGlobalVolume() {
    debugPrint('Restoring global volume...');
    _sendMessage(EventTypes.restoreGlobalVolume);
  }

  void restoreAudioDevice() {
    debugPrint('Restoring audio device...');
    _sendMessage(EventTypes.restoreAudioDevice);
  }

  void restoreSampleRate() {
    debugPrint('Restoring sample rate...');
    _sendMessage(EventTypes.restoreSampleRate);
  }

  void _sendMessage(EventTypes event, {EventData? data}) {
    if (_channel?.closeCode == null) {
      final String eventType = eventTypeConverter.inverse[event] ??
          eventTypeConverter.inverse[EventTypes.unknown]!;
      final String? jsonData = data?.toJson();

      _channel?.sink.add(jsonEncode({'event': eventType, 'data': jsonData}));
      debugPrint('Sent a message: "$eventType", data: $jsonData');
    } else {
      debugPrint('Failed to send a message - client is null or not connected');
    }
  }
}
