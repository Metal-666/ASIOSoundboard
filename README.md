# ASIO Soundboard

This is a simple soundboard app built using C# and Flutter. Lets you play audio clips into any ASIO device using hotkeys. Recommended to use together with [AutoHotkey](https://www.autohotkey.com/) and [JackRouter](https://jackaudio.org/faq/jack_on_windows.html).

| Board                                            | Settings                                               |
| ------------------------------------------------ | ------------------------------------------------------ |
| ![screenshot_board](img/screenshots/board_1.png) | ![screenshot_settings](img/screenshots/settings_1.png) |

## Features

- Save/load soundboard from a file
- Trigger sounds from AHK scripts (or by using http requests)
- Resample audio files to match your audio card settings
- Change volume for the whole app or each individual sound
- Adjust the UI to your preference
- *More features coming in the future...*

## Installation and Usage

- Download the [latest release](../../releases/latest)
- Unzip the archive
- Launch the app

When the app is running, go to Settings and select an Audio Device you want to use for playback. Then select the Sample Rate your device is working at (to set or see your device's sample rate, find and open its control panel). After that hit the Start button at the top-right of the app window. If everything is done correctly, the text in top-left will say that the Audio Engine is working. You can hit the button again to stop it at any time. Now you can actually play the sounds by navigating to Board and hitting the + button in bottom-right. Use the dialog to add a sound, when done click the tile that just appeared and you will hear the sound you selected. You can also right-click the tile to open its menu.
    
## Building

- Clone the repository
- Make sure `main` or `beta` branch is selected
- Make sure you have the latest Flutter SDK and .NET 6 installed
- Open the 'flutter-ui' directory in VS Code or something similar and restore project dependencies
- Open C# solution
- Now you have 2 options:
  - If you want to debug the app:
    - Set C# project configuration to 'Debug' and launch profile to 'no-ui'
    - Start debugging
    - Go to the Flutter project and start debugging it too
  - If you want to build the release version:
    - Set C# project configuration to 'Release'
    - Build the C# app
    - Go to the Flutter project and run `flutter build windows`
    - Copy and paste generated files to the 'flutter-ui' folder alongside the C# executable that you built earlier

## Guides

I will update this section with links to this repo's wiki, where I will describe how to set up AHK, JackRouter and maybe some other stuff.