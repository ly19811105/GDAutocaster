#HotkeyModifierTimeout -1
#KeyHistory 50
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#NoEnv
#SingleInstance Force
#Warn ClassOverwrite
#Persistent

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
#Include Hacker.ahk
#Include HideItems.ahk
#Include HotkeysCollector.ahk
#Include RelativeClicks.ahk
#Include ToggleHolds.ahk
#Include Tray.ahk

tray_instance := new Tray()

if (A_Args.Length() > 0)
    config_name := A_Args[1]
else
    FileSelectFile, config_name,,,Select Config File,Configs (*.ini)

hotkeys_suspended_by_user := false
autocast_right_away := false
if (A_Args.Length() > 1)
{
    hotkeys_suspended_by_user := A_Args[2] & 1
    autocast_prev_state := A_Args[2] & 2
    autocast_right_away := A_Args[2] & 4
}

If (!FileExist(config_name))
{
    MsgBox, %config_name% config file not found
    ExitApp
}

tray_instance.DisplayConfigName()

IniRead, title_match_mode, % config_name, general, title_match_mode, % _TITLE_MATCH_MODE
SetTitleMatchMode, % title_match_mode

IniRead, window_ids, % config_name, general, game_window_ids
if (!Common.Configured(window_ids))
    IniRead, window_ids, % config_name, general, game_window_id, % _GAME_WINDOW_ID

if (!Common.Configured(window_ids))
{
    MsgBox, Missing "game_window_id" in the config, i.e. game_window_id=ahk_exe Grim Dawn.exe in [general] section.
    ExitApp
}
window_ids := StrSplit(window_ids, ",")
    
IniRead
    , kill_on_exit
    , % config_name
    , general
    , kill_on_exit
    , % _KILL_ON_EXIT
    
Common.StrToBool(kill_on_exit)

IniRead, suspend_keys, % config_name, general, suspend_keys
if (!Common.Configured(suspend_keys))
    IniRead, suspend_keys, % config_name, general, suspend_key
    
if (!Common.Configured(suspend_keys))
    suspend_keys := []
else
    suspend_keys := StrSplit(suspend_keys, ",")

for not_used, key in suspend_keys
    Hotkey, $%key%, SuspendHotkeys

hotkeys_collector := new HotkeysCollector()
new AutocastByHold(config_name, hotkeys_collector)
new AutomaticCamera(config_name, hotkeys_collector)
new Camera(config_name, hotkeys_collector)
new CenterCasts(config_name, hotkeys_collector)
new FixedClicks(config_name, hotkeys_collector)
new Combos(config_name, hotkeys_collector)
new ComboHolds(config_name, hotkeys_collector)
new ToggleHolds(config_name, hotkeys_collector)
new HideItems(config_name, hotkeys_collector)
new RelativeClicks(config_name, hotkeys_collector)
new Hacker(config_name, hotkeys_collector)
autocast_by_toggle := new AutocastByToggle(config_name
    , hotkeys_collector
    , autocast_right_away
    , autocast_prev_state)

was_ingame := false
already_restarted := Common.IfActive(window_ids)
previous_id := ""

SetTimer, MainLoop, % _AUTOMATIC_HOTKEY_SUSPENSION_LOOP_DELAY
MainLoop()
{
    global window_ids
    global suspend_keys
    global hotkeys_suspended_by_user
    global already_restarted
    global tray_instance
    global kill_on_exit
    global was_ingame
    global previous_id

    id := Common.IfActive(window_ids)
    if (!id)
    {
        if (!A_IsSuspended)
            Suspend, On
        
        for not_used, key in suspend_keys
            Hotkey, $%key%, Off
            
        already_restarted := false
        previous_id := ""
        
        if (!Common.IfExist(window_ids))
        {
            if (was_ingame and kill_on_exit)
                ExitApp
                
            was_ingame := false
        }
    }    
    else
    {
        if (!already_restarted
        or (previous_id and (id != previous_id)))
        {
            fn := ObjBindMethod(tray_instance, "RestartAction", was_ingame)
            SetTimer, %fn%, -3000
            
            already_restarted := true
        }
        
        if (!was_ingame and Common.Configured(suspend_keys))
        {
            for not_used, key in suspend_keys
                Hotkey, $%key%, On
                
            if (hotkeys_suspended_by_user)
                Suspend, On
        }
        
        previous_id := id
        was_ingame := true
    }
}

SuspendHotkeys()
{
    Suspend
    global hotkeys_suspended_by_user
    hotkeys_suspended_by_user := A_IsSuspended
}
