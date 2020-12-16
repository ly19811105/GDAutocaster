#HotkeyModifierTimeout -1
#KeyHistory 50
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#NoEnv
#SingleInstance Force
#Warn ClassOverwrite

SetWorkingDir %A_ScriptDir%

#Include AutocastByHold.ahk
#Include AutocastByToggle.ahk
#Include AutomaticCamera.ahk
#include Camera.ahk
#Include CenterCasts.ahk
#Include FixedClicks.ahk
#Include Combos.ahk
#Include ComboHolds.ahk
#Include Common.ahk
#Include Defaults.ahk
#Include HideItems.ahk
#Include HotkeysCollector.ahk
#Include RelativeClicks.ahk
#Include Tray.ahk

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

IniRead, title_match_mode, % config_name, general, title_match_mode, % _TITLE_MATCH_MODE
SetTitleMatchMode, % title_match_mode

IniRead, window_ids, % config_name, general, game_window_id, % _GAME_WINDOW_ID
if (!Common.Configured(window_ids))
{
    MsgBox, Missing "game_window_id" in the config, i.e. game_window_id=ahk_exe Grim Dawn.exe in [general] section.
    ExitApp
}
window_ids := StrSplit(window_ids, ",")

IniRead, suspend_key, % config_name, general, suspend_key
if Common.Configured(suspend_key)
    Hotkey, $%suspend_key%, SuspendHotkeys
    
IniRead
    , kill_on_exit
    , % config_name
    , general
    , kill_on_exit
    , % _KILL_ON_EXIT

hotkeys_collector := new HotkeysCollector()
new AutocastByHold(config_name, hotkeys_collector)
autocast_by_toggle := new AutocastByToggle(config_name, hotkeys_collector, autocast_right_away)
new AutomaticCamera(config_name, hotkeys_collector)
new Camera(config_name, hotkeys_collector)
new CenterCasts(config_name, hotkeys_collector)
new FixedClicks(config_name, hotkeys_collector)
new Combos(config_name, hotkeys_collector)
new ComboHolds(config_name, hotkeys_collector)
new HideItems(config_name, hotkeys_collector)
new RelativeClicks(config_name, hotkeys_collector)

hotkeys_suspended_by_user := false
was_ever_ingame := false
hotkeys_inactive_fix := Common.IfActive(window_ids)

SetTimer, MainLoop, % _AUTOMATIC_HOTKEY_SUSPENSION_LOOP_DELAY
MainLoop()
{
    global window_ids
    global suspend_key
    global hotkeys_suspended_by_user
    global hotkeys_inactive_fix
    global tray_instance
    global kill_on_exit
    global was_ever_ingame

    if (!Common.IfActive(window_ids))
    {
        if (!A_IsSuspended)
            Suspend, On
        
        if Common.Configured(suspend_key)
            Hotkey, $%suspend_key%, Off
            
        hotkeys_inactive_fix := false
        
        if (kill_on_exit 
        and was_ever_ingame
        and !Common.IfExist(window_ids))
            ExitApp
    }    
    else
    {
        was_ever_ingame := true
    
        if (!hotkeys_inactive_fix)
        {
            fn := ObjBindMethod(tray_instance, "RestartAction")
            SetTimer, %fn%, -3000
            hotkeys_inactive_fix := true
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
