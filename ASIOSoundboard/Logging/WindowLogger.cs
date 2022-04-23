using Microsoft.Extensions.Logging;
using System;

namespace ASIOSoundboard.Logging {

	public sealed class WindowLogger : ILogger {

		private readonly string _name;
		private readonly Func<WindowLoggerConfiguration> _getCurrentConfig;

		public WindowLogger(string name, Func<WindowLoggerConfiguration> getCurrentConfig) => (_name, _getCurrentConfig) = (name, getCurrentConfig);

		public IDisposable BeginScope<TState>(TState state) => default!;

		public bool IsEnabled(LogLevel logLevel) => true;

		public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) {
			
			_getCurrentConfig().MainWindow?.WriteLine(logLevel, formatter(state, exception));

		}
	}

}
