import 'dart:async';

import 'bloc/settings/state.dart';
import 'data/network/websocket_events.dart';
import 'util/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

import 'bloc/board/bloc.dart';
import 'bloc/board/events.dart' as board_events;
import 'bloc/root/bloc.dart';
import 'bloc/root/events.dart';
import 'bloc/root/state.dart';
import 'bloc/settings/bloc.dart';
import 'bloc/settings/events.dart' as settings_events;
import 'data/network/client_repository.dart';
import 'data/settings/settings_repository.dart';
import 'views/board.dart';
import 'views/settings.dart';

// This accent color is used if accent mode is set to Original
final Color originalAccentColor = Colors.deepPurple[500]!;

// Keeps track of all loaded blocks
final Map<Bloc, bool> loadedBlocs = <Bloc, bool>{};

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setMinimumSize(const Size(400, 200));
    await windowManager.setSize(const Size(700, 400));
    await windowManager.center();
    await windowManager.show();
  });

  await SystemTheme.accentColor.load();

  final ClientRepository clientRepository = ClientRepository();
  final SettingsRepository settingsRepository = SettingsRepository();

  await settingsRepository.init();

  final RootBloc rootBloc = RootBloc(
    clientRepository,
    settingsRepository,
    preventAutostart: arguments.contains('-was-restarted'),
  );
  final BoardBloc boardBloc = BoardBloc(
    clientRepository,
    settingsRepository,
  );
  final SettingsBloc settingsBloc = SettingsBloc(
    clientRepository,
    settingsRepository,
  );

  loadedBlocs.addAll(<Bloc, bool>{
    rootBloc: false,
    boardBloc: false,
    settingsBloc: false,
  });

  // Start the websocket client and wait until server acknowledges conncetion
  StreamSubscription? subscription;
  subscription = clientRepository.eventStream.stream.listen((event) async {
    switch (event.type) {
      case WebsocketMessageType.connectionEstablished:
        {
          subscription!.cancel();

          final ThemeData theme = ThemeData.dark();

          // Select accent color based on current settings
          Color accentColor;

          switch (SettingsState
                  .accentModeConverter[settingsRepository.getAccentMode()] ??
              AccentMode.original) {
            original:
            case AccentMode.original:
              {
                accentColor = originalAccentColor;

                break;
              }
            case AccentMode.system:
              {
                accentColor = SystemTheme.accentColor.accent;

                break;
              }
            case AccentMode.custom:
              {
                String? color = settingsRepository.getCustomAccentColor();

                if (color != null) {
                  accentColor = HexColor.fromHex(color);

                  break;
                }

                continue original;
              }
          }

          // Actually start the app
          runApp(
            EasyLocalization(
              supportedLocales: const <Locale>[
                Locale('en'),
                Locale('uk'),
              ],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              useOnlyLangCode: true,
              useFallbackTranslations: true,
              child: Builder(
                builder: (context) => MaterialApp(
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
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  home: MultiRepositoryProvider(
                    providers: [
                      RepositoryProvider(
                        create: (_) => clientRepository,
                      ),
                      RepositoryProvider(
                        create: (_) => settingsRepository,
                      ),
                    ],
                    child: BlocProvider<RootBloc>.value(
                      value: rootBloc..add(AppLoaded()),
                      child: Root(boardBloc, settingsBloc),
                    ),
                  ),
                ),
              ),
            ),
          );

          break;
        }
      default:
    }
  });

  clientRepository.initWebsockets();
}

class Root extends HookWidget {
  final BoardBloc boardBloc;
  final SettingsBloc settingsBloc;

  const Root(
    this.boardBloc,
    this.settingsBloc, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: _body(usePageController()),
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
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(5),
          ),
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
                    text: 'root.engine_status.status'.tr(),
                    children: <InlineSpan>[
                      TextSpan(
                        text:
                            'root.engine_status.${state.isAudioEngineRunning ? 'running' : 'stopped'}'
                                .tr(),
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
                onPressed: () {
                  SettingsRepository settingsRepository =
                      context.read<SettingsRepository>();

                  return settingsRepository.getAudioDevice() == null ||
                      settingsRepository.getSampleRate() == null;
                }()
                    ? () => context
                        .read<RootBloc>()
                        .add(AudioEngineToggled()) //null
                    : () => context.read<RootBloc>().add(AudioEngineToggled()),
                child: Text(
                    'root.engine_status.${state.isAudioEngineRunning ? 'stop' : 'start'}'
                        .tr()),
              )
            ],
          ),
        ),
      );

  /// The main panel of the app. Displays a page depending on the current navigation state.
  Widget _body(PageController pageController) =>
      BlocListener<RootBloc, RootState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 7),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'errors.${state.error?.category}.error'.tr(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 20),
                  ),
                  Text(
                    state.error?.description == null
                        ? 'errors.${state.error?.category}.subjects.${state.error?.subject}.${state.error?.error}'
                            .tr(
                                namedArgs: <String, String?>{
                            'device': state.error?.device,
                            'sampleRate': state.error?.sampleRate?.toString(),
                            'path': state.error?.path,
                          }.map<String, String>(
                                    (key, value) => MapEntry(key, value ?? '')))
                        : 'root.error_dialog.internal_error'.tr(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 18),
                  ),
                ],
              ),
              action: () {
                if (state.error?.description != null) {
                  return SnackBarAction(
                    label: 'root.error_dialog.copy_stack_trace'.tr(),
                    onPressed: () =>
                        context.read<RootBloc>().add(CopyErrorStackTrace()),
                  );
                } else if (state.error?.path != null &&
                    state.error?.sampleRate != null) {
                  return SnackBarAction(
                    label: 'root.error_dialog.resample'.tr(),
                    onPressed: () =>
                        context.read<RootBloc>().add(FileResampleRequested()),
                  );
                }
              }(),
            ));
          }

          pageController.animateToPage(
            state.viewIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutQuint,
          );
        },
        child: PageView(
          controller: pageController,
          children: <Widget>[
            BlocProvider<BoardBloc>.value(
              value: boardBloc..add(board_events.PageLoaded()),
              child: BoardView(),
            ),
            BlocProvider<SettingsBloc>.value(
              value: settingsBloc..add(settings_events.PageLoaded()),
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
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.grid_on),
                label: 'root.nav.board'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: 'root.nav.settings'.tr(),
              ),
            ],
            onTap: (int index) =>
                context.read<RootBloc>().add(ViewChanged(index)),
            currentIndex: state.viewIndex,
          ),
        ),
      );
}
