#NoEnv
#Warn

global exePath = A_LineFile "/../ASIOSoundboard.AHK.exe"

RequestPlay(name) {
    Run %exePath% request-play %name%
}

StopAllSounds() {
    Run %exePath% stop
}