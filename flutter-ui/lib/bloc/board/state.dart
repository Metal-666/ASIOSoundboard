import '../../data/soundboard/soundboard.dart';

class BoardState {
  final Soundboard? soundboard;
  final TileDialog? dialog;

  final Tile? rightClickedTile;

  final Tile? tutorialTile;

  const BoardState(
    this.soundboard,
    this.dialog, {
    this.rightClickedTile,
    this.tutorialTile,
  });

  BoardState copyWith({
    Soundboard? Function()? soundboard,
    TileDialog? Function()? dialog,
    Tile? Function()? rightClickedTile,
    Tile? Function()? tutorialTile,
  }) =>
      BoardState(
        soundboard == null ? this.soundboard : soundboard.call(),
        dialog == null ? this.dialog : dialog.call(),
        rightClickedTile: rightClickedTile == null
            ? this.rightClickedTile
            : rightClickedTile.call(),
        tutorialTile:
            tutorialTile == null ? this.tutorialTile : tutorialTile.call(),
      );
}

class TileDialog {
  final String? tileName;
  final String? tileNameError;
  final String? tilePath;
  final String? tilePathError;

  final double tileVolume;

  final bool shouldOverwriteName;
  final bool shouldOverwritePath;

  final Tile? editedTile;

  const TileDialog(
    this.tileName,
    this.tilePath, {
    this.tileNameError,
    this.tilePathError,
    this.tileVolume = 1.0,
    this.shouldOverwriteName = false,
    this.shouldOverwritePath = false,
    this.editedTile,
  });

  TileDialog copyWith({
    String? Function()? tileName,
    String? Function()? tileNameError,
    String? Function()? tilePath,
    String? Function()? tilePathError,
    double Function()? tileVolume,
    bool Function()? shouldOverwriteName,
    bool Function()? shouldOverwritePath,
    Tile Function()? editedTile,
  }) =>
      TileDialog(
        tileName == null ? this.tileName : tileName.call(),
        tilePath == null ? this.tilePath : tilePath.call(),
        tileNameError:
            tileNameError == null ? this.tileNameError : tileNameError.call(),
        tilePathError:
            tilePathError == null ? this.tilePathError : tilePathError.call(),
        tileVolume: tileVolume == null ? this.tileVolume : tileVolume.call(),
        shouldOverwriteName:
            shouldOverwriteName == null ? false : shouldOverwriteName.call(),
        shouldOverwritePath:
            shouldOverwritePath == null ? false : shouldOverwritePath.call(),
        editedTile: editedTile == null ? this.editedTile : editedTile.call(),
      );
}
