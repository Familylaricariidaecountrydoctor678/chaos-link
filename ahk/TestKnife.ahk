#Requires AutoHotkey v2.0
#SingleInstance Force

if A_Args.Length && A_Args[1] = "--check"
    ExitApp

if !A_IsAdmin {
    try Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    catch {
        MsgBox("Для проверки нужны права администратора.", "Chaos Link")
    }
    ExitApp
}

TrayTip("Chaos Link", "Откройте CS2 и нажмите F8. F9 — закрыть тест.")

F8::PressKnife()
F9::ExitApp()

PressKnife() {
    cs2Window := WinExist("ahk_exe cs2.exe")
    if !cs2Window {
        MsgBox("CS2 не запущена: процесс cs2.exe не найден.", "Chaos Link")
        return
    }

    if !WinActive("ahk_id " cs2Window) {
        WinActivate("ahk_id " cs2Window)
        if !WinWaitActive("ahk_id " cs2Window, , 2) {
            MsgBox("Не удалось сделать окно CS2 активным.", "Chaos Link")
            return
        }
    }

    SendInput("{vk33sc004 down}")
    Sleep(100)
    SendInput("{vk33sc004 up}")
    SoundBeep(1100, 80)
}
