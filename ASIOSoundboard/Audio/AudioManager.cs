using Microsoft.Extensions.Logging;
using NAudio.Wave;
using NAudio.Wave.SampleProviders;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.Json.Serialization;
using System.Windows;

namespace ASIOSoundboard.Audio {

	/// <summary>
	/// This class is responsible for most audio-related tasks of the application, such as audio playback, file resampling and volume control
	/// </summary>
	public class AudioManager {

		/// <summary>
		/// Handle that will be used for retrieving a device object.
		/// </summary>
		public string? AudioDevice { get; set; }

		/// <summary>
		/// This property will be treated as user's preferred sample rate. Doesn't actually set the Audio Device's sample rate.
		/// </summary>
		public int SampleRate { get; set; }

		/// <summary>
		/// Combined with each tile's own volume during playback.
		/// </summary>
		public float Volume { get; set; }

		private readonly ILogger<AudioManager> logger;

		public event EventHandler<AudioEngineStatusEventArgs>? OnAudioEngineStatus;
		public event EventHandler<ErrorEventArgs>? OnError;
		public event EventHandler<FileErrorEventArgs>? OnFileError;
		public event EventHandler<FileResampleEventArgs>? OnFileResampleNeeded;

		//This is what I usually refer to as 'Audio Engine' or 'Audio Device'
		private AsioOut? asioOut;
		//This is an object that holds all the clips that are currently played by the Audio Engine
		//Created and destroyed together with Audio Engine
		private MixingSampleProvider? asioSampleProvider;

		public AudioManager(ILogger<AudioManager> logger) => this.logger = logger;

		/// <summary>
		/// Turns the Audio Engine on or off, depending on the current state.
		/// </summary>
		public void ToggleAudioEngine() {

			if(asioOut == null) {

				InitialiseASIO();

			}

			else {

				DisposeASIO();

			}

		}

		/// <summary>
		/// Sets the volume of the soundboard.
		/// </summary>
		/// <param name="volume">Desired volume.</param>
		public void SetGlobalVolume(double volume) {

			//Make sure our eardrums won't be destroyed
			Volume = Math.Clamp((float) volume, 0.0f, 2.0f);

			if(asioSampleProvider != null) {

				/*asioSampleProvider.MixerInputs.ToList()
					.FindAll((ISampleProvider provider) => provider is TileSampleProvider)
					.Cast<TileSampleProvider>().ToList()
					.ForEach((TileSampleProvider provider) => SetTileVolume(provider));*/

				asioSampleProvider.MixerInputs.ToList().ForEach((provider) => {

					if(provider is VolumeSampleProvider volumeSampleprovider) {

						volumeSampleprovider.SetVolume(Volume);

					}

				});

			}

		}

		/// <summary>
		/// Sets the volume of an individual tile.
		/// </summary>
		/// <param name="provider">TileSampleProvider that holds the reference to desired tile.</param>
		//private void SetTileVolume(TileSampleProvider provider) => provider.Volume = Volume * provider.Tile.Volume;

		/// <summary>
		/// Gets an array containing available ASIO devices.
		/// </summary>
		/// <returns>An array containing the handles of audio devices, available in this PC.</returns>
		public static string[] GetASIODevices() => AsioOut.GetDriverNames();

		/// <summary>
		/// Plays a sound clip, referenced in a specific Tile.
		/// </summary>
		/// <param name="id">The id of the tile, that holds the path to a sound clip.</param>
		/*public void PlayTileById(string? id) {

			Tile tile = Soundboard.Tiles.Where((Tile tile) => tile.Id.Equals(id)).First();

			PlayFile(tile.File, tile);

		}*/

		/// <summary>
		/// Plays a sound clip located at a specific path.
		/// </summary>
		/// <param name="file">The path to the file.</param>
		/// <param name="tile">Optional reference to the Tile that was clicked. If provided, makes it possible to change the volume of this sound.</param>
		public void PlayFile(string? file, float volume = 1) {

			logger.LogInformation("Preparing to play audio file: {}", file);

			if(asioOut != null) {

				AudioFileReader? source = ValidateFile(file, () => OnFileError?.Invoke(this, new FileErrorEventArgs() {

					Error = "FILE NOT FOUND",
					Description = "Make sure the requested file is present on your device",
					File = file

				}), () => OnFileResampleNeeded?.Invoke(this, new FileResampleEventArgs() {

					Error = "INVALID SAMPLE RATE",
					Description = "This file uses unsupported sample rate. Do you want to fix it? (Original file won't be changed)",
					File = file,
					SampleRate = SampleRate

				}));

				if(source != null) {

					logger.LogInformation("Playing audio file: {}", file);

					asioSampleProvider!.AddMixerInput(new VolumeSampleProvider(source, volume));

				}

			}

			else {

				OnError?.Invoke(this, new ErrorEventArgs() {

					Error = "ENGINE IS STOPPED",
					Description = "You need to start the Audio Engine before playing audio files"

				});

			}

		}

		/// <summary>
		/// Resamples a file and saves it as .wav with the same name in the same folder.
		/// </summary>
		/// <param name="file">A path to the file to be resampled.</param>
		/// <param name="sampleRate">Target sample rate.</param>
		public void ResampleFile(string? file, int sampleRate) {

			if(File.Exists(file)) {

				FileInfo fileInfo = new(file);

				using AudioFileReader reader = new(file);

				WaveFormat outFormat = new(sampleRate, reader.WaveFormat.Channels);
				
				using MediaFoundationResampler resampler = new(reader, outFormat);

				WaveFileWriter.CreateWaveFile(fileInfo.FullName.Replace(fileInfo.Extension, ".wav"), resampler);

				//After the file was saved, opens a new Explorer window and points it to the folder. Might be unwanted so I will probably add a toggle to disable this in the future.
				Process.Start("explorer.exe", Path.GetDirectoryName(file)!);

			}

			else {

				OnFileError?.Invoke(this, new FileErrorEventArgs() {

					Error = "FILE NOT FOUND",
					Description = "Make sure the requested file is present on your device",
					File = file

				});

			}

		}

		/// <summary>
		/// Clears all currently playing clips.
		/// </summary>
		public void StopAllSounds() {

			if(asioSampleProvider != null) {

				asioSampleProvider.RemoveAllMixerInputs();

			}

		}

		/// <summary>
		/// Starts up the Audio Engine. If it is currently active, disposes it first, making the process a restart.
		/// </summary>
		public void InitialiseASIO() {

			DisposeASIO();

			if(GetASIODevices().Contains(AudioDevice)) {

				Application.Current.Dispatcher.Invoke(() => {

					asioOut = new AsioOut(AudioDevice);

					if(asioOut.IsSampleRateSupported(SampleRate)) {

						asioSampleProvider = new(WaveFormat.CreateIeeeFloatWaveFormat(SampleRate, 2)) {
							
							//I have no idea why this is here, but it is probably important
							ReadFully = true

						};

						asioOut.Init(asioSampleProvider);
						asioOut.Play();

						logger.LogInformation("Audio Engine started");

						OnAudioEngineStatus?.Invoke(this, new AudioEngineStatusEventArgs() { Active = true });

					}

					else {

						OnError?.Invoke(this, new ErrorEventArgs() {

							Error = "SAMPLE RATE NOT SUPPORTED",
							Description = "The Audio Device you selected doesn't support current sample rate"

						});

						DisposeASIO();

					}

				});

			}

			else {

				OnError?.Invoke(this, new ErrorEventArgs() {

					Error = "DEVICE NOT FOUND",
					Description = "The Audio Device you intend to use for the Audio Engine was not found on your PC"

				});

			}

		}

		/// <summary>
		/// Destroys the Audio Engine.
		/// </summary>
		public void DisposeASIO() {

			if(asioOut != null) {

				asioOut.Dispose();
				asioOut = null;
				asioSampleProvider = null;

				logger.LogInformation("Audio Engine stopped");

				OnAudioEngineStatus?.Invoke(this, new AudioEngineStatusEventArgs() { Active = false });

			}

		}

		/// <summary>
		/// Checks if the file can be played through the soundboard and loads it if possible.
		/// </summary>
		/// <param name="file">The path to the file.</param>
		/// <param name="notFound">Called if the file is missing.</param>
		/// <param name="invalidSampleRate">Called if file's sample doesn't match the preffered one.</param>
		/// <returns><c>null</c> if the file could not be loaded, otherwise the <c>AudioFileReader</c> created from the file.</returns>
		private AudioFileReader? ValidateFile(string? file, Action notFound, Action invalidSampleRate) {

			logger.LogInformation("Validating audio file: {}", file);
			
			if(File.Exists(file)) {

				AudioFileReader reader = new(file);

				if(reader.WaveFormat.SampleRate != SampleRate) {

					logger.LogInformation("Audio file uses invalid sample rate: {}", reader.WaveFormat.SampleRate);

					invalidSampleRate?.Invoke();

				}
				
				else {

					return reader;

				}

				reader.Dispose();

			}

			else {

				notFound?.Invoke();

			}

			return null;

		}

		public class AudioEngineStatusEventArgs : EventArgs {

			[JsonPropertyName("active")]
			public bool Active { get; set; }

		}

		public class ErrorEventArgs : EventArgs {

			[JsonPropertyName("error")]
			public string Error { get; set; } = "GENERIC ERROR";
			[JsonPropertyName("description")]
			public string? Description { get; set; }

		}

		public class FileErrorEventArgs : ErrorEventArgs {

			[JsonPropertyName("file")]
			public string? File { get; set; }

		}

		public class FileResampleEventArgs : FileErrorEventArgs {

			[JsonPropertyName("sample_rate")]
			public int SampleRate { get; set; }
		
		}

	}

}