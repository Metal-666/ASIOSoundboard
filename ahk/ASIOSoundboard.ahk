#NoEnv
#Warn
SetWorkingDir %A_ScriptDir%

global exePath = "ASIOSoundboard.AHK.exe"

PlaySoundByName(name) {
    Run %exePath% play %name%
}

StopAllSounds() {
    Run %exePath% stop
}