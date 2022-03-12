import '../bloc/root/bloc.dart';
import '../bloc/root/events.dart';
import '../bloc/root/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings/bloc.dart';
import '../bloc/settings/events.dart';
import '../bloc/settings/state.dart';

/// A body panel that displays app settings.
class SettingsView extends StatelessWidget {
  // Ignore 'const' for the same reason we have done it in 'BoardView'.
  // ignore: prefer_const_constructors_in_immutables
  SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _scrollView(),
      );

  /// The root panel of the settings. Contains cards with different settings categories.
  Widget _scrollView() => SingleChildScrollView(
        child: Column(
          // This is why I love Dart. Just look at how beatiful and compact below code is. If you are not sure what it does, it creates a map (inline) where keys are the titles of each setting section and values are the widgets that represent the content of each card. Then it loops throught all the pairs and maps them to a list of Widgets that are created using the _settingsCard() function by passing the key and the value as the parameters.
          children: <String, Widget>{
            'Audio': _audioSettings(),
            'Board': _boardSettings(),
          }
              .entries
              .map<Widget>(
                (MapEntry<String, Widget> entry) => _settingsCard(
                  header: entry.key,
                  content: entry.value,
                ),
              )
              .toList(),
        ),
      );

  /// Builds a basic card for a settings category. Makes [header] the title of the card and puts [content] underneath.
  Widget _settingsCard({required String header, required Widget content}) =>
      Padding(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                    builder: (context) => Text(
                          header,
                          style: Theme.of(context).textTheme.headlineSmall,
                        )),
              ),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: content,
                ),
              )
            ],
          ),
        ),
      );

  /// Content of the Audio settings card.
  Widget _audioSettings() => BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => Column(
          children: <Widget>[
            const Text('ASIO Device'),
            DropdownButton<String>(
              value: state.asioDevice == '' ? null : state.asioDevice,
              items: state.asioDevices
                  ?.map<DropdownMenuItem<String>>(
                    (String? value) => DropdownMenuItem(
                      value: value,
                      child: Text(value ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                debugPrint('New Audio Device selected: $value');
                context.read<SettingsBloc>().add(ASIODeviceChanged(value));
              },
            ),
            const Text('Sample Rate'),
            DropdownButton<int?>(
              value: state.sampleRate,
              items: state.sampleRates
                  ?.map<DropdownMenuItem<int>>(
                    (int? value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (int? value) =>
                  context.read<SettingsBloc>().add(SampleRateChanged(value)),
            ),
            Column(
              children: <Widget>[
                const Text('Global Volume'),
                Slider(
                  min: 0,
                  divisions: 10,
                  max: 2,
                  label: (() => '${(state.volume * 100).toInt()}%')(),
                  value: state.volume,
                  onChangeEnd: (double value) => context
                      .read<SettingsBloc>()
                      .add(VolumeChangedFinal(value)),
                  onChanged: (double value) =>
                      context.read<SettingsBloc>().add(VolumeChanged(value)),
                )
              ],
            )
          ],
        ),
      );

  /// Content of the Board settings card.
  Widget _boardSettings() => BlocBuilder<RootBloc, RootState>(
        builder: (context, state) => Column(
          children: <Widget>[
            const Text('Tile Size'),
            Slider(
              min: 1,
              divisions: 10,
              max: 5,
              label: () {
                if (1 < state.tileSize && state.tileSize < 3) {
                  return 'Small';
                }
                if (3 < state.tileSize && state.tileSize < 5) {
                  return 'Big';
                }
                switch (state.tileSize.toInt()) {
                  case 1:
                    {
                      return 'Tiny';
                    }
                  case 3:
                    {
                      return 'Medium';
                    }
                  case 5:
                    {
                      return 'Huge';
                    }
                }
              }(),
              value: state.tileSize,
              onChangeEnd: (double value) =>
                  context.read<RootBloc>().add(TileSizeChangedFinal(value)),
              onChanged: (double value) =>
                  context.read<RootBloc>().add(TileSizeChanged(value)),
            )
          ],
        ),
      );
}
