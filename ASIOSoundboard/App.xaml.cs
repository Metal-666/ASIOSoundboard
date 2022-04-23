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

		// Cancelling this token closes the UI (if the UI was not started, the token will be null)
		private CancellationTokenSource? uiYeeter;

		// This indicates if Host window should stay when the UI is launched
		private bool persistentHost = false;

		private void OnStartup(object sender, StartupEventArgs startupEventArgs) {

			window = new MainWindow();
			window.Show();

			ILoggerFactory loggerFactory = LoggerFactory.Create(builder => builder.AddDebug().AddWindowLogger(configuration => {

				configuration.MainWindow = window;

			}));

			logger = loggerFactory.CreateLogger<App>();

			audioManager = new AudioManager(loggerFactory.CreateLogger<AudioManager>());

			logger.LogInformation("Launching internal server...");

			RunWebServer(loggerFactory);

			// If we pass --no-ui parameter to the executable, the Host window will not start the UI
			// This is useful for situations where you want to debug the UI separately
			if(startupEventArgs.Args.Contains("--no-ui")) {

				persistentHost = true;

				return;

			}
			
			LaunchUI();

		}

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

			// Running LaunchUIAsync without closing the UI first indicates that we want to restart it
			// Therefore we close the UI and add a -was-restarted startup argument so that the UI knows, that it was restarted when it is launched again
			// If UI sees -was-restarted argument, it knows that the Host is already running and it doesn't need to tell it to do any initialization
			if(uiYeeter != null) {

				uiYeeter.Cancel();

				arguments.Add("-was-restarted");

			}

			Current.Dispatcher.Invoke(() => {

				// If the persistentHost flag is set, we don't hide the Host before showing the UI
				if(!persistentHost) {

					window?.Hide();

				}

			});

			// Start the UI
			uiYeeter = new CancellationTokenSource();

			CommandResult result = await Command.Run(UI_PATH, arguments, options => options.CancellationToken(uiYeeter.Token)).Task;

			// After the UI was closed, we look at the exit code
			// If the exit code is 0 (meaning the UI was exited normally), we simply shutdown everything
			if(result.Success) {

				Dispatcher.Invoke(() => Shutdown());

			}

			else {

				switch(result.ExitCode) {

					// If exit code is 1, we know that the UI was closed with an intent to be restarted (for example to apply theme changes)
					// So we restart it
					case 1: {

						await LaunchUIAsync();

						break;

					}

					// Any other exit code (for now) indicates that an error has occured when exiting
					// So we print the error to the Host console
					default: {

						logger?.LogWarning("Did UI just crash?? Exit code was {}", result.ExitCode);

						Current.Dispatcher.Invoke(() => {

							uiYeeter = null;

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