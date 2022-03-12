import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/board/bloc.dart';
import 'bloc/root/bloc.dart';
import 'bloc/root/events.dart';
import 'bloc/root/state.dart';
import 'bloc/settings/bloc.dart';
import 'data/network/client_repository.dart';
import 'views/board.dart';
import 'views/settings.dart';

// All this fields should probably not be here, but I hava no idea what is the better place for them.
final ClientRepository _clientRepository = ClientRepository();

final RootBloc _rootBloc = RootBloc(_clientRepository);
final BoardBloc _boardBloc = BoardBloc(_clientRepository);
final SettingsBloc _settingsBloc = SettingsBloc(_clientRepository);
// To create our theme we first initalize a simple dark theme and then modify it's values in the MaterialApp constructor.
final ThemeData _theme = ThemeData.dark();

void main() => runApp(
      MaterialApp(
        title: 'ASIOSoundboard',
        theme: _theme.copyWith(
            colorScheme: _theme.colorScheme.copyWith(
                primary: Colors.deepPurple[500], secondary: Colors.white)),
        home: RepositoryProvider(
          create: (context) => _clientRepository,
          child: BlocProvider<RootBloc>.value(
            value: _rootBloc,
            child: const Root(),
          ),
        ),
      ),
    );

class Root extends StatelessWidget {
  const Root({Key? key}) : super(key: key);

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
            BoxShadow(offset: Offset(0, 2), blurRadius: 2, spreadRadius: -2)
          ],
        ),
        height: 40,
        child: BlocBuilder<RootBloc, RootState>(
          builder: (context, state) => Row(
            children: <Widget>[
              Expanded(
                  child: Text(
                      'Audio Engine Status: ${state.isAudioEngineRunning ? 'RUNNING' : 'STOPPED'}')),
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
  Widget _body() => BlocConsumer<RootBloc, RootState>(
        listener: (context, state) {
          if (state.error != null) {
            showModalBottomSheet(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: <Widget>[
                    Text(state.error!.error.toString()),
                    Text(state.error!.description.toString()),
                    if (state.error!.resampleFile != null &&
                        state.error!.sampleRate != null)
                      ElevatedButton(
                        onPressed: () {
                          context.read<RootBloc>().add(FileResampleRequested(
                              state.error!.resampleFile!,
                              state.error!.sampleRate!));
                          Navigator.of(context).pop();
                        },
                        child: const Text('Resample'),
                      )
                  ],
                ),
              ),
            ).whenComplete(
              () => context.read<RootBloc>().add(AudioEngineErrorDismissed()),
            );
          }
        },
        builder: (context, state) {
          switch (state.viewIndex) {
            case 0:
              {
                return BlocProvider<BoardBloc>.value(
                  value: _boardBloc,
                  child: BoardView(),
                );
              }
            case 1:
              {
                return BlocProvider<SettingsBloc>.value(
                  value: _settingsBloc,
                  child: SettingsView(),
                );
              }
            default:
              {
                return const Center();
              }
          }
        },
      );

  /// A bar at the bottom of the app window. Has buttons that switch the content of the [_body()] panel.
  Widget _bottomNavigationBar() => BlocBuilder<RootBloc, RootState>(
        builder: (context, state) => BottomNavigationBar(
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
      );
}
