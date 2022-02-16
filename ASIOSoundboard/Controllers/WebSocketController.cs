using ASIOSoundboard.Audio;
using EmbedIO.WebSockets;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Unicode;
using System.Threading.Tasks;
using System.Windows.Forms;
using static ASIOSoundboard.Audio.AudioManager;
using static ASIOSoundboard.Audio.Soundboard;

namespace ASIOSoundboard.Controllers {

	/// <summary>
	/// A <c>WebSocketModule</c> that is used to communicate with application's UI.
	/// </summary>
	public class WebSocketController : WebSocketModule {

		private readonly ILogger logger;

		private readonly AudioManager audioManager;

		private static readonly JsonSerializerOptions jsonSerializerOptions = new () {

			Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping

		};

		public WebSocketController(string urlPath, AudioManager audioManager, ILogger logger) : base(urlPath, true) {

			this.audioManager = audioManager;
			this.logger = logger;

		}

		private void ASIOStartedHandler(object? sender, EventArgs args) {

			SendMessage("started_audio_engine");

		}

		private void ASIOStoppedHandler(object? sender, EventArgs args) {

			SendMessage("stopped_audio_engine");

		}

		private void AudioDeviceChangedHandler(object? sender, AudioDeviceChangedEventArgs args) {

			SendMessage("set_audio_device", args);

		}

		private void SampleRateChangedHandler(object? sender, SampleRateChangedEventArgs args) {

			SendMessage("set_sample_rate", args);

		}

		private void ASIOErrorHandler(object? sender, ASIOErrorEventArgs args) {

			SendMessage("audio_engine_error", args);

		}

		private void FileLoadErrorHandler(object? sender, FileErrorEventArgs args) {

			SendMessage("file_load_error", args);

		}

		private void UnloadedFilesHandler(object? sender, EventArgs args) {

			SendMessage("unloaded_files");

		}

		private void FileResampleHandler(object? sender, FileResampleEventArgs args) {

			SendMessage("file_resample_needed", args);

		}

		protected override Task OnClientConnectedAsync(IWebSocketContext context) {

			logger.LogInformation("New client is connecting...");

			//If we already have one client connected, yeet the new one
			if(ActiveContexts.Count > 1) {

				logger.LogWarning("We already have one connected - yeet the impostor");

				CloseAsync(context);
			
			}

			//Subscribe to all the audio manager events
			//It's not really necessary to do it this way, but whatever, maybe I'll rewrite this for v2
			audioManager.OnStartedASIO += ASIOStartedHandler;
			audioManager.OnStoppedASIO += ASIOStoppedHandler;
			audioManager.OnAudioDeviceChanged += AudioDeviceChangedHandler;
			audioManager.OnSampleRateChanged += SampleRateChangedHandler;
			audioManager.OnASIOError += ASIOErrorHandler;
			audioManager.OnFileLoadError += FileLoadErrorHandler;
			audioManager.OnFileResampleNeeded += FileResampleHandler;

			return base.OnClientConnectedAsync(context);

		}

		protected override Task OnClientDisconnectedAsync(IWebSocketContext context) {

			logger.LogWarning("Our client is gone!");

			audioManager.OnStartedASIO -= ASIOStartedHandler;
			audioManager.OnStoppedASIO -= ASIOStoppedHandler;
			audioManager.OnAudioDeviceChanged -= AudioDeviceChangedHandler;
			audioManager.OnSampleRateChanged -= SampleRateChangedHandler;
			audioManager.OnASIOError -= ASIOErrorHandler;
			audioManager.OnFileLoadError -= FileLoadErrorHandler;
			audioManager.OnFileResampleNeeded -= FileResampleHandler;

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

					case "get_soundboard": {

						return SendMessage("get_soundboard", new Dictionary<string, dynamic?>() {

							{ "soundboard", audioManager.Soundboard }

						});

					}

					case "list_audio_devices": {

						return SendMessage("list_audio_devices", new Dictionary<string, dynamic?>() {

							{ "audio_devices", GetASIODevices() }

						});

					}

					case "list_sample_rates": {

						return SendMessage("list_sample_rates", new Dictionary<string, dynamic?>() {

							{ "sample_rates", new int[] { 44100, 48000, 88200, 96000, 176400, 192000 } }

						});

					}

					case "set_audio_device": {

						audioManager.AudioDevice = data?["audio_device"].GetString();

						break;

					}

					case "set_sample_rate": {

						audioManager.SampleRate = data?["sample_rate"].GetInt32() ?? 0;

						break;

					}

					case "set_global_volume": {

						audioManager.SetGlobalVolume((float) (data?["volume"].GetDouble() ?? 0));

						break;

					}

					case "toggle_audio_engine": {

						audioManager.ToggleAudioEngine();

						break;

					}

					case "play_tile_by_id": {

						audioManager.PlayTileById(data?["id"].GetString());

						break;

					}

					case "validate_new_tile": {

						string? name = data?["name"].GetString(),
							file = data?["file"].GetString();

						if(string.IsNullOrWhiteSpace(name)) {

							name = null;
						
						}

						if(!File.Exists(file)) {

							file = null;
						
						}

						Tile tile = new() {

							File = file,
							Name = name,
							Volume = (float) (data?["volume"].GetDouble() ?? 1)

						};

						if(name != null && file != null) {

							audioManager.Soundboard.Tiles.Add(tile);

						}

						SendMessage("validate_new_tile", tile);

						break;

					}

					case "pick_tile_path": {

						System.Windows.Application.Current.Dispatcher.Invoke(() => {

							OpenFileDialog dialog = new() {

								CheckFileExists = true

							};

							if(dialog.ShowDialog() == DialogResult.OK) {

								SendMessage("pick_tile_path", new Dictionary<string, dynamic?>() {

									{ "file", dialog.FileName }

								});

							}

						});

						break;

					}

					case "file_resample_needed": {

						audioManager.ResampleFile(data?["file"].GetString(), data?["sample_rate"].GetInt32() ?? 0);

						break;

					}

					case "stop_all_sounds": {

						audioManager.StopAllSounds();

						break;

					}

					case "delete_tile": {

						string? id = data?["id"].GetString();

						audioManager.Soundboard.Tiles.RemoveAll((Tile tile) => tile.Id.Equals(id));

						SendMessage("delete_tile", new Dictionary<string, dynamic?>() {

							{ "id", id }

						});

						break;

					}

					case "save_soundboard": {

						System.Windows.Application.Current.Dispatcher.Invoke(() => {

							SaveFileDialog dialog = new() {

								AddExtension = true,
								Filter = "Json File (*.json)|*.json",
								DefaultExt = "json",
							
							};

							if(dialog.ShowDialog() == DialogResult.OK) {

								using StreamWriter writer = File.CreateText(dialog.FileName);

								writer.WriteLine(JsonSerializer.Serialize(audioManager.Soundboard));

							}

						});

						break;

					}

					case "load_soundboard": {

						System.Windows.Application.Current.Dispatcher.Invoke(() => {

							OpenFileDialog dialog = new() {

								Filter = "Json File (*.json)|*.json",
								CheckFileExists = true

							};

							if(dialog.ShowDialog() == DialogResult.OK) {

								Soundboard? soundboard = JsonSerializer.Deserialize<Soundboard>(File.ReadAllText(dialog.FileName));

								if(soundboard != null) {

									audioManager.Soundboard = soundboard;

									SendMessage("get_soundboard", new Dictionary<string, dynamic?>() {

										{ "soundboard", audioManager.Soundboard }

									});

								}

								else {

									FileLoadErrorHandler(this, new FileErrorEventArgs() {
									
										Error = "FILE DESERIALIZATION ERROR",
										Description = "Soundboard file you selected could not be loaded",
										File = dialog.FileName
									
									});

								}

							}

						});

						break;

					}

					case "save_tile_size": {

						Properties.Settings.Default.TileSize = data?["size"].GetDouble() ?? 1;

						Properties.Settings.Default.Save();

						break;
					
					}

					case "restore_tile_size": {

						SendMessage("restore_tile_size", new Dictionary<string, dynamic?>() {

							{ "size", Properties.Settings.Default.TileSize }

						});

						break;

					}

					case "save_global_volume": {

						Properties.Settings.Default.GlobalVolume = data?["volume"].GetDouble() ?? 1;

						Properties.Settings.Default.Save();

						break;

					}

					case "restore_global_volume": {

						SendMessage("restore_global_volume", new Dictionary<string, dynamic?>() {

							{ "volume", Properties.Settings.Default.GlobalVolume }

						});

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

				audioManager.DisposeASIO();
			
			}

			base.Dispose(disposing);

		}

	}

}