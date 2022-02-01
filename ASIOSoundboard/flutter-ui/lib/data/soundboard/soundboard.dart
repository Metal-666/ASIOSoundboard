import 'dart:convert';

/// Represents a serializable collection of Tiles.
class Soundboard {
  final List<Tile?> tiles;

  Soundboard(this.tiles);

  Map<String, dynamic> toMap() => {
        'tiles': tiles.map((x) => x?.toMap()).toList(),
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
  final String? id;

  final double? volume;

  Tile(this.filePath, this.name, this.id, this.volume);

  Map<String, dynamic> toMap() =>
      {'file_path': filePath, 'name': name, 'id': id, 'volume': volume};

  factory Tile.fromMap(Map<String, dynamic> map) =>
      Tile(map['file_path'], map['name'], map['id'], map['volume']);

  String toJson() => json.encode(toMap());

  factory Tile.fromJson(String source) => Tile.fromMap(json.decode(source));
}