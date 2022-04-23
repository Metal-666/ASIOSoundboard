import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../bloc/root/bloc.dart';
import '../bloc/root/events.dart';
import '../bloc/root/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings/bloc.dart';
import '../bloc/settings/events.dart';
import '../bloc/settings/state.dart';

final Random _random = Random();

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
                      'settings.ui.accent_color_picker.title'.tr(),
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
                    tonalSubheading:
                        Text('settings.ui.accent_color_picker.shade'.tr()),
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
                      child: Text(
                          'settings.ui.accent_color_picker.actions.cancel'
                              .tr()),
                      onPressed: () => context
                          .read<SettingsBloc>()
                          .add(CancelPickingCustomAccentColor()),
                    ),
                    ElevatedButton(
                      child: Text(
                          'settings.ui.accent_color_picker.actions.done'.tr()),
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
        child: Stack(
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: _scrollView(),
            ),
            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (previous, current) =>
                  current.attemptsToBecomeADeveloper != null &&
                  (previous.attemptsToBecomeADeveloper == null ||
                      previous.attemptsToBecomeADeveloper! <
                          current.attemptsToBecomeADeveloper!),
              builder: (context, state) =>
                  state.attemptsToBecomeADeveloper != null
                      ? Align(
                          alignment: Alignment(
                            _random.nextDouble() * 2 - 1,
                            _random.nextDouble() * 2 - 1,
                          ),
                          child: Transform.scale(
                            scale: 1.0 -
                                ((state.attemptsToBecomeADeveloper ?? 1) / 30),
                            child: _developerButton(context),
                          ),
                        )
                      : const SizedBox(),
            ),
          ],
        ),
      );

  /// The root panel of the settings. Contains cards with different settings categories.
  Widget _scrollView() {
    Widget _githubAction(
      bool show,
      Widget action,
    ) =>
        AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeInOutCubicEmphasized,
          child: action,
        );

    return SingleChildScrollView(
      primary: false,
      child: Column(
        children: <Widget>[
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) => MouseRegion(
              onEnter: (event) =>
                  context.read<SettingsBloc>().add(ShowGithubActions()),
              onExit: (event) =>
                  context.read<SettingsBloc>().add(HideGithubActions()),
              child: Padding(
                padding: const EdgeInsets.all(5).copyWith(top: 20),
                child: IntrinsicWidth(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _githubAction(
                          state.showGithubActions,
                          ElevatedButton.icon(
                            icon: const Icon(Icons.warning_amber),
                            label: Text('settings.github.issues'.tr()),
                            onPressed: () => context
                                .read<SettingsBloc>()
                                .add(OpenGithubIssues()),
                          ),
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: const Icon(FontAwesomeIcons.github),
                          iconSize: 50,
                          onPressed: () =>
                              context.read<SettingsBloc>().add(OpenGithub()),
                        ),
                      ),
                      Expanded(
                        child: _githubAction(
                          state.showGithubActions,
                          ElevatedButton.icon(
                            icon: const Icon(Icons.menu_book),
                            label: Text('settings.github.wiki'.tr()),
                            onPressed: () => context
                                .read<SettingsBloc>()
                                .add(OpenGithubWiki()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ...<String, Widget>{
            'settings.audio.header'.tr(): _audioSettings(),
            'settings.board.header'.tr(): _boardSettings(),
            'settings.ui.header'.tr(): _uiSettings(),
            'settings.developer.header'.tr(): _developerSettings(),
          }
              .entries
              .map<Widget>(
                (MapEntry<String, Widget> entry) => _settingsCard(
                  header: entry.key,
                  content: entry.value,
                ),
              )
              .toList()
        ],
      ),
    );
  }

  /// Builds a basic card for a settings category. Makes [header] the title of the card and puts [content] underneath.
  Widget _settingsCard({
    required String header,
    required Widget content,
  }) =>
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
                  ),
                ),
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

  Widget _audioSettings() => BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => _settingsSection(
          <MapEntry<String?, Widget?>>[
            MapEntry<String?, Widget?>(
              'settings.audio.asio_device'.tr(),
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
            ),
            MapEntry<String?, Widget?>(
              'settings.audio.sample_rate'.tr(),
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
            ),
            MapEntry<String?, Widget?>(
              'settings.audio.global_volume'.tr(),
              Column(children: <Widget>[
                Slider(
                  min: 0,
                  divisions: 10,
                  max: 2,
                  label: '${(state.volume * 100).toInt()}%',
                  value: state.volume,
                  onChangeEnd: (value) => context
                      .read<SettingsBloc>()
                      .add(VolumeChangedFinal(value)),
                  onChanged: (value) =>
                      context.read<SettingsBloc>().add(VolumeChanged(value)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text('0%'),
                      Text('100%'),
                      Text('200%'),
                    ],
                  ),
                ),
              ]),
            ),
            MapEntry<String?, Widget?>(
              null,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'settings.audio.autostart'.tr(),
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ),
                    Switch(
                      value: state.autoStartEngine,
                      onChanged: (value) => context
                          .read<SettingsBloc>()
                          .add(AutoStartEngineChanged(value)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _boardSettings() => BlocBuilder<RootBloc, RootState>(
        builder: (context, state) => _settingsSection(
          <MapEntry<String?, Widget?>>[
            MapEntry(
              'settings.board.tile_size'.tr(),
              Column(
                children: <Widget>[
                  Slider(
                    min: 1,
                    divisions: 10,
                    max: 5,
                    label: 'settings.board.tile_sizes.${() {
                      if (1 < state.tileSize && state.tileSize < 3) {
                        return 'small';
                      }
                      if (3 < state.tileSize && state.tileSize < 5) {
                        return 'big';
                      }
                      switch (state.tileSize.toInt()) {
                        case 1:
                          {
                            return 'tiny';
                          }
                        case 3:
                          {
                            return 'medium';
                          }
                        case 5:
                          {
                            return 'huge';
                          }
                      }
                    }()}'
                        .tr(),
                    value: state.tileSize,
                    onChangeEnd: (value) => context
                        .read<RootBloc>()
                        .add(TileSizeChangedFinal(value)),
                    onChanged: (value) =>
                        context.read<RootBloc>().add(TileSizeChanged(value)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('settings.board.tile_sizes.tiny'.tr()),
                        Text('settings.board.tile_sizes.medium'.tr()),
                        Text('settings.board.tile_sizes.huge'.tr()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _uiSettings() => BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => _settingsSection(
          <MapEntry<String?, Widget?>>[
            MapEntry<String?, Widget?>(
              'settings.ui.accent_color'.tr(),
              Column(
                children: AccentMode.values
                    .map<RadioListTile<AccentMode>>(
                      (mode) => RadioListTile<AccentMode>(
                        title:
                            Text('settings.ui.accent_colors.${mode.name}'.tr()),
                        value: mode,
                        groupValue: state.accentMode,
                        onChanged: (value) => context
                            .read<SettingsBloc>()
                            .add(AccentModeChanged(value)),
                        secondary: mode == AccentMode.custom
                            ? IconButton(
                                icon: const Icon(Icons.color_lens),
                                onPressed: () => context
                                    .read<SettingsBloc>()
                                    .add(PickCustomAccentColor()),
                              )
                            : null,
                      ),
                    )
                    .toList(),
              ),
            ),
            MapEntry<String?, Widget?>(
              'settings.ui.language'.tr(),
              DropdownButton<String>(
                value: context.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    context.setLocale(Locale(value));
                  }
                },
                items: context.supportedLocales
                    .map<DropdownMenuItem<String>>(
                      (locale) => DropdownMenuItem(
                        value: locale.languageCode,
                        child: Text(
                            'settings.ui.languages.${locale.languageCode}'
                                .tr()),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );

  Widget _developerSettings() => BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) => Column(
            children: <Widget>[
              if (state.attemptsToBecomeADeveloper == null)
                _developerButton(context),
            ],
          ));

  Widget _settingsSection(List<MapEntry<String?, Widget?>> elements) => Column(
        children: elements
            .map<Column>(
              (e) => Column(
                children: <Widget>[
                  if (e.key != null)
                    Builder(
                        builder: (context) => Text(
                              e.key!,
                              style: Theme.of(context).textTheme.subtitle1,
                            )),
                  if (e.value != null) e.value!,
                  const SizedBox(height: 20),
                ],
              ),
            )
            .toList()
          ..last.children.removeLast(),
      );

  Widget _developerButton(BuildContext context) => _fakeButton(
        icon: const Icon(Icons.code),
        label: Text('settings.developer.become_developer'.tr()),
        onPressed: () => context.read<SettingsBloc>().add(BecomeDeveloper()),
      );

  Widget _fakeButton({
    required Icon icon,
    required Widget label,
    required void Function() onPressed,
  }) =>
      Builder(
        builder: (context) => GestureDetector(
          onTapDown: (details) => onPressed(),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: icon,
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      );
}
