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
  final bool isNameValid;
  final String? tilePath;
  final bool isPathValid;

  final bool needToValidate;

  final double tileVolume;

  const NewTileDialog(this.tileName, this.tilePath,
      {this.isNameValid = false,
      this.isPathValid = false,
      this.needToValidate = false,
      this.tileVolume = 1.0});

  NewTileDialog copyWith(
          {String? Function()? tileName,
          bool Function()? isNameValid,
          String? Function()? tilePath,
          bool Function()? isPathValid,
          bool Function()? needToValidate,
          double Function()? tileVolume}) =>
      NewTileDialog(tileName == null ? this.tileName : tileName.call(),
          tilePath == null ? this.tilePath : tilePath.call(),
          isNameValid:
              isNameValid == null ? this.isNameValid : isNameValid.call(),
          isPathValid:
              isPathValid == null ? this.isPathValid : isPathValid.call(),
          needToValidate: needToValidate == null
              ? this.needToValidate
              : needToValidate.call(),
          tileVolume: tileVolume == null ? this.tileVolume : tileVolume.call());
}
