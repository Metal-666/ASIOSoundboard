import '../../data/soundboard/soundboard.dart';

class BoardState {
  final Soundboard? soundboard;
  final NewTileDialog? dialog;

  final String? rightClickedTile;

  final String? encodedAHKHandle;

  const BoardState(this.soundboard, this.dialog,
      {this.rightClickedTile, this.encodedAHKHandle});

  BoardState copyWith(
          {Soundboard? Function()? soundboard,
          NewTileDialog? Function()? dialog,
          String? Function()? rightClickedTile,
          String? Function()? encodedAHKHandle}) =>
      BoardState(soundboard == null ? this.soundboard : soundboard.call(),
          dialog == null ? this.dialog : dialog.call(),
          rightClickedTile: rightClickedTile == null
              ? this.rightClickedTile
              : rightClickedTile.call(),
          encodedAHKHandle: encodedAHKHandle == null
              ? this.encodedAHKHandle
              : encodedAHKHandle.call());
}

class NewTileDialog {
  final String? tileName;
  final String? tileNameError;
  final String? tilePath;
  final String? tilePathError;

  final bool shouldOverwritePath;

  final double tileVolume;

  const NewTileDialog(this.tileName, this.tilePath,
      {this.tileNameError,
      this.tilePathError,
      this.shouldOverwritePath = false,
      this.tileVolume = 1.0});

  NewTileDialog copyWith(
          {String? Function()? tileName,
          String? Function()? tileNameError,
          String? Function()? tilePath,
          String? Function()? tilePathError,
          bool Function()? shouldOverwritePath,
          double Function()? tileVolume}) =>
      NewTileDialog(tileName == null ? this.tileName : tileName.call(),
          tilePath == null ? this.tilePath : tilePath.call(),
          tileNameError:
              tileNameError == null ? this.tileNameError : tileNameError.call(),
          tilePathError:
              tilePathError == null ? this.tilePathError : tilePathError.call(),
          shouldOverwritePath:
              shouldOverwritePath == null ? false : shouldOverwritePath.call(),
          tileVolume: tileVolume == null ? this.tileVolume : tileVolume.call());
}
