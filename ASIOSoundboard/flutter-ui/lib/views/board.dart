import '../bloc/root/bloc.dart';
import '../bloc/root/states.dart';

import '../bloc/board/events.dart';
import '../data/soundboard/soundboard.dart';

import '../bloc/board/bloc.dart';
import '../bloc/board/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A body panel that displays a soundboard.
class BoardView extends StatelessWidget {
  // We don't want 'const' in the constructor because this prevents the panel from rebuilding when the root panel rebuilds. And I want this to rebuild because there is a button that needs to be disabled when a thing in the root state changes. Yes, there are other and probably better ways to achieve this, but I don't care.
  // ignore: prefer_const_constructors_in_immutables
  BoardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocConsumer<BoardBloc, BoardState>(
        listener: (context, state) {
          if (state.dialog == null) {
            Navigator.of(context).pop();
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider<BoardBloc>.value(
                value: BlocProvider.of<BoardBloc>(context),
                child: _newTileDialog(context),
              ),
            );
          }
        },
        listenWhen: (BoardState previous, BoardState current) =>
            (previous.dialog == null) ^ (current.dialog == null),
        builder: (context, state) => BlocListener<BoardBloc, BoardState>(
          listener: (context, state) {
            if (state.encodedAHKHandle != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Handle "${state.encodedAHKHandle}" copied to Clipboard'),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {/*Why is this a required argument?*/},
                  ),
                ),
              );
            }
          },
          child: Row(
            children: <Widget>[
              Expanded(
                child: _mainPanel(),
              ),
              SizedBox(
                width: 150,
                child: _sidePanel(context),
              )
            ],
          ),
        ),
      );

  /// Builds a dialog that lets the user customize the new tile they want to add. Will probably be extracted into a reusable widget later, since I plan on adding an ability to change a tile that is already on the board.
  Widget _newTileDialog(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    final TextEditingController pathController = TextEditingController();

    /// A panel in the middle of the dialog, has most of it's important stuff.
    Widget _form() {
      Widget _sectionHeader(String text) => Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              text,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          );

      return BlocListener<BoardBloc, BoardState>(
        listener: (context, state) {
          if (state.dialog?.needToValidate == true) {
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              _formKey.currentState?.validate();
            });
          }
          if (state.dialog?.tilePath != pathController.text) {
            pathController.text = state.dialog?.tilePath ?? '';
          }
        },
        child: BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) => Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionHeader('Tile Name'),
                TextFormField(
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    isDense: true,
                    hintText: 'Bruh',
                  ),
                  validator: (value) =>
                      state.dialog!.isNameValid ? null : 'Name can\'t be empty',
                  onChanged: (value) =>
                      context.read<BoardBloc>().add(NewTileNameChanged(value)),
                ),
                _sectionHeader('Tile Sound Path'),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'D:\\Sounds\\bruh.wav',
                        ),
                        controller: pathController,
                        validator: (value) =>
                            state.dialog!.isPathValid ? null : 'Invalid path',
                        onChanged: (value) => context
                            .read<BoardBloc>()
                            .add(NewTilePathChanged(value)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<BoardBloc>().add(PickTilePath()),
                      child: const Text('Browse'),
                    )
                  ],
                ),
                _sectionHeader('Tile Volume'),
                Slider(
                  min: 0,
                  divisions: 10,
                  max: 2,
                  label: (() =>
                      '${((state.dialog?.tileVolume ?? 1) * 100).toInt()}%')(),
                  value: state.dialog?.tileVolume ?? 1,
                  onChanged: (double value) => context
                      .read<BoardBloc>()
                      .add(NewTileVolumeChanged(value)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 3, top: 5, bottom: 15),
                child: Text(
                  'Add New Tile',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ),
            Expanded(
              child: _form(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        context.read<BoardBloc>().add(NewTileDialogClosed()),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<BoardBloc>().add(NewTileDialogSubmitted()),
                    child: const Text('Add'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _mainPanel() => Stack(
        children: <Widget>[
          _grid(),
          _fab(),
        ],
      );

  Widget _fab() => Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: BlocBuilder<BoardBloc, BoardState>(
            builder: (context, state) => FloatingActionButton(
              onPressed: () => context.read<BoardBloc>().add(AddNewTile()),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

  Widget _grid() => BlocBuilder<RootBloc, RootState>(
        builder: (rootContext, rootState) => BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) => LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              final double desiredWidth = 70 * rootState.tileSize;
              final int availableItemSpace =
                  constraints.maxWidth ~/ desiredWidth;
              final double finalWidth =
                  constraints.maxWidth / availableItemSpace;

              return GridView.extent(
                maxCrossAxisExtent: finalWidth,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                children: List.generate(
                  state.soundboard?.tiles.length ?? 0,
                  (index) => _tile(
                    context,
                    state.soundboard?.tiles[index] ??
                        const Tile('null', 'new_tile', 'null', 1),
                  ),
                ),
              );
            },
          ),
        ),
      );

  /// Builds a tile that can be placed inisde the grid.
  Widget _tile(BuildContext context, Tile tile) {
    /// A general button to be placed on the back side of the tile.
    Widget _backButton(
            {required String text,
            required VoidCallback onPressed,
            required IconData iconData}) =>
        Expanded(
          child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(iconData),
            label: Text(
              text,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
            style: TextButton.styleFrom(
                primary: Theme.of(context).colorScheme.onSecondary),
          ),
        );
    Widget _backDivider() => const Divider(height: 1);

    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) => GestureDetector(
        onSecondaryTap: () =>
            context.read<BoardBloc>().add(TileRightClick(tile.id)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: state.rightClickedTile != tile.id
              ? SizedBox.expand(
                  child: ElevatedButton(
                    onPressed: () =>
                        context.read<BoardBloc>().add(PlayTileById(tile.id)),
                    child: Text(tile.name ?? 'new_tile'),
                  ),
                )
              : Card(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _backButton(
                        text: 'Delete',
                        onPressed: () =>
                            context.read<BoardBloc>().add(DeleteTile(tile.id)),
                        iconData: Icons.close,
                      ),
                      _backDivider(),
                      _backButton(
                        text: 'Copy AHK Handle',
                        onPressed: () => context
                            .read<BoardBloc>()
                            .add(EncodeAHKHandle(tile.name)),
                        iconData: Icons.code,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// A panel that can be seen on the right of the board. Has buttons that control the state of the soundboard.
  Widget _sidePanel(BuildContext context) {
    Widget _sideButton(
            {required String text, required VoidCallback onPressed}) =>
        SizedBox(
          height: 35,
          child: ElevatedButton(
            onPressed: onPressed,
            child: Text(text),
          ),
        );

    Widget _separator() => const SizedBox(
          width: 0,
          height: 4,
        );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            offset: Offset(2, 0),
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sideButton(
            text: 'Save',
            onPressed: () => context.read<BoardBloc>().add(SaveSoundboard()),
          ),
          _separator(),
          _sideButton(
            text: 'Load',
            onPressed: () => context.read<BoardBloc>().add(LoadSoundboard()),
          ),
          const Divider(),
          _sideButton(
            text: 'Stop All Sounds',
            onPressed: () => context.read<BoardBloc>().add(StopAllSound()),
          )
        ],
      ),
    );
  }
}
