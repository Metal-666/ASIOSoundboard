using NAudio.Wave;

namespace ASIOSoundboard.Audio {

	/// <summary>
	/// A wrapper class for <c>AudioFileReader</c> that also specifies the Tile this provider was created from.
	/// </summary>
	public class VolumeSampleProvider : ISampleProvider {

		private readonly AudioFileReader source;

		/// <summary>
		/// Tile that provides the playback info, such as file path and volume.
		/// </summary>
		private readonly float volume;

		/// <summary>
		/// Returns the <c>WaveFormat</c> of the underlying sample provider.
		/// </summary>
		public WaveFormat WaveFormat => source.WaveFormat;

		public VolumeSampleProvider(AudioFileReader source, float volume) {
		
			this.source = source;
			this.volume = volume;
		
		}

		public void SetVolume(float globalVolume) => source.Volume = volume * globalVolume;

		/// <summary>
		/// Reads audio from this sample provider.
		/// </summary>
		/// <param name="buffer"></param>
		/// <param name="offset"></param>
		/// <param name="count"></param>
		/// <returns>Number of samples read.</returns>
		public int Read(float[] buffer, int offset, int count) => source.Read(buffer, offset, count);

	}

}