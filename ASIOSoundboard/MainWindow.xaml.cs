using Microsoft.Extensions.Logging;
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace ASIOSoundboard {

	public partial class MainWindow : Window {

		public bool isClosed = false;

		public MainWindow() {

			InitializeComponent();

		}

		public void WriteLine(LogLevel logLevel, string text) {

			if(!isClosed) {

				Dispatcher.Invoke(() => LogContainer.Items.Add(new ListViewItem() {

					Content = text,
					Foreground = new SolidColorBrush(LogLevelToColor(logLevel))

				}));

			}

		}

		public Color LogLevelToColor(LogLevel logLevel) {

			switch(logLevel) {

				case LogLevel.Debug: {

					return Colors.Gray;

				}

				case LogLevel.Warning: {

					return Colors.Yellow;

				}

				case LogLevel.Error: {

					return Colors.Red;

				}

				case LogLevel.Critical: {

					return Colors.DarkRed;
				
				}

				default: {

					return Colors.White;

				}

			}

		}

		private void OnClosed(object sender, EventArgs e) {

			isClosed = true;

		}

		private void OnStartStopUI(object sender, RoutedEventArgs e) {

			((App) Application.Current).ToggleUI();

		}

	}

}