import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../bloc/board/bloc.dart';
import '../../bloc/board/events.dart';
import '../../bloc/board/state.dart';

/// Dialog that appears when user wants to add a new tile/edit a tile.
class TileDialog extends HookWidget {
  const TileDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) => Text(
              'board.tile_dialog.title.${state.dialog?.editedTile == null ? 'new_tile' : 'edit_tile'}'
                  .tr()),
        ),
        content: _form(
          context,
          useTextEditingController(),
          useTextEditingController(),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('board.tile_dialog.actions.cancel'.tr()),
            onPressed: () => context.read<BoardBloc>().add(TileDialogClosed()),
          ),
          ElevatedButton(
            child: Text('board.tile_dialog.actions.done'.tr()),
            onPressed: () =>
                context.read<BoardBloc>().add(TileDialogSubmitted()),
          ),
        ],
      );

  /// A panel in the middle of the dialog, has most of it's important stuff.
  Widget _form(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController pathController,
  ) {
    Widget _sectionHeader(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            text,
            style: Theme.of(context).textTheme.subtitle1,
          ),
        );

    Widget _spacer() => const SizedBox(height: 20);

    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        if (state.dialog?.shouldOverwriteName ?? false) {
          _overwriteControllerText(
            nameController,
            state.dialog!.tileName ?? '',
          );
        }
        if (state.dialog?.shouldOverwritePath ?? false) {
          _overwriteControllerText(
            pathController,
            state.dialog!.tilePath ?? '',
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('board.tile_dialog.name.header'.tr()),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 10,
                  ),
                  isDense: true,
                  hintText: 'board.tile_dialog.name.placeholder'.tr(),
                ),
                autovalidateMode: AutovalidateMode.always,
                controller: nameController,
                validator: (_) => state.dialog?.tileNameError?.tr(),
                onChanged: (value) =>
                    context.read<BoardBloc>().add(TileDialogNameChanged(value)),
              ),
              _spacer(),
              _sectionHeader('board.tile_dialog.path.header'.tr()),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'board.tile_dialog.path.placeholder'.tr(),
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      controller: pathController,
                      validator: (_) => state.dialog?.tilePathError?.tr(),
                      onChanged: (value) => context
                          .read<BoardBloc>()
                          .add(TileDialogPathChanged(value)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<BoardBloc>().add(PickTilePath()),
                    child: Text('board.tile_dialog.path.browse'.tr()),
                  ),
                ],
              ),
              _spacer(),
              _sectionHeader('board.tile_dialog.volume.header'.tr()),
              Slider(
                min: 0,
                divisions: 10,
                max: 2,
                label: (() =>
                    '${((state.dialog?.tileVolume ?? 1) * 100).toInt()}%')(),
                value: state.dialog?.tileVolume ?? 1,
                onChanged: (double value) => context
                    .read<BoardBloc>()
                    .add(TileDialogVolumeChanged(value)),
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
            ],
          ),
        );
      },
    );
  }

  void _overwriteControllerText(
    TextEditingController controller, [
    String? newText,
  ]) {
    controller
      ..text = newText ?? ''
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
  }
}
