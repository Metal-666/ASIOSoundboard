import '../../data/soundboard/soundboard.dart';

class BoardState {
  final Soundboard? soundboard;
  final NewTileDialog? dialog;

  final String? rightClickedTile;

  final String? encodedAHKHandle;

  BoardState(this.soundboard, this.dialog,
      {this.rightClickedTile, this.encodedAHKHandle});

  BoardState setSoundboard(Soundboard? soundboard) =>
      BoardState(soundboard, dialog);

  BoardState setDialog(NewTileDialog? dialog) => BoardState(soundboard, dialog);

  BoardState setRightClickedTile(String? rightClickedTile) =>
      BoardState(soundboard, dialog, rightClickedTile: rightClickedTile);

  BoardState setEncodedAHKHandle(String? encodedAHKHandle) =>
      BoardState(soundboard, dialog, encodedAHKHandle: encodedAHKHandle);
}

class NewTileDialog {
  final String? tileName;
  final bool isNameValid;
  final String? tilePath;
  final bool isPathValid;

  final bool needToValidate;

  final double tileVolume;

  NewTileDialog(this.tileName, this.tilePath,
      {this.isNameValid = false,
      this.isPathValid = false,
      this.needToValidate = false,
      this.tileVolume = 1.0});

  NewTileDialog changeName(String? tileName) =>
      NewTileDialog(tileName, tilePath,
          isNameValid: isNameValid,
          isPathValid: isPathValid,
          tileVolume: tileVolume);

  NewTileDialog changeValidity(
          bool isNameValid, bool isPathValid, bool needToValidate) =>
      NewTileDialog(tileName, tilePath,
          isNameValid: isNameValid,
          isPathValid: isPathValid,
          needToValidate: needToValidate,
          tileVolume: tileVolume);

  NewTileDialog changePath(String? tilePath) =>
      NewTileDialog(tileName, tilePath,
          isNameValid: isNameValid,
          isPathValid: isPathValid,
          tileVolume: tileVolume);

  NewTileDialog changeVolume(double tileVolume) =>
      NewTileDialog(tileName, tilePath,
          isNameValid: isNameValid,
          isPathValid: isPathValid,
          tileVolume: tileVolume);
}
