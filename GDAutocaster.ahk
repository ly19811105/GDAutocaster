#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#HotkeyModifierTimeout -1
#KeyHistory 50
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 3

#include Camera.ahk
#Include CenterCasts.ahk
#Include Clicker.ahk
#Include Combos.ahk
#Include ComboHolds.ahk
#Include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk
#Include PeriodicCasts.ahk

areTimersToggled := {}
timers_to_toggle := []
hold_allowed := true
autocasting_allowed := true
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

IniRead, pressed_buttons, % config_name, autocasting, pressed_buttons, % _AUTOCASTING_PRESSED_BUTTONS
pressed_buttons := Common.Configured(pressed_buttons) ? StrSplit(pressed_buttons, ",") : []
for not_used, key in pressed_buttons
{
    IniRead, delay, % config_name, % key, delay, % _AUTOCASTING_DELAY
    IniRead, toggle_key, % config_name, % key, toggle_key
    IniRead, hold_keys_str, % config_name, % key, hold_keys
    IniRead, not_hold_keys_str, % config_name, % key, not_hold_keys
    
    hold_keys := Common.Configured(hold_keys_str) ? StrSplit(hold_keys_str, ",") : [] 
    not_hold_keys := Common.Configured(not_hold_keys_str) ? StrSplit(not_hold_keys_str, ",") : []
    
    if (!Common.Configured(delay))
        continue
    
    if Common.Configured(toggle_key)
    {
        areTimersToggled[key] := false
        hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . toggle_key, Func("ToggleTimer").Bind(key))
        timers_to_toggle.Push(key)
    }    
    
    if (Common.Configured(toggle_key) or (hold_keys.Length() > 0))
    {
        fn := Func("PressButton").Bind(key, hold_keys, not_hold_keys)
        SetTimer, %fn%, %delay% 
    }
}

IniRead, master_toggle, % config_name, autocasting, master_toggle
IniRead, master_hold, % config_name, autocasting, master_hold
if (Common.Configured(master_toggle) and master_hold != master_toggle)
    hotkeys_collector.AddHotkey(master_toggle, Func("MasterToggle"))
   
if (Common.Configured(master_hold) and master_hold != master_toggle)
    hotkeys_collector.AddHotkey(master_hold, Func("MasterHold"))
   
if (Common.Configured(master_hold) and master_hold = master_toggle)
    hotkeys_collector.AddHotkey(master_hold, Func("Master"))

IniRead, suspend_key, % config_name, general, suspend_key
if Common.Configured(suspend_key)
    Hotkey, %suspend_key%, SuspendHotkeys

IniRead, capslock_remap, % config_name, general, capslock_remap
if Common.Configured(capslock_remap)
    hotkeys_collector.AddHotkey("Capslock", Func("CapslockAction"))

IniRead, temp_block_str, % config_name, autocasting, temp_block_keys
IniRead, temp_block_duration, % config_name, autocasting, temp_block_duration, % _AUTOCASTING_TEMPORARY_BLOCK_DURATION
temp_block_keys := Common.Configured(temp_block_str, temp_block_duration) ? StrSplit(temp_block_str, ",") : []
for not_used, key in temp_block_keys
    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key, Func("BlockAutocasting").Bind(temp_block_duration))

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

ToggleTimer(key)
{
    global areTimersToggled, game_window_id
    if (WinActive(game_window_id))
        areTimersToggled[key] ^= true
}

PressButton(key, hold_keys, not_hold_keys)
{
    global game_window_id, hold_allowed, areTimersToggled, autocasting_allowed
    if (!WinActive(game_window_id) or !autocasting_allowed)
        return
    
    if (hold_allowed and ((not_hold_keys.Length() > 0) and HeldTogether(not_hold_keys)))
        return
    
    if (areTimersToggled[key] or (hold_allowed and (hold_keys.Length() > 0) and HeldTogether(hold_keys)))
        send {%key%}
}

HeldTogether(keys)
{
    For not_used, key in keys
        if !GetKeyState(key, "P")
            return false
    
    return true
}

MasterToggle()
{
    global areTimersToggled, timers_to_toggle, game_window_id
    if (!WinActive(game_window_id))
        return
    
    areTimersOn := AreTimersOn() 
    
    if (areTimersOn)
    {
        timers_to_toggle := []
        For key, state in areTimersToggled
        {
            if (state)
            {
                timers_to_toggle.Push(key)
                ToggleTimer(key)
            }
        }
    }
    else
    {
        For not_used, key in timers_to_toggle
            ToggleTimer(key)
    }
    
    return areTimersOn
}

AreTimersOn()
{
    global areTimersToggled
    for not_used, state in areTimersToggled 
        if (state)
            return true
    
    return false
}

MasterHold()
{
    global hold_allowed, game_window_id
    if (WinActive(game_window_id))
        hold_allowed := !hold_allowed
}

Master()
{
    global hold_allowed, game_window_id, areTimersToggled
    if (WinActive(game_window_id) and areTimersToggled.Length() > 0)
        hold_allowed := !MasterToggle()
    else
        MasterHold()
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

BlockAutocasting(duration)
{
    global autocasting_allowed, game_window_id
    if (WinActive(game_window_id))
    {
        autocasting_allowed := false
        SetTimer, BlockAutocastingOff, -%duration%
    }
}

BlockAutocastingOff()
{
    global autocasting_allowed
    autocasting_allowed := true
}
