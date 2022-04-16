using ASIOSoundboard.Audio;
using ASIOSoundboard.Web.Modules;
using EmbedIO;
using EmbedIO.Routing;
using EmbedIO.WebApi;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ASIOSoundboard.Web.Controllers {

	public class CoreController : WebApiController {

		private readonly ILogger logger;

		private readonly AudioManager audioManager;

		private readonly HostEventsModule hostEventsModule;

		public CoreController(AudioManager audioManager, HostEventsModule hostEventsModule, ILogger logger) {

			this.audioManager = audioManager;
			this.hostEventsModule = hostEventsModule;
			this.logger = logger;

		}

		#region Verb: ANY

		[Route(HttpVerbs.Any, "/unknown")]
		public void Unknown() => logger.LogWarning("Unknown request");

		#endregion

		#region Verb: GET

		[Route(HttpVerbs.Get, "/audio-devices")]
		public Dictionary<string, string[]> AudioDevices() {

			logger.LogInformation("Listing audio devices");

			string[]? asioDevices = AudioManager.GetASIODevices();

			logger.LogInformation("Fetched list: {}, sending...", asioDevices);

			return new Dictionary<string, string[]>{

				{ "devices", asioDevices }

			};
			
		}

		[Route(HttpVerbs.Get, "/sample-rates")]
		public Dictionary<string, int[]> SampleRates() {

			logger.LogInformation("Listing sample rates");

			return new Dictionary<string, int[]>{

				{ "rates", new int[] { 44100, 48000, 88200, 96000, 176400, 192000 } }

			};

		}

		[Route(HttpVerbs.Get, "/pick-file")]
		public async Task<Dictionary<string, string?>> PickFile() {

			logger.LogInformation("Picking a file");

			string? file = await System.Windows.Application.Current.Dispatcher.Invoke(PickFileTask);

			return new Dictionary<string, string?>() {
			
				{ "file", file }
				
			};

		}

		[Route(HttpVerbs.Get, "/load-file")]
		public async Task<Dictionary<string, string?>> LoadFile([QueryField(false)] string filter) {

			logger.LogInformation("Loading a file");

			string? content = await System.Windows.Application.Current.Dispatcher.Invoke(() => LoadFileTask(filter));

			return new Dictionary<string, string?>() {
			
				{ "content", content }
			
			};

		}

		[Route(HttpVerbs.Get, "/read-file")]
		public Dictionary<string, string?> ReadFile([QueryField(false)] string path) {

			logger.LogInformation("Loading a file ({})", path);

			string? content;

			if(!string.IsNullOrWhiteSpace(path) && File.Exists(path)) {

				content = File.ReadAllText(path);

				return new Dictionary<string, string?>() {

					{ "content", content }

				};

			}

			else {

				hostEventsModule.ErrorHandler(this, new AudioManager.FileLoadErrorEventArgs() {

					Subject = AudioManager.FileErrorEventArgs.FILE,
					Error = AudioManager.FileErrorEventArgs.File.NOT_FOUND,
					Path = path

				});

				throw HttpException.NotFound();

			}

		}

		[Route(HttpVerbs.Get, "/file-exists")]
		public async Task<Dictionary<string, bool>> FileExists([QueryField(false)] string path) {

			logger.LogInformation("Checking if file exists");

			bool exists = await System.Windows.Application.Current.Dispatcher.Invoke(() => FileExistsTask(path));

			return new Dictionary<string, bool>() {

				{ "exists", exists }

			};

		}

		#endregion

		#region Verb: POST

		[Route(HttpVerbs.Post, "/start-audio-engine")]
		public void StartAudioEngine([FormData] NameValueCollection data) {

			int? rate = null;
			float? volume = null;

			if(int.TryParse(data["rate"], out int rateResult)) {

				rate = rateResult;

			}

			if(float.TryParse(data["volume"], out float volumeResult)) {

				volume = volumeResult;

			}

			logger.LogInformation("Starting Audio Engine with AudioEngine={}, SampleRate={}, GlobalVolume={}", data["device"], rate, volume);

			audioManager.StartAudioEngine(data["device"], rate, volume);

		}

		[Route(HttpVerbs.Post, "/stop-audio-engine")]
		public void StopAudioEngine() {

			logger.LogInformation("Stopping Audio Engine");

			audioManager.StopAudioEngine();

		}

		[Route(HttpVerbs.Post, "/global-volume")]
		public void GlobalVolume([FormField(false)] float volume) {
		
			logger.LogInformation("Setting Global Volume to {}", volume);

			audioManager.SetGlobalVolume(volume);

		}

		[Route(HttpVerbs.Post, "/save-file")]
		public async Task<Dictionary<string, string?>> SaveFile([FormData] NameValueCollection data) {

			logger.LogInformation("Saving a file");

			string? path = await System.Windows.Application.Current.Dispatcher.Invoke(() => SaveFileTask(data.Get("filter"), data.Get("ext"), data.Get("content")));

			return new Dictionary<string, string?>{

				{ "path", path }

			};

		}

		[Route(HttpVerbs.Post, "/resample-file")]
		public void ResampleFile([FormData] NameValueCollection data) {

			string? file = data.Get("file");

			if(file != null && int.TryParse(data.Get("rate"), out int rate)) {

				logger.LogInformation("Resampling a file ({} @ {})", file, rate);

				audioManager.ResampleFile(file, rate);

			}

			else {

				logger.LogInformation("Can't resample file: one of parameters is null ({} @ {})", file, data.Get("rate"));

			}

		}

		#endregion

		#region Tasks

		private async Task<string?> PickFileTask() {

			OpenFileDialog dialog = new() {

				CheckFileExists = true

			};

			if(dialog.ShowDialog() == DialogResult.OK) {

				return dialog.FileName;

			}

			return null;

		}

		private async Task<string?> LoadFileTask(string? filter) {

			OpenFileDialog dialog = new() {

				CheckFileExists = true,
				Filter = filter

			};

			if(dialog.ShowDialog() == DialogResult.OK) {

				return File.ReadAllText(dialog.FileName);

			}

			return null;

		}

		private async Task<bool> FileExistsTask(string? path) {

			return File.Exists(path);

		}

		private async Task<string?> SaveFileTask(string? filter, string? ext, string? content) {

			SaveFileDialog dialog = new() {

				AddExtension = true,
				Filter = filter,
				DefaultExt = ext,

			};

			if(dialog.ShowDialog() == DialogResult.OK) {

				File.WriteAllText(dialog.FileName, content);

				return dialog.FileName;

			}

			return null;

		}

		#endregion

	}

}