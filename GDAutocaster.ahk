#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#HotkeyModifierTimeout -1
#KeyHistory 50
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 3

#include Autocasting.ahk
#include Camera.ahk
#Include CenterCasts.ahk
#Include Clicker.ahk
#Include Combos.ahk
#Include ComboHolds.ahk
#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk
#Include PeriodicCasts.ahk

hotkeys_suspended_by_user := false
hotkeys_collector := new HotkeysCollector()
toggle_pending := false
already_hidden := false
hotkeys_inactive_fix := false

Menu, Tray, Icon , *, -1, 1
Menu, Tray, NoStandard
Menu, Tray, Add, Load Config, LoadConfigAction
Menu, Tray, Add, Restart, RestartAction
Menu, Tray, Add, Exit, ExitAction

if (A_Args.Length() > 0)
{   
    config_name := A_Args[1]
}
else
    FileSelectFile, config_name,,,Select Config File,Configs (*.ini)

If (!FileExist(config_name))
{
    MsgBox, %config_name% config file not found
    ExitApp
}

Menu, Tray, Insert, Load Config, ConfigName
Menu, Tray, Insert, Load Config
Menu, Tray, Disable, ConfigName
Menu, Tray, Default, ConfigName
SplitPath, config_name,,,, config_shortname
Menu, Tray, Rename, ConfigName, % config_shortname

IniRead, game_window_id, % config_name, general, game_window_id, % _GAME_WINDOW_ID
if (!Common.Configured(game_window_id))
{
    MsgBox, Missing "game_window_id" in the config, i.e. game_window_id=ahk_exe Grim Dawn.exe in [general] section.
    ExitApp
}

IniRead, suspend_key, % config_name, general, suspend_key
if Common.Configured(suspend_key)
    Hotkey, %suspend_key%, SuspendHotkeys

IniRead, capslock_remap, % config_name, general, capslock_remap
if Common.Configured(capslock_remap)
    hotkeys_collector.AddHotkey("Capslock", Func("CapslockAction"))

new Autocasting(config_name, hotkeys_collector)
new Camera(config_name, hotkeys_collector)
new CenterCasts(config_name, hotkeys_collector)
new Clicker(config_name, hotkeys_collector)
new Combos(config_name, hotkeys_collector)
new ComboHolds(config_name, hotkeys_collector)
new PeriodicCasts(config_name, hotkeys_collector)

IniRead, hold_to_hide_key, % config_name, hiding items, hold_to_hide_key
IniRead, gd_toggle_hide_key, % config_name, hiding items, gd_toggle_hide_key
IniRead, show_delay, % config_name, hiding items, show_delay, % _HOLD_TO_HIDE_ITEMS_TIME_BUFFER
if Common.Configured(hold_to_hide_key, gd_toggle_hide_key, show_delay)
{
    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . hold_to_hide_key, Func("HoldToHideItems").Bind(1, show_delay))
    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . hold_to_hide_key . " UP", Func("HoldToHideItems").Bind(0, show_delay))
}
    
SetTimer, MainLoop, % _AUTOMATIC_HOTKEY_SUSPENSION_LOOP_DELAY
MainLoop()
{
    global game_window_id
    global suspend_key
    global hotkeys_suspended_by_user
    global hotkeys_inactive_fix

    if (!WinActive(game_window_id))
    {
        if (!A_IsSuspended)
            Suspend, On
        
        if Common.Configured(suspend_key)
            Hotkey, %suspend_key%, Off
            
        hotkeys_inactive_fix := false
    }    
    else
    {
        if (!hotkeys_inactive_fix)
        {
            Suspend, On
            Suspend, Off
            hotkeys_inactive_fix := true
        }
        
        if Common.Configured(suspend_key)
        {
            Hotkey, %suspend_key%, On
            if (!hotkeys_suspended_by_user)
                Suspend, Off
        }
        else
        {
            Suspend, Off
        }
    }
}

ConfigName()
{
}

LoadConfigAction()
{
    Run % A_ScriptFullPath
    ExitApp
}

RestartAction()
{
    global config_name
    if (config_name = "")
    {
        LoadConfigAction()
        ExitApp
    }
    
    Run, %A_ScriptFullPath% "%config_name%"
}

ExitAction()
{
    ExitApp
}

SuspendHotkeys()
{
    Suspend
    global hotkeys_suspended_by_user
    hotkeys_suspended_by_user ^= true
}

HoldToHideItems(hiding, show_delay)
{
    global game_window_id, toggle_pending, already_hidden
    if (!WinActive(game_window_id))
        return
        
    if (already_hidden and hiding)
        return
        
    if (hiding)
    {
        if (toggle_pending)
        {
            SetTimer, ToggleItemDisplay, Off
            toggle_pending := false
        }
        else
            ToggleItemDisplay()
    }
    else
    {
        toggle_pending := true
        SetTimer, ToggleItemDisplay, -%show_delay%
    }
    
    already_hidden := hiding
}

ToggleItemDisplay()
{
    global toggle_pending, gd_toggle_hide_key
    Send {%gd_toggle_hide_key%}
    toggle_pending := false
}

CapslockAction()
{
    global game_window_id, capslock_remap
    if(WinActive(game_window_id))
        Send {%capslock_remap%}
}

