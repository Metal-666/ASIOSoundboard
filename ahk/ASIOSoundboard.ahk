#NoEnv
#Include WinHttpRequest.ahk

global endpoint := "http://localhost:29873/controller/public"

Play(file, volume) {
	body := {}
	body.file := file
	body.volume := volume

	new WinHttpRequest().post(endpoint . "/play", body)
}

RequestPlay(name) {
	body := {}
	body.name := name

	new WinHttpRequest().post(endpoint . "/request-play", body)
}

Stop() {
	new WinHttpRequest().post(endpoint . "/stop", body)
}