#NoEnv
#Warn
SetWorkingDir %A_ScriptDir%

global controllerUrl := "http://localhost:29873/controller"
global controllerHTTP := ComObjCreate("WinHttp.Winhttprequest.5.1")

PlaySoundByName(name) {
    controllerHTTP.open("GET", controllerUrl "/play/byName/" name)
    controllerHTTP.send()
}

StopAllSounds() {
    controllerHTTP.open("GET", controllerUrl "/stopAll")
    controllerHTTP.send()
}