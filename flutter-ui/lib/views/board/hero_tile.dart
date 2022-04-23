import '../../util/extensions.dart';
import 'package:flutter/material.dart';

/// What does this do, again? Probably draws a pseudo-tile when the hero animation is playing
class HeroTile extends StatelessWidget {
  final String? name;

  const HeroTile({
    required this.name,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Text(
            name ?? '',
            style: Theme.of(context).textTheme.tile,
          ),
        ),
      );
}
