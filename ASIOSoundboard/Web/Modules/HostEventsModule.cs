using ASIOSoundboard.Audio;
using EmbedIO.WebSockets;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Threading.Tasks;
using static ASIOSoundboard.Audio.AudioManager;

namespace ASIOSoundboard.Web.Modules {

	/// <summary>
	/// A <c>WebSocketModule</c> that is used to communicate with application's UI.
	/// </summary>
	public class HostEventsModule : WebSocketModule {

		private readonly ILogger logger;

		private readonly AudioManager audioManager;

		private static readonly JsonSerializerOptions jsonSerializerOptions = new() {

			Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping

		};

		public HostEventsModule(string urlPath, AudioManager audioManager, ILogger logger) : base(urlPath, true) {

			this.audioManager = audioManager;
			this.logger = logger;

			audioManager.OnAudioEngineStatus += AudioEngineStatusHandler;
			audioManager.OnError += ErrorHandler;

		}

		public void RequestSoundByName(string name) {

			SendMessage("request_sound_by_name", new Dictionary<string, dynamic>() {

				{ "name", name }

			});

		}

		public void AudioEngineStatusHandler(object? sender, AudioEngineStatusEventArgs args) {

			SendMessage("audio_engine_status", args);

		}

		public void ErrorHandler(object? sender, ErrorEventArgs args) {

			SendMessage("error", new Dictionary<string, dynamic>() {

				{ "error", args }

			});

		}

		protected override Task OnClientConnectedAsync(IWebSocketContext context) {

			logger.LogInformation("New client is connecting...");

			SendMessage("connection_established");

			return base.OnClientConnectedAsync(context);

		}

		protected override Task OnClientDisconnectedAsync(IWebSocketContext context) {

			logger.LogWarning("Our client is gone!");

			return base.OnClientDisconnectedAsync(context);

		}

		protected override Task OnMessageReceivedAsync(IWebSocketContext context, byte[] buffer, IWebSocketReceiveResult result) {

			Dictionary<string, JsonElement>? message = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(buffer),
				data = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(message?["data"].GetString() ?? "{}");

			logger.LogInformation("Received a message from the client: {}", message);

			if(message?["event"] != null) {

				//Depending on the event type, do different stuff
				//The purpose of each command should be pretty self-explanatory from it's name.
				switch(message["event"].GetString()) {

					case "app_loaded": {

						SendMessage("app_loaded");

						audioManager.AudioEngineStatus();

						break;

					}

				}

			}

			return Task.CompletedTask;

		}

		/// <summary>
		/// Sends a message without data to the client.
		/// </summary>
		/// <param name="type">Message type.</param>
		/// <returns>Something.</returns>
		private Task SendMessage(string type) => SendMessage(type, new Dictionary<string, dynamic>());

		/// <summary>
		/// Sends a message with data to the client.
		/// </summary>
		/// <param name="type">Message type.</param>
		/// <param name="data">Key-value pairs of data, will be serialized to JSON when sending.</param>
		/// <returns>Something.</returns>
		private Task SendMessage(string type, dynamic? data) {

			string message = JsonSerializer.Serialize(new Dictionary<string, dynamic?>() {

				{ "type", type },
				{ "data", data }

			}, jsonSerializerOptions);

			logger.LogInformation("Sending a message to the client: {}", message);

			return BroadcastAsync(message);

		}

		protected override void Dispose(bool disposing) {

			if(audioManager != null) {

				audioManager.OnAudioEngineStatus -= AudioEngineStatusHandler;
				audioManager.OnError -= ErrorHandler;

			}

			base.Dispose(disposing);

		}

	}

}