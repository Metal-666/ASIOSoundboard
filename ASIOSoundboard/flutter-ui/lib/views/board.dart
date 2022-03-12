import '../bloc/root/bloc.dart';
import '../bloc/root/state.dart';

import '../bloc/board/events.dart';
import '../data/soundboard/soundboard.dart';

import '../bloc/board/bloc.dart';
import '../bloc/board/state.dart' hide NewTileDialog;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dialogs/new_tile_dialog.dart';

/// A body panel that displays a soundboard.
class BoardView extends StatelessWidget {
  // We don't want 'const' in the constructor because this prevents the panel from rebuilding when the root panel rebuilds. And I want this to rebuild because there is a button that needs to be disabled when a thing in the root state changes. Yes, there are other and probably better ways to achieve this, but I don't care.
  // ignore: prefer_const_constructors_in_immutables
  BoardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocConsumer<BoardBloc, BoardState>(
        listener: (context, state) {
          if (state.dialog != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider<BoardBloc>.value(
                value: context.read<BoardBloc>(),
                child: const NewTileDialog(),
              ),
            );
          } else {
            Navigator.of(context).pop();
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
