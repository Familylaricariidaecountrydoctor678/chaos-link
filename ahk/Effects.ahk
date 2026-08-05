#Requires AutoHotkey v2.0
#SingleInstance Off
global BlockingWasd := false

OnExit((*) => ReleaseEverything())
Hotkey("^+F12", (*) => ExitApp(2))

effectId := GetArg("--effect")
if effectId = "" {
    MsgBox("Этот скрипт запускается приложением Chaos Link Agent.")
    ExitApp
}
durationArg := GetArg("--duration")
seedArg := GetArg("--seed")
soundPath := GetArg("--sound")
imagePath := GetArg("--image")
durationMs := durationArg = "" ? 0 : Integer(durationArg)
seed := seedArg = "" ? 0 : Integer(seedArg)
ExecuteEffect(effectId, durationMs, seed, soundPath, imagePath)
ExitApp(0)

ExecuteEffect(effectId, durationMs, seed, soundPath, imagePath) {
    try {
        switch effectId {
            case "release_all": ReleaseEverything()
            case "knife": PressKnife()
            case "reload": Send("r")
            case "jump": Send("{Space}")
            case "drop_weapon": Send("g")
            case "mouse_jerk": MouseJerk(seed)
            case "hold_ctrl": HoldKey("Ctrl", Max(durationMs, 1000))
            case "block_wasd": BlockWasd(Max(durationMs, 1000))
            case "flash": FlashOverlay(Max(durationMs, 1000))
            case "screamer": ScreamerOverlay(Max(durationMs, 1000), soundPath, imagePath)
            default: throw Error("Эффект отсутствует в AHK")
        }
        WriteLog("Выполнено: " effectId)
    } catch as error {
        ReleaseEverything()
        WriteLog(error.Message)
        ExitApp(1)
    }
}

WriteLog(message) {
    try FileAppend(message, "*")
}

HoldKey(key, durationMs) {
    Send("{" key " down}")
    try Sleep(durationMs)
    finally Send("{" key " up}")
}

PressKnife() {
    cs2Window := WinExist("ahk_exe cs2.exe")
    if !cs2Window
        throw Error("Процесс cs2.exe не найден")

    if !WinActive("ahk_id " cs2Window) {
        WinActivate("ahk_id " cs2Window)
        if !WinWaitActive("ahk_id " cs2Window, , 2)
            throw Error("Не удалось активировать окно CS2")
    }

    SendInput("{vk33sc004 down}")
    Sleep(100)
    SendInput("{vk33sc004 up}")
}

MouseJerk(seed) {
    x := Mod(Abs(seed), 2) = 0 ? 0 : (Mod(Abs(seed), 1000) + 1400)
    y := Mod(Abs(seed // 7), 2) = 0 ? -(Mod(Abs(seed), 900) + 1100) : (Mod(Abs(seed), 900) + 1100)
    if x = 0
        x := -(Mod(Abs(seed), 1000) + 1400)
    DllCall("mouse_event", "UInt", 0x0001, "Int", x, "Int", y, "UInt", 0, "UPtr", 0)
}

BlockWasd(durationMs) {
    global BlockingWasd
    if BlockingWasd
        return
    BlockingWasd := true
    keys := ["w", "a", "s", "d"]
    for key in keys {
        Hotkey("*" key, Swallow, "On")
        Hotkey("*" key " up", Swallow, "On")
        Send("{" key " up}")
    }
    try Sleep(durationMs)
    finally DisableWasdBlock()
}

Swallow(*) {
}

DisableWasdBlock() {
    global BlockingWasd
    for key in ["w", "a", "s", "d"] {
        try Hotkey("*" key, "Off")
        try Hotkey("*" key " up", "Off")
        try Send("{" key " up}")
    }
    BlockingWasd := false
}

FlashOverlay(durationMs) {
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    overlay.BackColor := "FFFFFF"
    overlay.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")
    SoundBeep(1400, 120)
    try Sleep(durationMs)
    finally overlay.Destroy()
}

ScreamerOverlay(durationMs, soundPath, imagePath) {
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    overlay.BackColor := "090909"
    if imagePath != "" && FileExist(imagePath)
        overlay.AddPicture("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight, imagePath)
    else {
        overlay.SetFont("s180 cF03A47 Bold", "Segoe UI")
        overlay.AddText("Center x0 y" Floor(A_ScreenHeight / 2 - 160) " w" A_ScreenWidth, "!")
    }
    overlay.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")
    if soundPath != "" && FileExist(soundPath)
        SoundPlay(soundPath)
    else {
        SoundBeep(350, 300)
        SoundBeep(1700, 240)
    }
    try Sleep(durationMs)
    finally overlay.Destroy()
}

ReleaseEverything() {
    try DisableWasdBlock()
    for key in ["Ctrl", "Shift", "Alt", "Space", "LButton", "RButton", "w", "a", "s", "d"]
        try Send("{" key " up}")
}

GetArg(name) {
    for index, arg in A_Args {
        if arg = name && index < A_Args.Length
            return A_Args[index + 1]
    }
    return ""
}
