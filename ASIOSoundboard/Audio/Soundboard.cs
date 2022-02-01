using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace ASIOSoundboard.Audio {

	/// <summary>
	/// Represents a soundboard, can be serialized to JSON.
	/// </summary>
	public class Soundboard {

		/// <summary>
		/// The tiles present on the soundboard.
		/// </summary>
		[JsonPropertyName("tiles")]
		public List<Tile> Tiles { get; set; } = new List<Tile>();

		/// <summary>
		/// A single tile on the soundboard.
		/// </summary>
		public class Tile {

			/// <summary>
			/// Path to a file that should be played when clicking this tile.
			/// </summary>
			[JsonPropertyName("file")]
			public string? File { get; set; } = "";

			/// <summary>
			/// Text displayed on the tile.
			/// </summary>
			[JsonPropertyName("name")]
			public string? Name { get; set; } = "new_sound";

			/// <summary>
			/// The id of this tile in a UUID format.
			/// </summary>
			[JsonPropertyName("id")]
			public string Id { get; set; } = Guid.NewGuid().ToString();

			/// <summary>
			/// Volume that will be used together with the global volume when playing this tile.
			/// </summary>
			[JsonPropertyName("volume")]
			public float Volume { get; set; } = 1.0f;

		}

	}

}