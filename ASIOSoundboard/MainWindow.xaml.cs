using Microsoft.Web.WebView2.Core;
using System;
using System.Windows;

namespace ASIOSoundboard {

	public partial class MainWindow : Window {

		public MainWindow(bool noFlutter) {

			InitializeComponent();

			//If the --no-flutter flag was not found, open the UI
			if(!noFlutter) {

				//Wait till Edge is initialized, then disable the right-click menu and DevTools
				WebView.CoreWebView2InitializationCompleted += (object? sender, CoreWebView2InitializationCompletedEventArgs args) => {

					WebView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
					WebView.CoreWebView2.Settings.AreDevToolsEnabled = false;

				};

				WebView.Source = new Uri("http://localhost:29873/");

			}

		}

	}

}