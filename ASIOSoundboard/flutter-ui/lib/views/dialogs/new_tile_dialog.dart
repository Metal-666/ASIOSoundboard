import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/board/bloc.dart';
import '../../bloc/board/events.dart';
import '../../bloc/board/state.dart';

/// Dialog that appears when user wants to add a new tile.
class NewTileDialog extends StatefulWidget {
  const NewTileDialog({Key? key}) : super(key: key);

  @override
  State<NewTileDialog> createState() => _NewTileDialogState();
}

// I'm not a fan of using stateful widgets in a bloc app, but there is no other way - TextEditingController needs to be disposed
class _NewTileDialogState extends State<NewTileDialog> {
  final TextEditingController pathController = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(
          'Add New Tile',
          style: Theme.of(context).textTheme.headline6,
        ),
        content: _form(),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () =>
                context.read<BoardBloc>().add(NewTileDialogClosed()),
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () =>
                context.read<BoardBloc>().add(NewTileDialogSubmitted()),
          )
        ],
      );

  /// A panel in the middle of the dialog, has most of it's important stuff.
  Widget _form() {
    Widget _sectionHeader(String text) => Padding(
          padding: const EdgeInsets.all(3),
          child: Text(
            text,
            style: Theme.of(context).textTheme.subtitle1,
          ),
        );

    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        if (state.dialog?.shouldOverwritePath ?? false) {
          _overwriteControllerText(
              pathController, state.dialog!.tilePath ?? '');
        }

        return Column(
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
              autovalidateMode: AutovalidateMode.always,
              validator: (_) => state.dialog?.tileNameError,
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
                    autovalidateMode: AutovalidateMode.always,
                    controller: pathController,
                    validator: (_) => state.dialog?.tilePathError,
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
              onChanged: (double value) =>
                  context.read<BoardBloc>().add(NewTileVolumeChanged(value)),
            )
          ],
        );
      },
    );
  }

  void _overwriteControllerText(TextEditingController controller,
      [String? newText]) {
    controller
      ..text = newText ?? ''
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
  }

  @override
  void dispose() {
    pathController.dispose();

    super.dispose();
  }
}
