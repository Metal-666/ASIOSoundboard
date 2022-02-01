using ASIOSoundboard.Audio;
using EmbedIO;
using EmbedIO.Routing;
using EmbedIO.WebApi;
using Microsoft.Extensions.Logging;
using System.Linq;
using static ASIOSoundboard.Audio.Soundboard;

namespace ASIOSoundboard.Controllers {

	/// <summary>
	/// A <c>WebApiController</c> that can interact with <c>AudioManager</c>.
	/// </summary>
	public class SoundboardController : WebApiController {

		private readonly ILogger logger;

		private readonly AudioManager audioManager;

		public SoundboardController(AudioManager audioManager, ILogger logger) {

			this.audioManager = audioManager;
			this.logger = logger;

		}

		/// <summary>
		/// Plays a sound from a Tile (or all tiles, if multiple where found) with the provided name.
		/// </summary>
		/// <param name="selector">The name of the Tile.</param>
		[Route(HttpVerbs.Get, "/play/byName/{selector}")]
		public void PlayByName(string selector) {

			logger.LogInformation("Playing tile by name ({})", selector);

			audioManager.Soundboard.Tiles.Where((Tile tile) => tile.Name?.Equals(selector) ?? false).ToList().ForEach((Tile tile) => audioManager.PlayFile(tile.File));
		
		}

		/// <summary>
		/// Stops all sounds.
		/// </summary>
		[Route(HttpVerbs.Get, "/stopAll")]
		public void StopAll() {

			logger.LogInformation("Stopping all sounds");

			audioManager.StopAllSounds();

		}

	}

}