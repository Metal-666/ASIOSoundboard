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

		private readonly ILogger<AudioManager> logger;

		public event EventHandler<AudioEngineStatusEventArgs>? OnAudioEngineStatus;
		public event EventHandler<ErrorEventArgs>? OnError;
		public event EventHandler<FileErrorEventArgs>? OnFileError;
		public event EventHandler<FileResampleEventArgs>? OnFileResampleNeeded;

		private AsioOut? asioOut;
		private MixingSampleProvider? mixingSampleProvider;
		private VolumeSampleProvider? volumeSampleProvider;

		public AudioManager(ILogger<AudioManager> logger) => this.logger = logger;

		public void AudioEngineStatus() => OnAudioEngineStatus?.Invoke(this, new AudioEngineStatusEventArgs() {

			Active = asioOut != null,

		});

		public void StartAudioEngine(string? audioDevice, int? sampleRate, float? volume) {

			if(asioOut != null) {

				OnError?.Invoke(this, new ErrorEventArgs() {

					Error = ErrorEventArgs.CANT_START_AUDIO_ENGINE,
					Description = "Audio Engine is already running"

				});
			
			}

			else if(audioDevice == null) {

				OnError?.Invoke(this, new ErrorEventArgs() {

					Error = ErrorEventArgs.CANT_START_AUDIO_ENGINE,
					Description = "Audio Device not set"

				});

			}

			else if(sampleRate == null) {

				OnError?.Invoke(this, new ErrorEventArgs() {

					Error = ErrorEventArgs.CANT_START_AUDIO_ENGINE,
					Description = "Sample Rate not set"

				});

			}

			else if(GetASIODevices().Contains(audioDevice)) {

				Application.Current.Dispatcher.Invoke(() => {

					try {

						asioOut = new AsioOut(audioDevice);

						if(asioOut.IsSampleRateSupported((int) sampleRate)) {

							mixingSampleProvider = new(WaveFormat.CreateIeeeFloatWaveFormat((int) sampleRate, 2)) {

								//I have no idea why this is here, but it is probably important
								ReadFully = true

							};

							volumeSampleProvider = new(mixingSampleProvider) {

								Volume = volume ?? 1

							};

							asioOut.Init(volumeSampleProvider);
							asioOut.Play();

							logger.LogInformation("Audio Engine started");

							AudioEngineStatus();

						}

						else {

							OnError?.Invoke(this, new ErrorEventArgs() {

								Error = ErrorEventArgs.CANT_START_AUDIO_ENGINE,
								Description = $"Selected Sample Rate is unsupported by {audioDevice}"

							});

							Dispose();

						}

					}

					catch(Exception e) {

						OnError?.Invoke(this, new ErrorEventArgs() {

							Error = ErrorEventArgs.CANT_START_AUDIO_ENGINE,
							Description = e.Message

						});

						Dispose();

					}

				});

			}

			else {

				OnError?.Invoke(this, new ErrorEventArgs() {

					Error = ErrorEventArgs.CANT_START_AUDIO_ENGINE,
					Description = "Selected Audio Device can't be found"

				});

			}

		}

		public void StopAudioEngine() {

			Dispose();

		}

		/// <summary>
		/// Sets the volume of the soundboard.
		/// </summary>
		/// <param name="volume">Desired volume.</param>
		public void SetGlobalVolume(double volume) {

			if(volumeSampleProvider != null) {

				volumeSampleProvider.Volume = TransformVolume((float) volume);

			}

		}

		/// <summary>
		/// Gets an array containing available ASIO devices.
		/// </summary>
		/// <returns>An array containing the handles of audio devices, available in this PC.</returns>
		public static string[] GetASIODevices() => AsioOut.GetDriverNames();

		/// <summary>
		/// Plays a sound clip located at a specific path.
		/// </summary>
		/// <param name="file">The path to the file.</param>
		/// <param name="tile">Optional reference to the Tile that was clicked. If provided, makes it possible to change the volume of this sound.</param>
		public void PlayFile(string? file, float volume = 1) {

			logger.LogInformation("Preparing to play audio file: {}", file);

			if(asioOut != null) {

				AudioFileReader? source = ValidateAudioFile(file, () => OnFileError?.Invoke(this, new FileErrorEventArgs() {

					Error = FileErrorEventArgs.FILE_NOT_FOUND,
					Description = "Make sure the requested file is present on your device",
					File = file

				}), (sampleRate) => OnFileResampleNeeded?.Invoke(this, new FileResampleEventArgs() {

					Error = "INVALID SAMPLE RATE",
					Description = "This file uses unsupported sample rate. Do you want to fix it? (Original file won't be changed)",
					File = file,
					SampleRate = sampleRate

				}));

				if(source != null) {

					source.Volume = TransformVolume(volume);

					logger.LogInformation("Playing audio file: {}", file);

					mixingSampleProvider!.AddMixerInput((ISampleProvider) source);

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

					Error = FileErrorEventArgs.FILE_NOT_FOUND,
					Description = "Make sure the requested file is present on your device",
					File = file

				});

			}

		}

		/// <summary>
		/// Clears all currently playing clips.
		/// </summary>
		public void StopAllSounds() {

			if(mixingSampleProvider != null) {

				mixingSampleProvider.RemoveAllMixerInputs();

			}

		}

		/// <summary>
		/// Destroys the Audio Engine.
		/// </summary>
		public void Dispose() {

			if(asioOut != null) {

				asioOut.Dispose();
				asioOut = null;

			}

			mixingSampleProvider = null;
			volumeSampleProvider = null;

			logger.LogInformation("Audio Engine stopped");

			AudioEngineStatus();

		}

		/// <summary>
		/// Checks if the file can be played through the soundboard and loads it if possible.
		/// </summary>
		/// <param name="file">The path to the file.</param>
		/// <param name="notFound">Called if the file is missing.</param>
		/// <param name="invalidSampleRate">Called if file's sample doesn't match the preffered one.</param>
		/// <returns><c>null</c> if the file could not be loaded, otherwise the <c>AudioFileReader</c> created from the file.</returns>
		private AudioFileReader? ValidateAudioFile(string? file, Action notFound, Action<int> invalidSampleRate) {

			logger.LogInformation("Validating audio file: {}", file);
			
			if(File.Exists(file)) {

				AudioFileReader reader = new(file);

				if(reader.WaveFormat.SampleRate != mixingSampleProvider?.WaveFormat.SampleRate) {

					logger.LogInformation("Audio file uses invalid sample rate: {}", reader.WaveFormat.SampleRate);

					invalidSampleRate?.Invoke(mixingSampleProvider?.WaveFormat.SampleRate ?? -1);

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

		private static float TransformVolume(float volume) {

			volume = Math.Clamp(volume, 0.0f, 2.0f);

			return (float) (1.7 * Math.Pow(volume, 1.8) - Math.Pow(volume, 1.6));

		}

		public class AudioEngineStatusEventArgs : EventArgs {

			[JsonPropertyName("active")]
			public bool Active { get; set; }

		}

		public class ErrorEventArgs : EventArgs {

			public const string CANT_START_AUDIO_ENGINE = "CAN'T START AUDIO ENGINE";

			[JsonPropertyName("error")]
			public string Error { get; set; } = "GENERIC ERROR";
			[JsonPropertyName("description")]
			public string? Description { get; set; }

		}

		public class FileErrorEventArgs : ErrorEventArgs {

			public const string FILE_NOT_FOUND = "FILE NOT FOUND";

			[JsonPropertyName("file")]
			public string? File { get; set; }

		}

		public class FileResampleEventArgs : FileErrorEventArgs {

			[JsonPropertyName("sample_rate")]
			public int SampleRate { get; set; }
		
		}

	}

}