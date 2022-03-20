import 'dart:convert';

/// Represents a serializable collection of Tiles.
class Soundboard {
  final List<Tile> tiles;

  const Soundboard(this.tiles);

  Soundboard copyWith({List<Tile> Function()? tiles}) =>
      Soundboard(tiles == null ? this.tiles : tiles.call());

  Map<String, dynamic> toMap() => {
        'tiles': tiles.map((x) => x.toMap()).toList(),
      };

  factory Soundboard.fromMap(Map<String, dynamic> map) => Soundboard(
        map['tiles'] != null
            ? List<Tile>.from(map['tiles']?.map((x) => Tile.fromMap(x)))
            : const <Tile>[],
      );

  String toJson() => json.encode(toMap());

  factory Soundboard.fromJson(String source) =>
      Soundboard.fromMap(json.decode(source));
}

/// Represents a single tile on the board.
class Tile {
  final String? filePath;
  final String? name;

  final double? volume;

  const Tile(this.filePath, this.name, this.volume);

  Tile copyWith(
          {String? Function()? filePath,
          String? Function()? name,
          String? Function()? id,
          double? Function()? volume}) =>
      Tile(
          filePath == null ? this.filePath : filePath.call(),
          name == null ? this.name : name.call(),
          volume == null ? this.volume : volume.call());

  Map<String, dynamic> toMap() =>
      {'file_path': filePath, 'name': name, 'volume': volume};

  factory Tile.fromMap(Map<String, dynamic> map) =>
      Tile(map['file_path'], map['name'], map['volume']);

  String toJson() => json.encode(toMap());

  factory Tile.fromJson(String source) => Tile.fromMap(json.decode(source));
}
