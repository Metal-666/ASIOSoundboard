using ASIOSoundboard.Audio;
using EmbedIO;
using EmbedIO.Routing;
using EmbedIO.WebApi;
using Microsoft.Extensions.Logging;
using System.Collections.Specialized;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ASIOSoundboard.Web.Controllers {

	public class CoreController : WebApiController {

		private readonly ILogger logger;

		private readonly AudioManager audioManager;

		public CoreController(AudioManager audioManager, ILogger logger) {

			this.audioManager = audioManager;
			this.logger = logger;

		}

		[Route(HttpVerbs.Any, "/unknown")]
		public void Unknown() => logger.LogWarning("Unknown request");

		[Route(HttpVerbs.Get, "/audio-devices")]
		public async Task AudioDevices() {

			logger.LogInformation("Listing audio devices");

			await HttpContext.SendDataAsync(AudioManager.GetASIODevices());
			
		}

		[Route(HttpVerbs.Get, "/sample-rates")]
		public async Task SampleRates() {

			logger.LogInformation("Listing sample rates");

			await HttpContext.SendDataAsync(new int[] { 44100, 48000, 88200, 96000, 176400, 192000 });

		}

		[Route(HttpVerbs.Get, "/pick-file")]
		public async Task PickFile() {

			logger.LogInformation("Picking a file");

			string? file = await System.Windows.Application.Current.Dispatcher.Invoke(PickFileTask);

			await HttpContext.SendDataAsync(file ?? "");

		}

		[Route(HttpVerbs.Get, "/load-file")]
		public async Task LoadFile() {

			logger.LogInformation("Loading a file");

			NameValueCollection query = HttpContext.GetRequestQueryData();

			string? content = await System.Windows.Application.Current.Dispatcher.Invoke(() => LoadFileTask(query.Get("filter")));

			await HttpContext.SendDataAsync(content ?? "");

		}

		[Route(HttpVerbs.Get, "/file-exists")]
		public async Task FileExists() {

			logger.LogInformation("Checking if file exists");

			NameValueCollection query = HttpContext.GetRequestQueryData();

			bool exists = await System.Windows.Application.Current.Dispatcher.Invoke(() => FileExistsTask(query.Get("path")));

			await HttpContext.SendDataAsync(exists);

		}

		[Route(HttpVerbs.Post, "/audio-device")]
		public async void AudioDevice() {

			logger.LogInformation("Setting Audio Device");

			audioManager.AudioDevice = (await HttpContext.GetRequestFormDataAsync()).Get("device");

		}

		[Route(HttpVerbs.Post, "/sample-rate")]
		public async void SampleRate() {

			logger.LogInformation("Setting Sample Rate");

			audioManager.SampleRate = int.Parse((await HttpContext.GetRequestFormDataAsync()).Get("rate") ?? "0");

		}

		[Route(HttpVerbs.Post, "/global-volume")]
		public async void GlobalVolume() {

			logger.LogInformation("Setting Global Volume");

			audioManager.SetGlobalVolume(float.Parse((await HttpContext.GetRequestFormDataAsync()).Get("volume") ?? "1"));

		}

		[Route(HttpVerbs.Post, "/toggle-audio-engine")]
		public void ToggleAudioEngine() {

			logger.LogInformation("Toggling Audio Engine");

			audioManager.ToggleAudioEngine();

		}

		[Route(HttpVerbs.Post, "/save-file")]
		public async void SaveFile() {

			logger.LogInformation("Saving a file");

			NameValueCollection form = await HttpContext.GetRequestFormDataAsync();

			System.Windows.Application.Current.Dispatcher.Invoke(() => {

				SaveFileDialog dialog = new() {

					AddExtension = true,
					Filter = form.Get("filter"),
					DefaultExt = form.Get("default_ext"),

				};

				if(dialog.ShowDialog() == DialogResult.OK) {

					File.WriteAllText(dialog.FileName, form.Get("content"));

				}

			});

		}

		[Route(HttpVerbs.Post, "/resample-file")]
		public async void ResampleFile() {

			logger.LogInformation("Resampling a file");

			NameValueCollection form = await HttpContext.GetRequestFormDataAsync();

			audioManager.ResampleFile(form.Get("file"), int.Parse(form.Get("rate") ?? "48000"));

		}

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

	}

}