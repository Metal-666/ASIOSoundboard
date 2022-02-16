import 'dart:async';

import 'package:asio_soundboard/data/network/client_events.dart'
    as client_events;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/network/client_repository.dart';
import 'events.dart';
import 'states.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ClientRepository _clientRepository;
  late final StreamSubscription<client_events.ClientEvent> _subscription;

  SettingsBloc(this._clientRepository)
      : super(SettingsState(null, <int>[], null, <String>[], 1)) {
    // When this bloc is created, retrieve a list of Audio Devices and available Sample Rates to display in the dropdown boxes.
    _clientRepository
      ..listAudioDevices()
      ..listSampleRates();

    _clientRepository.restoreGlobalVolume();

    // Start listening to the host events. We mainly want to know when the lists requested above arrive and when an Audio Device or Sample Rate updates are processed by the server.
    _subscription = _clientRepository.eventStream.stream
        .listen((client_events.ClientEvent event) => add(ClientEvent(event)));

    on<ClientEvent>((event, emit) {
      switch (event.event.type) {
        case client_events.EventTypes.listAudioDevices:
          {
            debugPrint(
                'Received Audio Devices: ${event.event.data?.audioDevices}');
            emit(state.populateASIODevices(event.event.data?.audioDevices));
            break;
          }
        case client_events.EventTypes.listSampleRates:
          {
            debugPrint(
                'Received Audio Devices: ${event.event.data?.sampleRates}');
            emit(state.populateSampleRates(event.event.data?.sampleRates));
            break;
          }
        case client_events.EventTypes.setAudioDevice:
          {
            debugPrint(
                'Received Audio Device: ${event.event.data?.audioDevice}');
            emit(state.changeASIODevice(event.event.data?.audioDevice));
            break;
          }
        case client_events.EventTypes.setSampleRate:
          {
            debugPrint('Received Sample Rate: ${event.event.data?.sampleRate}');
            emit(state.changeSampleRate(event.event.data?.sampleRate));
            break;
          }
        case client_events.EventTypes.restoreGlobalVolume:
          {
            emit(state.changeGlobalVolume(event.event.data?.volume ?? 1));
            break;
          }
        default:
      }
    });
    on<ASIODeviceChanged>((event, emit) {
      debugPrint('Changing Audio Device to ${event.asioDevice}');
      _clientRepository.setASIODevice(event.asioDevice);
    });
    on<SampleRateChanged>((event, emit) {
      debugPrint('Changing Audio Device to ${event.sampleRate}');
      _clientRepository.setSampleRate(event.sampleRate ?? 0);
    });
    on<VolumeChanged>((event, emit) {
      if (state.volume != event.volume) {
        debugPrint('Changing global volume to ${event.volume}');
        emit(state.changeGlobalVolume(event.volume));
        _clientRepository.setGlobalVolume(event.volume);
      }
    });
    on<VolumeChangedFinal>(
        (event, emit) => _clientRepository.saveGlobalVolume(event.volume));
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
