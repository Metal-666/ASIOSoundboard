import 'package:asio_soundboard/bloc/settings/state.dart';
import 'package:asio_soundboard/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:system_theme/system_theme.dart';

import 'bloc/board/bloc.dart';
import 'bloc/board/events.dart' as bloc_events;
import 'bloc/root/bloc.dart';
import 'bloc/root/events.dart';
import 'bloc/root/state.dart';
import 'bloc/settings/bloc.dart';
import 'bloc/settings/events.dart' as settings_events;
import 'data/network/client_repository.dart';
import 'data/settings/settings_repository.dart';
import 'views/board.dart';
import 'views/settings.dart';

// All this fields should probably not be here, but I have no idea where else to put them.
final ClientRepository _clientRepository = ClientRepository();
final SettingsRepository _settingsRepository = SettingsRepository();

final RootBloc _rootBloc = RootBloc(_clientRepository, _settingsRepository);
final BoardBloc _boardBloc = BoardBloc(_clientRepository);
final SettingsBloc _settingsBloc =
    SettingsBloc(_clientRepository, _settingsRepository);

final Color originalAccentColor = Colors.deepPurple[500]!;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemTheme.accentInstance.load();

  await _settingsRepository.init();
  _clientRepository.init();

  final ThemeData theme = ThemeData.dark();

  Color? accentColor;

  switch (SettingsState.accentModeConverter[_settingsRepository.accentMode] ??
      AccentMode.original) {
    original:
    case AccentMode.original:
      {
        accentColor = originalAccentColor;

        break;
      }
    case AccentMode.system:
      {
        accentColor = SystemTheme.accentInstance.accent;

        break;
      }
    case AccentMode.custom:
      {
        String? color = _settingsRepository.customAccentColor;

        if (color != null) {
          accentColor = HexColor.fromHex(color);

          break;
        }

        continue original;
      }
  }

  await _clientRepository.setGlobalVolume(_settingsRepository.globalVolume);

  if (_settingsRepository.autoStartEngine) {
    await _clientRepository.startAudioEngine(
      _settingsRepository.audioDevice,
      _settingsRepository.sampleRate,
      _settingsRepository.globalVolume,
    );
  }

  runApp(
    MaterialApp(
      title: 'ASIOSoundboard',
      theme: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: accentColor,
          secondary: Colors.white,
          onPrimary: accentColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
          onSecondary: Colors.black,
        ),
        toggleableActiveColor: accentColor,
      ),
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (_) => _clientRepository,
          ),
          RepositoryProvider(
            create: (_) => _settingsRepository,
          ),
        ],
        child: BlocProvider<RootBloc>.value(
          value: _rootBloc..add(AppLoaded()),
          child: Root(),
        ),
      ),
    ),
  );
}

class Root extends StatelessWidget {
  final PageController pageController = PageController();

  Root({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: _body(),
            ),
            _topInfoBar(context),
          ],
        ),
        bottomNavigationBar: _bottomNavigationBar(),
      );

  /// Generates a panel that can be seen at the top of the app window. Has a button that toggles the Audio Engine and a text showing Audio Engine's current state.
  Widget _topInfoBar(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 2,
              spreadRadius: -2,
            )
          ],
        ),
        height: 40,
        child: BlocBuilder<RootBloc, RootState>(
          builder: (context, state) => Row(
            children: <Widget>[
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Audio Engine Status: ',
                    children: <InlineSpan>[
                      TextSpan(
                        text:
                            state.isAudioEngineRunning ? 'RUNNING' : 'STOPPED',
                        style: TextStyle(
                          color: state.isAudioEngineRunning
                              ? Colors.green
                              : Colors.red,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    context.read<RootBloc>().add(AudioEngineToggled()),
                child: Text(state.isAudioEngineRunning ? 'STOP' : 'START'),
              )
            ],
          ),
        ),
      );

  /// The main panel of the app. Displays a page depending on the current navigation state.
  Widget _body() => BlocListener<RootBloc, RootState>(
        listener: (context, state) {
          if (state.errorDialog != null) {
            showModalBottomSheet(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: <Widget?>[
                    Text(
                      state.errorDialog!.error.toString(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      state.errorDialog!.description.toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    () {
                      if (state.errorDialog is ResampleNeededDialog) {
                        ResampleNeededDialog dialog =
                            state.errorDialog as ResampleNeededDialog;

                        return ElevatedButton(
                          onPressed: () {
                            context.read<RootBloc>().add(FileResampleRequested(
                                dialog.file, dialog.sampleRate));
                            Navigator.of(context).pop();
                          },
                          child: const Text('Resample'),
                        );
                      }
                    }()
                  ].where((element) => element != null).toList().cast<Widget>(),
                ),
              ),
            ).whenComplete(
                () => context.read<RootBloc>().add(ErrorDialogDismissed()));
          }

          pageController.animateToPage(state.viewIndex,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuint);
        },
        child: PageView(
          controller: pageController,
          children: <Widget>[
            BlocProvider<BoardBloc>.value(
              value: _boardBloc..add(bloc_events.PageLoaded()),
              child: BoardView(),
            ),
            BlocProvider<SettingsBloc>.value(
              value: _settingsBloc..add(settings_events.PageLoaded()),
              child: SettingsView(),
            ),
          ],
        ),
      );

  /// A bar at the bottom of the app window. Has buttons that switch the content of the [_body()] panel.
  Widget _bottomNavigationBar() => BlocBuilder<RootBloc, RootState>(
        builder: (context, state) => Container(
          decoration: const BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                offset: Offset(0, -1),
                blurRadius: 10,
                spreadRadius: -4,
              )
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Theme.of(context).cardColor,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_on),
                label: 'Board',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            onTap: (int index) =>
                context.read<RootBloc>().add(ViewChanged(index)),
            currentIndex: state.viewIndex,
          ),
        ),
      );
}
