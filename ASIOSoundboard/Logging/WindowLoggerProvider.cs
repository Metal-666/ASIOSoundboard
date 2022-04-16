using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Concurrent;

namespace ASIOSoundboard.Logging {

	[ProviderAlias("Window")]
	public sealed class WindowLoggerProvider : ILoggerProvider {

		private readonly IDisposable _onChangeToken;
		private WindowLoggerConfiguration _currentConfig;
		private readonly ConcurrentDictionary<string, WindowLogger> _loggers =
			new(StringComparer.OrdinalIgnoreCase);

		public WindowLoggerProvider(IOptionsMonitor<WindowLoggerConfiguration> config) {

			_currentConfig = config.CurrentValue;
			_onChangeToken = config.OnChange(updatedConfig => _currentConfig = updatedConfig);

		}

		public ILogger CreateLogger(string categoryName) => _loggers.GetOrAdd(categoryName, name => new WindowLogger(name, GetCurrentConfig));

		private WindowLoggerConfiguration GetCurrentConfig() => _currentConfig;

		public void Dispose() {

			_loggers.Clear();
			_onChangeToken.Dispose();

		}

	}

}
