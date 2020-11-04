#HotkeyModifierTimeout -1
#KeyHistory 50
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#NoEnv
#SingleInstance Force
#Warn ClassOverwrite

SetTitleMatchMode, 3
SetWorkingDir %A_ScriptDir%

#Include AutocastByHold.ahk
#include AutocastByToggle.ahk
#include Camera.ahk
#Include CenterCasts.ahk
#Include Clicker.ahk
#Include Combos.ahk
#Include ComboHolds.ahk
#Include Common.ahk
#Include Defaults.ahk
#Include HideItems.ahk
#Include HotkeysCollector.ahk
#include Tray.ahk

tray_instance := new Tray()

if (A_Args.Length() > 0)
    config_name := A_Args[1]
else
    FileSelectFile, config_name,,,Select Config File,Configs (*.ini)

autocast_right_away := (A_Args.Length() > 1)

If (!FileExist(config_name))
{
    MsgBox, %config_name% config file not found
    ExitApp
}

tray_instance.DisplayConfigName()

IniRead, game_window_id, % config_name, general, game_window_id, % _GAME_WINDOW_ID
if (!Common.Configured(game_window_id))
{
    MsgBox, Missing "game_window_id" in the config, i.e. game_window_id=ahk_exe Grim Dawn.exe in [general] section.
    ExitApp
}

IniRead, suspend_key, % config_name, general, suspend_key
if Common.Configured(suspend_key)
    Hotkey, $%suspend_key%, SuspendHotkeys

hotkeys_collector := new HotkeysCollector()
new AutocastByHold(config_name, hotkeys_collector)
autocast_by_toggle := new AutocastByToggle(config_name, hotkeys_collector, autocast_right_away)
new Camera(config_name, hotkeys_collector)
new CenterCasts(config_name, hotkeys_collector)
new Clicker(config_name, hotkeys_collector)
new Combos(config_name, hotkeys_collector)
new ComboHolds(config_name, hotkeys_collector)
new HideItems(config_name, hotkeys_collector)

hotkeys_suspended_by_user := false
hotkeys_inactive_fix := WinActive(game_window_id)
SetTimer, MainLoop, % _AUTOMATIC_HOTKEY_SUSPENSION_LOOP_DELAY

MainLoop()
{
    global game_window_id
    global suspend_key
    global hotkeys_suspended_by_user
    global hotkeys_inactive_fix
    global tray_instance

    if (!WinActive(game_window_id))
    {
        if (!A_IsSuspended)
            Suspend, On
        
        if Common.Configured(suspend_key)
            Hotkey, $%suspend_key%, Off
            
        hotkeys_inactive_fix := false
    }    
    else
    {
        if (!hotkeys_inactive_fix)
        {
            fn := ObjBindMethod(tray_instance, "RestartAction")
            SetTimer, %fn%, -3000
        }
        
        if Common.Configured(suspend_key)
        {
            Hotkey, $%suspend_key%, On
            if (!hotkeys_suspended_by_user)
                Suspend, Off
        }
        else
        {
            Suspend, Off
        }
    }
}

SuspendHotkeys()
{
    Suspend
    global hotkeys_suspended_by_user
    hotkeys_suspended_by_user ^= true
}
