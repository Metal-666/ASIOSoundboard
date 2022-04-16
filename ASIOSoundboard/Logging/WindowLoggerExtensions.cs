using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Configuration;
using System;

namespace ASIOSoundboard.Logging {

	public static class WindowLoggerExtensions {

		public static ILoggingBuilder AddWindowLogger(this ILoggingBuilder builder) {

			builder.AddConfiguration();

			builder.Services.TryAddEnumerable(ServiceDescriptor.Singleton<ILoggerProvider, WindowLoggerProvider>());

			LoggerProviderOptions.RegisterProviderOptions<WindowLoggerConfiguration, WindowLoggerProvider>(builder.Services);

			return builder;

		}

		public static ILoggingBuilder AddWindowLogger(this ILoggingBuilder builder, Action<WindowLoggerConfiguration> configure) {

			builder.AddWindowLogger();
			builder.Services.Configure(configure);

			return builder;

		}

	}

}