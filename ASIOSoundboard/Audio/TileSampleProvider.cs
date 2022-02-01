using NAudio.Wave;
using static ASIOSoundboard.Audio.Soundboard;

namespace ASIOSoundboard.Audio {

	/// <summary>
	/// A wrapper class for <c>AudioFileReader</c> that also specifies the Tile this provider was created from.
	/// </summary>
	public class TileSampleProvider : ISampleProvider {

		private readonly AudioFileReader _source;

		/// <summary>
		/// Tile that provides the playback info, such as file path and volume.
		/// </summary>
		public Tile Tile { get; set; }

		/// <summary>
		/// This property should be set when we want to change the volume of this provider.
		/// </summary>
		public float Volume {
		
			get {
		
				return _source.Volume; 
		
			}
			
			set {
		
				_source.Volume = value;
		
			}
			
		}

		/// <summary>
		/// Returns the <c>WaveFormat</c> of the underlying sample provider.
		/// </summary>
		public WaveFormat WaveFormat => _source.WaveFormat;

		public TileSampleProvider(AudioFileReader source, Tile tile) {
		
			_source = source;
			Tile = tile;
		
		}

		/// <summary>
		/// Reads audio from this sample provider.
		/// </summary>
		/// <param name="buffer"></param>
		/// <param name="offset"></param>
		/// <param name="count"></param>
		/// <returns>Number of samples read.</returns>
		public int Read(float[] buffer, int offset, int count) => _source.Read(buffer, offset, count);

	}

}