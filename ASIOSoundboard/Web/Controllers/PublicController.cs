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

		[Route(HttpVerbs.Post, "/play")]
		public void Play([FormData] NameValueCollection data) {

			logger.LogInformation("Playing file ({} @ {})", data.Get("file"), data.Get("volume"));

			float? volume = null;

			if(float.TryParse(data.Get("volume"), out float resultVolume)) {

				volume = resultVolume;

			}

			audioManager.PlayFile(data.Get("file"), volume ?? 1);

		}

		[Route(HttpVerbs.Post, "/request-play")]
		public void RequestPlay([FormField(false)] string name) {

			logger.LogInformation("Requested file playback ({})", name);

			if(!string.IsNullOrEmpty(name)) {

				hostEventsModule.RequestSoundByName(name);

			}

		}

		[Route(HttpVerbs.Post, "/stop")]
		public void Stop() {

			logger.LogInformation("Stopping all sounds");

			audioManager.StopAllSounds();

		}

		#endregion

	}

}