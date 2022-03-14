import 'dart:async';

import '../../data/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/network/client_events.dart';
import '../../data/network/client_repository.dart';
import 'events.dart';
import 'state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ClientRepository _clientRepository;
  final SettingsRepository _settingsRepository;

  late final StreamSubscription<WebsocketMessage> _subscription;

  SettingsBloc(this._clientRepository, this._settingsRepository)
      : super(SettingsState(null, <int>[], null, <String>[],
            _settingsRepository.globalVolume)) {
    // Start listening to the host events. We mainly want to know when the lists requested above arrive and when an Audio Device or Sample Rate updates are processed by the server.
    _subscription = _clientRepository.eventStream.stream
        .listen((WebsocketMessage message) => add(WebsocketEvent(message)));

    on<PageLoaded>((event, emit) async {
      List<String>? audioDevices = await _clientRepository.listAudioDevices();
      List<int>? sampleRates = await _clientRepository.listSampleRates();

      emit(state.copyWith(
        asioDevices: () => audioDevices,
        sampleRates: () => sampleRates,
        asioDevice: () => _settingsRepository.audioDevice,
        sampleRate: () => _settingsRepository.sampleRate,
      ));
    });

    on<WebsocketEvent>((event, emit) {
      switch (event.message.type) {
        /**/
      }
    });
    on<ASIODeviceChanged>((event, emit) {
      debugPrint('Changing Audio Device to ${event.asioDevice}');
      _clientRepository.setAudioDevice(event.asioDevice);
    });
    on<SampleRateChanged>((event, emit) {
      debugPrint('Changing Audio Device to ${event.sampleRate}');
      _clientRepository.setSampleRate(event.sampleRate ?? 0);
    });
    on<VolumeChanged>((event, emit) {
      if (state.volume != event.volume) {
        debugPrint('Changing global volume to ${event.volume}');
        emit(state.copyWith(volume: () => event.volume));
        _clientRepository.setGlobalVolume(event.volume);
      }
    });
    on<VolumeChangedFinal>(
        (event, emit) => _settingsRepository.globalVolume = event.volume);
  }

  @override
  Future<void> close() {
    _subscription.cancel();

    return super.close();
  }
}
