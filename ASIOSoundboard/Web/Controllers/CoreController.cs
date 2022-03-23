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

		public event EventHandler? OnAppReloadRequest;

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
		public async Task AudioDevices() {

			logger.LogInformation("Listing audio devices");

			string[]? asioDevices = AudioManager.GetASIODevices();

			logger.LogInformation("Fetched list: {}, sending...", asioDevices);

			await HttpContext.SendDataAsync(new Dictionary<string, string[]>{

				{ "devices", asioDevices }

			});
			
		}

		[Route(HttpVerbs.Get, "/sample-rates")]
		public async Task SampleRates() {

			logger.LogInformation("Listing sample rates");

			await HttpContext.SendDataAsync(new Dictionary<string, int[]>{

				{ "rates", new int[] { 44100, 48000, 88200, 96000, 176400, 192000 } }

			});

		}

		[Route(HttpVerbs.Get, "/pick-file")]
		public async Task PickFile() {

			logger.LogInformation("Picking a file");

			string? file = await System.Windows.Application.Current.Dispatcher.Invoke(PickFileTask);

			await HttpContext.SendDataAsync(new Dictionary<string, string>() {
			
				{ "file", file ?? "" }
				
			});

		}

		[Route(HttpVerbs.Get, "/load-file")]
		public async Task LoadFile() {

			logger.LogInformation("Loading a file");

			NameValueCollection query = HttpContext.GetRequestQueryData();

			string? content = await System.Windows.Application.Current.Dispatcher.Invoke(() => LoadFileTask(query.Get("filter")));
			
			await HttpContext.SendDataAsync(new Dictionary<string, string?>() {
			
				{ "content", content }
			
			});

		}

		[Route(HttpVerbs.Get, "/read-file")]
		public async Task ReadFile() {

			logger.LogInformation("Loading a file");

			string? path = HttpContext.GetRequestQueryData().Get("path");

			string? content = null;

			if(!string.IsNullOrWhiteSpace(path) && File.Exists(path)) {

				content = File.ReadAllText(path);

				await HttpContext.SendDataAsync(new Dictionary<string, string?>() {

					{ "content", content }

				});

			}

			else {

				hostEventsModule.FileErrorHandler(this, new AudioManager.FileErrorEventArgs() {

					Error = AudioManager.FileErrorEventArgs.CANT_READ_FILE,
					Description = "File path is empty or file doesn't exist",
					File = path

				});

				HttpContext.Response.StatusCode = 500;

			}

		}

		[Route(HttpVerbs.Get, "/file-exists")]
		public async Task FileExists() {

			logger.LogInformation("Checking if file exists");

			NameValueCollection query = HttpContext.GetRequestQueryData();

			bool exists = await System.Windows.Application.Current.Dispatcher.Invoke(() => FileExistsTask(query.Get("path")));

			await HttpContext.SendDataAsync(new Dictionary<string, bool>() {

				{ "exists", exists }

			});

		}

		#endregion

		#region Verb: POST

		[Route(HttpVerbs.Post, "/start-audio-engine")]
		public async void StartAudioEngine() {

			NameValueCollection form = await HttpContext.GetRequestFormDataAsync();

			string? audioDevice = form.Get("device");
			int? sampleRate = null;
			float? globalVolume = null;

			if(int.TryParse(form.Get("rate"), out int rate)) {

				sampleRate = rate;

			}

			if(float.TryParse(form.Get("volume"), out float volume)) {

				globalVolume = volume;

			}

			logger.LogInformation("Starting Audio Engine with AudioEngine={}, SampleRate={}, GlobalVolume={}", audioDevice, sampleRate, globalVolume);

			audioManager.StartAudioEngine(audioDevice, sampleRate, globalVolume);

		}

		[Route(HttpVerbs.Post, "/stop-audio-engine")]
		public void StopAudioEngine() {

			logger.LogInformation("Stopping Audio Engine");

			audioManager.StopAudioEngine();

		}

		[Route(HttpVerbs.Post, "/global-volume")]
		public async void GlobalVolume() {

			float globalVolume = float.Parse((await HttpContext.GetRequestFormDataAsync()).Get("volume") ?? "1");

			logger.LogInformation("Setting Global Volume to {}", globalVolume);

			audioManager.SetGlobalVolume(globalVolume);

		}

		[Route(HttpVerbs.Post, "/save-file")]
		public async Task SaveFile() {

			logger.LogInformation("Saving a file");

			NameValueCollection form = await HttpContext.GetRequestFormDataAsync();

			string? path = await System.Windows.Application.Current.Dispatcher.Invoke(() => SaveFileTask(form.Get("filter"), form.Get("default_ext"), form.Get("content")));

			await HttpContext.SendDataAsync(new Dictionary<string, string?>{

				{ "path", path }

			});

		}

		[Route(HttpVerbs.Post, "/resample-file")]
		public async void ResampleFile() {

			logger.LogInformation("Resampling a file");

			NameValueCollection form = await HttpContext.GetRequestFormDataAsync();

			audioManager.ResampleFile(form.Get("file"), int.Parse(form.Get("rate") ?? "48000"));

		}

		[Route(HttpVerbs.Post, "/reload")]
		public void Reload() {

			logger.LogInformation("Reloading app");

			OnAppReloadRequest?.Invoke(this, new EventArgs());

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

		private async Task<string?> SaveFileTask(string? filter, string? defaultExt, string? content) {

			SaveFileDialog dialog = new() {

				AddExtension = true,
				Filter = filter,
				DefaultExt = defaultExt,

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