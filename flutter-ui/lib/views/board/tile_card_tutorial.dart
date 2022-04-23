import '../../bloc/board/tile_tutorial/bloc.dart';
import '../../bloc/board/tile_tutorial/events.dart';
import '../../util/extensions.dart';
import 'hero_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';

import '../../bloc/board/bloc.dart';
import '../../bloc/board/events.dart';
import '../../bloc/board/tile_tutorial/state.dart';
import '../../data/soundboard/soundboard.dart';

/// Appears when user creates a tile for the first time.
///
/// Shows how to use the tile (left/right-click)
class TileCardTutorial extends StatelessWidget {
  final Tile tile;
  final BoardBloc boardBloc;

  final TextStyle sideTextStyle = const TextStyle(fontSize: 26);

  const TileCardTutorial(
    this.tile,
    this.boardBloc, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider<TileTutorialBloc>(
            create: (context) => TileTutorialBloc()..add(TutorialOpened()),
          ),
          BlocProvider<BoardBloc>.value(value: boardBloc),
        ],
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.black.withOpacity(0.75),
            child: BlocBuilder<TileTutorialBloc, TileTutorialState>(
              buildWhen: (previous, current) => current.revealProgress >= 3,
              builder: (context, state) => Stack(
                children: <Widget>[
                  _tutorialContent(),
                  if (state.revealProgress >= 3) _mouseDetectorOverlay(context),
                ],
              ),
            ),
          ),
        ),
      );

  // Best way to organize code! Throw functions inside functions! Yay! Good look understanding what is happening down there!
  Widget _tutorialContent() {
    Widget _middleSection() {
      Widget _sideText(String text) => Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: FadeIn(
                curve: Curves.easeInCubic,
                duration: const Duration(seconds: 1),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: sideTextStyle,
                ),
              ),
            ),
          );

      Widget _sideTextPlaceholder() => const Expanded(child: SizedBox());

      Widget _tile() {
        Widget _faceContainer({
          required BuildContext context,
          required bool rightSide,
          required bool? currentSide,
          required Widget child,
        }) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              color: rightSide
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
              width: () {
                if (!rightSide) {
                  if (currentSide != null) {
                    return currentSide ? 75 : 225;
                  }
                  return 300;
                } else {
                  if (currentSide != null) {
                    return currentSide ? 225 : 75;
                  }
                  return 0;
                }
              }()
                  .toDouble(),
              child: child,
            );

        Widget _frontFace(BuildContext context, TileTutorialState state) =>
            _faceContainer(
              context: context,
              rightSide: false,
              currentSide: state.showRightClick,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    tile.name ?? '',
                    softWrap: true,
                    style: Theme.of(context).textTheme.tile,
                  ),
                ),
              ),
            );

        Widget _backFace(BuildContext context, TileTutorialState state) {
          Widget _backButton(IconData iconData, String text) => Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(iconData),
                        Text(
                          state.showRightClick! ? text : '',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );

          return _faceContainer(
            context: context,
            rightSide: true,
            currentSide: state.showRightClick,
            child: IconTheme(
              data: IconThemeData(
                  color: Theme.of(context).colorScheme.onSecondary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: state.showRightClick == null
                    ? <Widget>[]
                    : <Widget>[
                        _backButton(Icons.close, 'board.grid.tile.delete'.tr()),
                        Divider(
                          height: 1,
                          thickness: 0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondary
                              .withOpacity(0.25),
                        ),
                        _backButton(Icons.edit, 'board.grid.tile.edit'.tr()),
                      ],
              ),
            ),
          );
        }

        return BlocBuilder<TileTutorialBloc, TileTutorialState>(
          buildWhen: (previous, current) =>
              previous.showRightClick != current.showRightClick,
          builder: (context, state) => Hero(
            tag: tile,
            flightShuttleBuilder: (_, __, ___, ____, _____) =>
                HeroTile(name: tile.name),
            child: SizedBox(
              width: 300,
              height: 300,
              child: Card(
                margin: EdgeInsets.zero,
                color: Theme.of(context).colorScheme.primary,
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: <Widget>[
                    _frontFace(context, state),
                    _backFace(context, state),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return BlocBuilder<TileTutorialBloc, TileTutorialState>(
        buildWhen: (previous, current) =>
            current.revealProgress == 1 || current.revealProgress == 2,
        builder: (context, state) => Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (state.revealProgress >= 1)
                _sideText('board.tile_tutorial.left_click'.tr()),
              if (state.revealProgress < 1) _sideTextPlaceholder(),
              _tile(),
              if (state.revealProgress >= 2)
                _sideText('board.tile_tutorial.right_click'.tr()),
              if (state.revealProgress < 2) _sideTextPlaceholder(),
            ],
          ),
        ),
      );
    }

    Widget _gotItButton(BuildContext context) => Flexible(
          child: FadeIn(
            curve: Curves.easeInCubic,
            duration: const Duration(seconds: 1),
            child: OutlinedButton(
              child: Text(
                'board.tile_tutorial.got_it'.tr(),
                style: const TextStyle(fontSize: 22),
              ),
              style:
                  OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
              onPressed: () =>
                  context.read<BoardBloc>().add(CloseTileTutorial()),
            ),
          ),
        );

    return BlocBuilder<TileTutorialBloc, TileTutorialState>(
      buildWhen: (previous, current) => current.revealProgress >= 3,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _middleSection(),
          if (state.revealProgress >= 3) _gotItButton(context),
          if (state.revealProgress < 3) const Flexible(child: SizedBox())
        ],
      ),
    );
  }

  /// Draws two invisible containers above everything. Containers detect when mouse hovers over them and emit respective events.
  Widget _mouseDetectorOverlay(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: MouseRegion(
              opaque: false,
              onEnter: (details) => context
                  .read<TileTutorialBloc>()
                  .add(MouseSwitchedSide(false)),
            ),
          ),
          const SizedBox(width: 200),
          Expanded(
            child: MouseRegion(
              opaque: false,
              onEnter: (details) =>
                  context.read<TileTutorialBloc>().add(MouseSwitchedSide(true)),
            ),
          ),
        ],
      );
}
