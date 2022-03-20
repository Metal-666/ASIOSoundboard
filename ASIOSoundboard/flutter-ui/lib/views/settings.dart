import 'package:flex_color_picker/flex_color_picker.dart';

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
  Widget build(BuildContext context) =>
      BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.pickingAccentColor != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider<SettingsBloc>.value(
                value: context.read<SettingsBloc>(),
                child: AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  scrollable: true,
                  content: ColorPicker(
                    title: Text(
                      'Pick custom accent color',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                      copyFormat: ColorPickerCopyFormat.hexRRGGBB,
                    ),
                    heading: const SizedBox(height: 20),
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.primary: false,
                      ColorPickerType.accent: false,
                      ColorPickerType.wheel: true,
                    },
                    wheelDiameter: 300,
                    wheelHasBorder: true,
                    enableShadesSelection: false,
                    tonalSubheading: const Text('Select color shade'),
                    enableTonalPalette: true,
                    showColorName: true,
                    showColorCode: true,
                    colorCodeHasColor: true,
                    color: state.pickingAccentColor ?? Colors.black,
                    onColorChanged: (value) => context
                        .read<SettingsBloc>()
                        .add(UpdateCustomAccentColor(value)),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => context
                          .read<SettingsBloc>()
                          .add(CancelPickingCustomAccentColor()),
                    ),
                    ElevatedButton(
                      child: const Text('Done'),
                      onPressed: () => context
                          .read<SettingsBloc>()
                          .add(FinishedPickingCustomAccentColor()),
                    ),
                  ],
                ),
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
        listenWhen: (oldState, newState) =>
            (oldState.pickingAccentColor == null) ^
            (newState.pickingAccentColor == null),
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _scrollView(),
        ),
      );

  /// The root panel of the settings. Contains cards with different settings categories.
  Widget _scrollView() => SingleChildScrollView(
        child: Column(
          // This is why I love Dart. Just look at how beatiful and compact below code is. If you are not sure what it does, it creates a map (inline) where keys are the titles of each setting section and values are the widgets that represent the content of each card. Then it loops throught all the pairs and maps them to a list of Widgets that are created using the _settingsCard() function by passing the key and the value as the parameters.
          children: <String, Widget>{
            'Audio': _audioSettings(),
            'Board': _boardSettings(),
            'UI': _uiSettings(),
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
              onChanged: (value) =>
                  context.read<SettingsBloc>().add(ASIODeviceChanged(value)),
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
              onChanged: (value) =>
                  context.read<SettingsBloc>().add(SampleRateChanged(value)),
            ),
            const Text('Global Volume'),
            Slider(
              min: 0,
              divisions: 10,
              max: 2,
              label: (() => '${(state.volume * 100).toInt()}%')(),
              value: state.volume,
              onChangeEnd: (value) =>
                  context.read<SettingsBloc>().add(VolumeChangedFinal(value)),
              onChanged: (value) =>
                  context.read<SettingsBloc>().add(VolumeChanged(value)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Start Engine when app launches?'),
                  Switch(
                      value: state.autoStartEngine,
                      onChanged: (value) => context
                          .read<SettingsBloc>()
                          .add(AutoStartEngineChanged(value))),
                ],
              ),
            ),
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
              onChangeEnd: (value) =>
                  context.read<RootBloc>().add(TileSizeChangedFinal(value)),
              onChanged: (value) =>
                  context.read<RootBloc>().add(TileSizeChanged(value)),
            )
          ],
        ),
      );
  Widget _uiSettings() => BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => Column(
            children: <Widget>[
              const Text('Accent Color'),
              RadioListTile<AccentMode>(
                title: const Text('Original'),
                value: AccentMode.original,
                groupValue: state.accentMode,
                onChanged: (value) =>
                    context.read<SettingsBloc>().add(AccentModeChanged(value)),
              ),
              RadioListTile<AccentMode>(
                title: const Text('System'),
                value: AccentMode.system,
                groupValue: state.accentMode,
                onChanged: (value) =>
                    context.read<SettingsBloc>().add(AccentModeChanged(value)),
              ),
              RadioListTile<AccentMode>(
                title: const Text('Custom'),
                value: AccentMode.custom,
                groupValue: state.accentMode,
                onChanged: (value) =>
                    context.read<SettingsBloc>().add(AccentModeChanged(value)),
                secondary: IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: () =>
                      context.read<SettingsBloc>().add(PickCustomAccentColor()),
                ),
              ),
            ],
          ));
}
