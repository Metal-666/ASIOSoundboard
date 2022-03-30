
; Version: 2022.02.05.1
; Usage and examples: https://redd.it/mcjj4s

WinHttpRequest(Parameters*)
{
	static instance := ""
	if !IsObject(instance)
		instance := new WinHttpRequest(Parameters*)
	return instance
}

class WinHttpRequest extends WinHttpRequestFactory
{

	class MIME ; const
	{
		static gif := "image/gif"
			, jpg := "image/jpeg"
			, json := "application/json"
			, mp4 := "video/mp4"
			, png := "image/png"
			, zip := "application/zip"
	}

	Encoding[]
	{
		get {
			return this._encoding
		}
		set {
			return this._encoding := value
		}
	}

	; Identical to JS counterpart
	EncodeUri(Uri, Encoding := "UTF-8")
	{
		Encoding := this._encoding ? this._encoding : Encoding
		return this._Encode(Uri, Encoding, "[!#$&-;=?-Z_a-z~]")
	}

	; Identical to JS counterpart
	EncodeUriComponent(Uri, Encoding := "UTF-8")
	{
		Encoding := this._encoding ? this._encoding : Encoding
		return this._Encode(Uri, Encoding, "[!'-*-\.0-9A-Z_a-z~]")
	}

	; Identical to JS counterpart
	DecodeUri(Uri, Encoding := "UTF-8")
	{
		Encoding := this._encoding ? this._encoding : Encoding
		return this._Decode(Uri, Encoding)
	}

	; Identical to JS counterpart
	DecodeUriComponent(Uri, Encoding := "UTF-8")
	{
		Encoding := this._encoding ? this._encoding : Encoding
		return this._Decode(Uri, Encoding)
	}

	ObjToQuery(Object)
	{
		if !IsObject(Object)
			return Object
		out := ""
		for key,val in Object {
			key := this.EncodeUriComponent(key)
			val := this.EncodeUriComponent(val)
			out .= key "=" val "&"
		}
		return RTrim(out, "&")
	}

	Reset()
	{
		this.__New()
	}

	; Private

	_Encode(String, Encoding, Regex)
	{
		out := ""
		strLen := StrPut(String, Encoding)
		VarSetCapacity(var, strLen * 2, 0)
		StrPut(String, &var, Encoding)
		while code := NumGet(var, A_Index - 1, "UChar") {
			chr := Chr(code)
			out .= chr ~= Regex ? chr : Format("%{:02x}", code)
		}
		return out
	}

	_Decode(String, Encoding)
	{
		p := 1
		VarSetCapacity(var, 5, 0)
		while p := InStr(String, "%",, p) {
			hex := SubStr(String, ++p, 2)
			NumPut("0x" hex, var, 0, "UChar")
			chr := StrGet(&var, Encoding)
			String := StrReplace(String, "%" hex, chr)
		}
		return String
	}

	_MultiPart(ByRef Body)
	{
		this._memLen := 0
		this._memPtr := DllCall("GlobalAlloc", "Int",0x0040, "Int",1)
		boundary := "----------WinHttpRequest-" A_NowUTC A_MSec "`r`n"

		; Convention, but not required. See https://bit.ly/3otfjCC
		; this._StrPut(boundary "Content-Disposition: form-data;"
		; 	. " name=""_charset_""`r`n`r`n" this._encoding "`r`n")

		for field,value in Body
			this._MultiPartAdd(boundary, field, value)
		boundary := SubStr(boundary, 3, -2)
		this._StrPut("--" boundary "--`r`n")
		Body := ComObjArray(0x11, this._memLen)
		pvData := NumGet(ComObjValue(Body) + A_PtrSize + 8)
		DllCall("Ntdll\RtlMoveMemory"
			, "Ptr",pvData
			, "Ptr",this._memPtr
			, "Ptr",this._memLen)
		this._memPtr := DllCall("GlobalFree", "Ptr",this._memPtr)
		return boundary
	}

	_MultiPartAdd(Boundary, Field, Value)
	{
		if !IsObject(Value) {
			str := Boundary "Content-Disposition: form-data; "
			str .= "name=""" Field """`r`n`r`n" Value "`r`n"
			this._StrPut(str)
			return
		}
		for _,path in Value {
			SplitPath path, file,, ext
			mime := this.MIME.HasKey(ext) ? this.MIME[ext] : -1
			mime := mime = -1 ? "application/octet-stream" : mime
			str := Boundary "Content-Disposition: form-data; "
			str .= "name=""" Field """; filename=""" file """"
			str .= "`r`nContent-Type: " mime "`r`n`r`n"
			this._StrPut(str)
			this._MultipartFile(path)
			this._StrPut("`r`n")
		}
	}

	_MultipartFile(Path)
	{
		fileObj := FileOpen(Path, 0x0)
		if (!fileObj || !fileObj.length) {
			MsgBox 0x40010, Error, % "Invalid file:`n`n" Path
			Exit
		}
		this._memLen += fileObj.Length
		this._memPtr := DllCall("Kernel32\GlobalReAlloc"
			, "Ptr",this._memPtr
			, "Int",this._memLen
			, "Int",0x0042) ; GMEM_ZEROINIT | GMEM_MOVEABLE
		offset := this._memLen - fileObj.length
		fileObj.RawRead(this._memPtr + offset, fileObj.length)
	}

	_Post(ByRef Body, ByRef Headers, Options)
	{
		multipart := 0
		for _,value in Body
			multipart += !!IsObject(value)

		if (multipart || (IsObject(Body) && Options.multipart)) {
			boundary := this._MultiPart(Body)
			contType := "multipart/form-data; boundary=" boundary
		} else {
			Body := this.ObjToQuery(Body)
			contType := "application/x-www-form-urlencoded"
		}
		if !Headers.HasKey("Content-Type")
			Headers["Content-Type"] := contType
	}

	_Response()
	{
		try {
			out := this._whr.ResponseText
			return out
		}
		out := ""
		for char in this._whr.ResponseBody
			out .= Chr(char)
		return out
	}

	_Save(Target)
	{
		; https://www.pinvoke.net/default.aspx/Interfaces/IStream.html
		ptsm := ComObjQuery(this._whr.ResponseStream
			, "{0000000c-0000-0000-C000-000000000046}")
		fileObj := FileOpen(Target, 0x1)
		if (!fileObj)
			throw Exception("Cannot save to file.", -1, Target)

		cb := 8192
		pcbRead := ""
		IStreamRead := NumGet(NumGet(ptsm + 0) + 3 * A_PtrSize)
		while (pcbRead != 0) {
			VarSetCapacity(pv, cb, 0)
			DllCall(IStreamRead
				, "Ptr",ptsm
				, "Ptr",&pv
				, "UInt",cb
				, "Ptr*",pcbRead)
			fileObj.RawWrite(&pv, pcbRead)
		}
		ObjRelease(ptsm)
		fileObj.close()
	}

	_StrPut(String)
	{
		size := StrPut(String, this._encoding) - 1
		this._memLen += size
		this._memPtr := DllCall("Kernel32\GlobalReAlloc"
			, "Ptr",this._memPtr
			, "Ptr",this._memLen + 1
			, "Ptr",0x0042) ; GMEM_ZEROINIT|GMEM_MOVEABLE
		target := this._memPtr + this._memLen - size
		StrPut(String, target, size, this._encoding)
	}

}

class WinHttpRequestFactory
{

	_reset := false
	_encoding := "UTF-8"

	__New(Options := false)
	{
		if !IsObject(Options)
			Options := {}

		this._whr := "" ; Release previous reference if exist
		this._whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

		if (Options.HasKey("cookies") && !Options.cookies)
			this._reset := true

		if (!Options.proxy) {
			this._whr.SetProxy(HTTPREQUEST.PROXYSETTING_DEFAULT)
		} else if (Options.proxy = "DIRECT") {
			this._whr.SetProxy(HTTPREQUEST.PROXYSETTING_DIRECT)
		} else {
			val := Options.proxy
			this._whr.SetProxy(HTTPREQUEST.PROXYSETTING_PROXY, val)
		}

		if (Options.UA) {
			ua := Options.UA
		} else {
			RegExMatch(A_OSVersion, "^\d+\.\d+", ver)
			ua := "AHK/1.1 (Windows NT " ver
			ua .= "; Win" (A_Is64bitOS ? "64" : "32")
			ua .= "; x" (A_PtrSize = 8 ? "64" : "86")
			ua .= "; rv:" A_AhkVersion ")"
		}
		this._whr.Option(WinHttpRequestOption.UserAgentString) := ua

		/* Protocols
			0x008 SSL2
			0x020 SSL3
			0x080 TLS1.0
			0x200 TLS1.1
			0x800 TLS1.2
		*/
		; 0xA00 = TLS1.1 | TLS1.2, see https://bit.ly/3FmNnXT
		this._whr.Option(WinHttpRequestOption.SecureProtocols) := 0xA00

		/* SSL Flags
			0x0100 Unknown CA / Untrusted root
			0x0200 Wrong usage
			0x1000 Invalid CN
			0x2000 Invalid date / Certificate expired
		*/
		if (!Options.verifySSL) {
			opt := WinHttpRequestOption.SslErrorIgnoreFlags
			this._whr.Option(opt) := 0x0100|0x0200|0x1000|0x2000
		}
	}

	__Call(Method, Url, Body := "", Headers := false, Options := false)
	{
		if (!this._whr)
			throw Exception("Not instantiated.", -1)

		Method := Format("{:U}", Method) ; CONNECT not supported
		if Method not in DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT,TRACE
			throw Exception("Invalid HTTP verb.", -1, Method)

		Headers := IsObject(Headers) ? Headers : {}
		Options := IsObject(Options) ? Options : {}

		Url := this.EncodeUri(Url, "UTF-8")

		if (Method = "POST") {
			this._Post(Body, Headers, Options)
		} else if (Method = "GET" && Body) {
			Url := RTrim(Url, " &")
			Url .= InStr(Url, "?") ? "&" : "?"
			Url .= this.ObjToQuery(Body)
			Body := ""
		}

		this._whr.Open(Method, Url, true)
		for key,val in Headers
			this._whr.SetRequestHeader(key, val)

		if (Body)
			this._whr.Send(Body)
		else
			this._whr.Send()

		this._whr.WaitForResponse()

		if (Options.Save) {
			this._Save(Options.Save)
			return
		}

		response := this._Response()

		if (!Options.object)
			return response, (this._reset ? this.__New() : "")

		out := {}
		headers := this._whr.GetAllResponseHeaders()
		/*loop parse, % RTrim(headers, "`r`n"), `n, `r
		{
			pair := StrSplit(A_LoopField, ":", " ", 2)
			out["Headers", pair.1] := pair[2]
		}
		*/
		headers := RTrim(headers, "`r`n")
		for _,line in StrSplit(headers, "`n", "`r") {
			pair := StrSplit(line, ":", " ", 2)
			out["Headers", pair[1]] := pair[2]
		}
		out.Status := this._whr.Status
		out.Text := response
		out.Url := this._whr.Option(WinHttpRequestOption.URL)

		return out, (this._reset ? this.__New() : "")
	}

}

class WinHttpRequestOption ; Enum
{
	static UserAgentString := 0
		, URL := 1
		, URLCodePage := 2
		, EscapePercentInURL := 3
		, SslErrorIgnoreFlags := 4
		, SelectCertificate := 5
		, EnableRedirects := 6
		, UrlEscapeDisable := 7
		, UrlEscapeDisableQuery := 8
		, SecureProtocols := 9
		, EnableTracing := 10
		, RevertImpersonationOverSsl := 11
		, EnableHttpsToHttpRedirects := 12
		, EnablePassportAuthentication := 13
		, MaxAutomaticRedirects := 14
		, MaxResponseHeaderSize := 15
		, MaxResponseDrainSize := 16
		, EnableHttp1_1 := 17
		, EnableCertificateRevocationCheck := 18
} ; https://docs.microsoft.com/windows/win32/winhttp/winhttprequestoption

class HTTPREQUEST ; const
{
	static PROXYSETTING_DEFAULT := 0
		, PROXYSETTING_PRECONFIG = 0
		, PROXYSETTING_DIRECT = 1
		, PROXYSETTING_PROXY = 2
} ; https://docs.microsoft.com/windows/win32/winhttp/iwinhttprequest-setproxy
