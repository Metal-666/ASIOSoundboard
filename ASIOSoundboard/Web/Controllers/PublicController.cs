using ASIOSoundboard.Audio;
using EmbedIO;
using EmbedIO.Routing;
using EmbedIO.WebApi;
using Microsoft.Extensions.Logging;
using System.Collections.Specialized;

namespace ASIOSoundboard.Web.Controllers {

	/// <summary>
	/// A <c>WebApiController</c> that can interact with <c>AudioManager</c>.
	/// </summary>
	public class PublicController : WebApiController {

		private readonly ILogger logger;

		private readonly AudioManager audioManager;

		public PublicController(AudioManager audioManager, ILogger logger) {

			this.audioManager = audioManager;
			this.logger = logger;

		}

		/// <summary>
		/// Plays a sound from a Tile (or all tiles, if multiple where found) with the provided name.
		/// </summary>
		/// <param name="selector">The name of the Tile.</param>
		[Route(HttpVerbs.Post, "/play")]
		public async void Play() {

			NameValueCollection query = await HttpContext.GetRequestFormDataAsync();

			logger.LogInformation("Playing file ({})", query.Get("file"));

			audioManager.PlayFile(query.Get("file"), float.Parse(query.Get("volume") ?? "1"));

		}

		/// <summary>
		/// Stops all sounds.
		/// </summary>
		[Route(HttpVerbs.Post, "/stop")]
		public void Stop() {

			logger.LogInformation("Stopping all sounds");

			audioManager.StopAllSounds();

		}

	}

}