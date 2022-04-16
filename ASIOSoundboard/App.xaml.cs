using ASIOSoundboard.Audio;
using ASIOSoundboard.Logging;
using ASIOSoundboard.Web.Controllers;
using ASIOSoundboard.Web.Modules;
using EmbedIO;
using EmbedIO.WebApi;
using Medallion.Shell;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;

namespace ASIOSoundboard {

	public partial class App : Application {

		private const string UI_PATH = "flutter-ui/asio_soundboard.exe";

		private ILogger? logger;

		private WebServer? webServer;
		private AudioManager? audioManager;

		private MainWindow? window;

		private CancellationTokenSource? uiYeeter;

		private bool persistentHost = true;

		private void OnStartup(object sender, StartupEventArgs startupEventArgs) {

			window = new MainWindow();
			window.Show();

			ILoggerFactory loggerFactory = LoggerFactory.Create(builder => builder.AddDebug().AddWindowLogger(configuration => {

				configuration.MainWindow = window;

			}));

			logger = loggerFactory.CreateLogger<App>();

			audioManager = new AudioManager(loggerFactory.CreateLogger<AudioManager>());

			logger.LogInformation("Launching internal server...");

			//Run the server
			RunWebServer(loggerFactory);

			//If we pass --no-ui parameter to the executable, no window will be created
			//This was done so that I can run Flutter UI separately, with debugger enabled
			//In prod --no-ui shouldn't be used
			if(!startupEventArgs.Args.Contains("--no-ui")) {

				persistentHost = false;

				LaunchUI();

			}

		}

		/// <summary>
		/// Starts the web server.
		/// </summary>
		/// <param name="loggerFactory">Used to create loggers for controllers used by the server.</param>
		private void RunWebServer(ILoggerFactory loggerFactory) {

			if(audioManager != null) {

				HostEventsModule hostEventsModule = new("/websockets", audioManager, loggerFactory.CreateLogger<HostEventsModule>());
				CoreController coreController = new(audioManager, hostEventsModule, loggerFactory.CreateLogger<CoreController>());
				PublicController publicController = new(audioManager, hostEventsModule, loggerFactory.CreateLogger<PublicController>());

				webServer = new WebServer((WebServerOptions options) => options
						.WithUrlPrefix("http://localhost:29873/")
						.WithMode(HttpListenerMode.EmbedIO))
					.WithModule(hostEventsModule)
					.WithWebApi("/controller/public", (WebApiModule module) => module.WithController(() => publicController))
					.WithWebApi("/controller/core", (WebApiModule module) => module.WithController(() => coreController))
					.WithStaticFolder("/", @"flutter-ui\", true);

				webServer.Start();

			}

		}

		private void OnExit(object sender, ExitEventArgs e) {

			webServer?.Dispose();
			audioManager?.Dispose();

		}

		private void LaunchUI() {

			logger?.LogInformation("Waiting for UI to load...");

			Task.Run(LaunchUIAsync);

		}

		private async Task LaunchUIAsync() {

			List<string> arguments = new();

			if(uiYeeter != null) {

				uiYeeter.Cancel();

				arguments.Add("-was-restarted");

			}

			Current.Dispatcher.Invoke(() => {

				if(!persistentHost) {

					window?.Hide();

				}

			});

			uiYeeter = new CancellationTokenSource();

			CommandResult result = await Command.Run(UI_PATH, arguments, options => options.CancellationToken(uiYeeter.Token)).Task;

			if(result.Success) {

				Dispatcher.Invoke(() => Shutdown());

			}

			else {

				switch(result.ExitCode) {

					case 1: {

						await LaunchUIAsync();

						break;

					}

					default: {

						logger?.LogWarning("Did UI just crash??");

						Current.Dispatcher.Invoke(() => {

							window?.Show();

						});

						break;

					}

				}

			}

		}

		private void CloseUI() {

			uiYeeter?.Cancel();

			uiYeeter = null;

		}

		public void ToggleUI() {

			if(uiYeeter == null) {

				LaunchUI();

			}

			else {

				CloseUI();

			}

		}

	}

}