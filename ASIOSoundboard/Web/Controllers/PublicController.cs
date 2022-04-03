using ASIOSoundboard.Audio;
using ASIOSoundboard.Web.Modules;
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

		private readonly HostEventsModule hostEventsModule;

		public PublicController(AudioManager audioManager, HostEventsModule hostEventsModule, ILogger logger) {

			this.audioManager = audioManager;
			this.hostEventsModule = hostEventsModule;
			this.logger = logger;

		}

		#region Verb: ANY

		[Route(HttpVerbs.Any, "/unknown")]
		public void Unknown() => logger.LogWarning("Unknown request");

		#endregion

		#region Verb: POST

		/// <summary>
		/// Plays a sound from a Tile (or all tiles, if multiple where found) with the provided name.
		/// </summary>
		/// <param name="selector">The name of the Tile.</param>
		[Route(HttpVerbs.Post, "/play")]
		public void Play([FormField] string file, [FormField] float volume) {

			logger.LogInformation("Playing file ({})", file);

			audioManager.PlayFile(file, volume);

		}

		[Route(HttpVerbs.Post, "/request-play")]
		public void RequestPlay([FormField] string name) {

			logger.LogInformation("Requested file playback ({})", name);

			if(name != null) {

				hostEventsModule.RequestSoundByName(name);

			}

		}

		/// <summary>
		/// Stops all sounds.
		/// </summary>
		[Route(HttpVerbs.Post, "/stop")]
		public void Stop() {

			logger.LogInformation("Stopping all sounds");

			audioManager.StopAllSounds();

		}

		#endregion

	}

}