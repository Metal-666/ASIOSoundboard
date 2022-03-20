using ASIOSoundboard.Audio;
using ASIOSoundboard.Web.Controllers;
using ASIOSoundboard.Web.Modules;
using EmbedIO;
using EmbedIO.WebApi;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Windows;

namespace ASIOSoundboard {

	public partial class App : Application {

		private ILogger logger;

		private WebServer? webServer;
		private AudioManager? audioManager;

		private MainWindow? window;

		private void OnStartup(object sender, StartupEventArgs e) {

			ILoggerFactory loggerFactory = LoggerFactory.Create(builder => builder.AddDebug());

			logger = loggerFactory.CreateLogger<App>();

			audioManager = new AudioManager(loggerFactory.CreateLogger<AudioManager>());

			//Run the server
			RunWebServer(loggerFactory);

			//If we pass --no-ui parameter to the executable, no window will be created
			//This was done so that I can run Flutter UI separately, with debugger enabled
			//In prod --no-ui shouldn't be used
			if(!e.Args.Contains("--no-ui")) {

				window = new MainWindow(e.Args.Contains("--no-flutter"));
				window.Show();

			}

		}

		/// <summary>
		/// Starts the web server.
		/// </summary>
		/// <param name="loggerFactory">Used to create loggers for controllers used by the server.</param>
		private void RunWebServer(ILoggerFactory loggerFactory) {

			if(audioManager != null) {

				HostEventsModule hostEventsModule = new("/websockets", audioManager, loggerFactory.CreateLogger<HostEventsModule>());
				CoreController coreController = new(audioManager, loggerFactory.CreateLogger<CoreController>());

				coreController.OnAppReloadRequest += (sender, e) => window?.ReloadApp();

				webServer = new WebServer((WebServerOptions options) => options
						.WithUrlPrefix("http://localhost:29873/")
						.WithMode(HttpListenerMode.EmbedIO))
					.WithModule(hostEventsModule)
					.WithWebApi("/controller/public", (WebApiModule module) => module.WithController(() => new PublicController(audioManager, hostEventsModule, loggerFactory.CreateLogger<PublicController>())))
					.WithWebApi("/controller/core", (WebApiModule module) => module.WithController(() => coreController))
					.WithStaticFolder("/", @"flutter-ui\", true);

				webServer.Start();

			}

		}

		private void OnExit(object sender, ExitEventArgs e) {

			webServer?.Dispose();
			audioManager?.Dispose();

		}

	}

}