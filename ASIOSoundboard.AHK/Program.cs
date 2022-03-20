using System.Net.Http;
using System.Windows;

namespace ASIOSoundboard.AHK {

	public class Program {

		private const string SERVER_URL = "http://localhost:29873/controller/public/";

		public static void Main(string[] args) => MainAsync(args).GetAwaiter().GetResult();

		private static async Task MainAsync(string[] args) {

			if(args.Length == 0) {

				MessageBox.Show("Please use one of the following commands when starting the app:\n" +
				"play \"<path/to/file>\" <volume>\n" +
				"stop");

			}

			else {

				switch(args[0]) {

					case "play": {

						if(args.Length < 3 || !float.TryParse(args[2], out _)) {

							MessageBox.Show("Malformed \"play\" command. Run app without parameters to see the correct syntax.");

						}

						else {

							await PostRequest("play", new Dictionary<string, string>() {

								{ "file", args[1] },
								{ "volume", args[2] }

							});

						}

						break;

					}

					case "request-play": {

						if(args.Length < 2) {

							MessageBox.Show("Malformed \"request-play\" command. Run app without parameters to see the correct syntax.");

						}

						else {

							await PostRequest("request-play", new Dictionary<string, string>() {

								{ "name", args[1] }

							});

						}

						break;

					}

					case "stop": {

						await PostRequest("stop");

						break;

					}

					default: {

						MessageBox.Show("Unknown command. Run without parameters to see available commands.");

						break;

					}

				}

			}

		}

		private static async Task PostRequest(string path, Dictionary<string, string>? form = null) {

			HttpClient client = new();

			await client.PostAsync(SERVER_URL + path, form == null ? null : new FormUrlEncodedContent(form));

			client.Dispose();

		}

	}

}