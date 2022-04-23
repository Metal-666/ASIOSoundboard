using Microsoft.Extensions.Logging;
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace ASIOSoundboard {

	public partial class MainWindow : Window {

		// Why is this not a standard property on a Window class??
		public bool isClosed = false;

		public MainWindow() {

			InitializeComponent();

		}

		public void WriteLine(LogLevel logLevel, string text) {

			// Sometimes logs can be printed when the Host is already shutting down and this window is closed
			// If that's the case - don't print anything
			if(isClosed) {

				return;
			
			}

			Dispatcher.Invoke(() => {

				MenuItem copyButton = new() {

					Header = "Copy"

				};

				copyButton.Click += (sender, e) => {

					Clipboard.SetText(text);

				};

				LogContainer.Items.Add(new ListViewItem() {

					ContextMenu = new ContextMenu() {

						Items = {

							copyButton

						}

					},
					Content = text,
					Foreground = new SolidColorBrush(LogLevelToColor(logLevel))

				});

			});

		}

		public static Color LogLevelToColor(LogLevel logLevel) {

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