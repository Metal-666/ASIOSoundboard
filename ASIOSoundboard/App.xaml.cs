using ASIOSoundboard.Audio;
using ASIOSoundboard.Controllers;
using EmbedIO;
using EmbedIO.WebApi;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Windows;

namespace ASIOSoundboard {

	public partial class App : Application {

		private WebServer? webServer;
		private AudioManager? audioManager;

		private void OnStartup(object sender, StartupEventArgs e) {

			ILoggerFactory loggerFactory = LoggerFactory.Create(builder => builder.AddDebug());

			audioManager = new AudioManager(loggerFactory.CreateLogger<AudioManager>());

			//Run the server
			RunWebServer(loggerFactory);

			//If we pass --no-ui parameter to the executable, no window will be created
			//This was done so that I can run Flutter UI separately, with debugger enabled
			//In prod --no-ui shouldn't be used
			if(!e.Args.Contains("--no-ui")) {

				new MainWindow(e.Args.Contains("--no-flutter")).Show();

			}

		}

		/// <summary>
		/// Starts the web server.
		/// </summary>
		/// <param name="loggerFactory">Used to create loggers for controllers used by the server.</param>
		private void RunWebServer(ILoggerFactory loggerFactory) {

			if(audioManager != null) {

				webServer = new WebServer((WebServerOptions options) => options
						.WithUrlPrefix("http://localhost:29873/")
						.WithMode(HttpListenerMode.EmbedIO))
					.WithModule(new WebSocketController("/websockets", audioManager, loggerFactory.CreateLogger<WebSocketController>()))
					.WithWebApi("/controller", (WebApiModule module) => module.WithController(() => new SoundboardController(audioManager, loggerFactory.CreateLogger<SoundboardController>())))
					.WithStaticFolder("/", @"flutter-ui\", true);

				webServer.Start();

			}

		}

		private void OnExit(object sender, ExitEventArgs e) {

			webServer?.Dispose();

		}

	}

}