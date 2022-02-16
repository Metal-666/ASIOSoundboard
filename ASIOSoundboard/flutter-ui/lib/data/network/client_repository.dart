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

        Map<String, dynamic> message = jsonDecode(json);
        EventData messageData = EventData.fromMap(message['data']);

        EventTypes type = EventTypes.unknown;

        //Looks ugly but I'm yet to find a better way to handle this.
        switch (message['type']) {
          case 'get_soundboard':
            {
              type = EventTypes.getSoundboard;
              break;
            }
          case 'started_audio_engine':
            {
              type = EventTypes.startedAudioEngine;
              break;
            }
          case 'stopped_audio_engine':
            {
              type = EventTypes.stoppedAudioEngine;
              break;
            }
          case 'audio_engine_error':
            {
              type = EventTypes.audioEngineError;
              break;
            }
          case 'invalid_sample_rate_error':
            {
              type = EventTypes.invalidSampleRateError;
              break;
            }
          case 'list_audio_devices':
            {
              type = EventTypes.listAudioDevices;
              break;
            }
          case 'list_sample_rates':
            {
              type = EventTypes.listSampleRates;
              break;
            }
          case 'set_audio_device':
            {
              type = EventTypes.setAudioDevice;
              break;
            }
          case 'set_sample_rate':
            {
              type = EventTypes.setSampleRate;
              break;
            }
          case 'validate_new_tile':
            {
              type = EventTypes.validateNewTile;
              break;
            }
          case 'pick_tile_path':
            {
              type = EventTypes.pickTilePath;
              break;
            }
          case 'file_resample_needed':
            {
              type = EventTypes.fileResampleNeeded;
              break;
            }
          case 'watch_keys':
            {
              type = EventTypes.fileResampleNeeded;
              break;
            }
          case 'delete_tile':
            {
              type = EventTypes.deleteTile;
              break;
            }
          case 'restore_tile_size':
            {
              type = EventTypes.restoreTileSize;
              break;
            }
          case 'restore_global_volume':
            {
              type = EventTypes.restoreGlobalVolume;
              break;
            }
          case 'restore_audio_device':
            {
              type = EventTypes.restoreAudioDevice;
              break;
            }
          case 'restore_sample_rate':
            {
              type = EventTypes.restoreSampleRate;
              break;
            }
        }

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
      String eventType = 'unknown';
      String? jsonData = data?.toJson();

      switch (event) {
        case EventTypes.listAudioDevices:
          {
            eventType = 'list_audio_devices';
            break;
          }
        case EventTypes.listSampleRates:
          {
            eventType = 'list_sample_rates';
            break;
          }
        case EventTypes.setAudioDevice:
          {
            eventType = 'set_audio_device';
            break;
          }
        case EventTypes.setSampleRate:
          {
            eventType = 'set_sample_rate';
            break;
          }
        case EventTypes.setGlobalVolume:
          {
            eventType = 'set_global_volume';
            break;
          }
        case EventTypes.toggleAudioEngine:
          {
            eventType = 'toggle_audio_engine';
            break;
          }
        case EventTypes.playTileById:
          {
            eventType = 'play_tile_by_id';
            break;
          }
        case EventTypes.validateNewTile:
          {
            eventType = 'validate_new_tile';
            break;
          }
        case EventTypes.pickTilePath:
          {
            eventType = 'pick_tile_path';
            break;
          }
        case EventTypes.fileResampleNeeded:
          {
            eventType = 'file_resample_needed';
            break;
          }
        case EventTypes.stopAllSounds:
          {
            eventType = 'stop_all_sounds';
            break;
          }
        case EventTypes.deleteTile:
          {
            eventType = 'delete_tile';
            break;
          }
        case EventTypes.saveSoundboard:
          {
            eventType = 'save_soundboard';
            break;
          }
        case EventTypes.loadSoundboard:
          {
            eventType = 'load_soundboard';
            break;
          }
        case EventTypes.saveTileSize:
          {
            eventType = 'save_tile_size';
            break;
          }
        case EventTypes.restoreTileSize:
          {
            eventType = 'restore_tile_size';
            break;
          }
        case EventTypes.saveGlobalVolume:
          {
            eventType = 'save_global_volume';
            break;
          }
        case EventTypes.restoreGlobalVolume:
          {
            eventType = 'restore_global_volume';
            break;
          }
        case EventTypes.restoreAudioDevice:
          {
            eventType = 'restore_audio_device';
            break;
          }
        case EventTypes.restoreSampleRate:
          {
            eventType = 'restore_sample_rate';
            break;
          }
        default:
      }

      _channel?.sink.add(jsonEncode({'event': eventType, 'data': jsonData}));
      debugPrint('Sent a message: "$eventType", data: $jsonData');
    } else {
      debugPrint('Failed to send a message - client is null or not connected');
    }
  }
}
