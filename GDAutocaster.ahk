#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#HotkeyModifierTimeout -1
#KeyHistory 50
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 3
Menu, Tray, Icon , *, -1, 1

#Include CenterCasts.ahk
#Include ComboHolds.ahk
#Include CommonFunctions.ahk
#Include HotkeysCollector.ahk

areTimersToggled := {}
timers_to_toggle := []
hold_allowed := true
autocasting_allowed := true
hotkeys_suspended_by_user := false
hotkeys_collector := new HotkeysCollector()

config_name := % StrSplit(A_ScriptName, ".")[1] . ".ini"
If (!FileExist(config_name))
{
    MsgBox, %config_name% not found
    ExitApp
}

IniRead, game_window_id, % config_name, general, game_window_id, ahk_exe Grim Dawn.exe
if (!Configured(game_window_id))
{
    MsgBox, Missing "game_window_id" in the config, i.e. game_window_id=ahk_exe Grim Dawn.exe in [general] section.
    ExitApp
}

new CenterCasts(config_name, hotkeys_collector)

IniRead, skill_key_list, % config_name, autocasting, skill_key_list, 0,1,2,3,4,5,6,7,8,9
skill_key_list := Configured(skill_key_list) ? StrSplit(skill_key_list, ",") : []
for not_used, key in skill_key_list
{
    IniRead, delay, % config_name, % key, delay, 100
    IniRead, toggle_key, % config_name, % key, toggle_key
    IniRead, hold_keys_str, % config_name, % key, hold_keys
    IniRead, not_hold_keys_str, % config_name, % key, not_hold_keys
    
    hold_keys := Configured(hold_keys_str) ? StrSplit(hold_keys_str, ",") : [] 
    not_hold_keys := Configured(not_hold_keys_str) ? StrSplit(not_hold_keys_str, ",") : []
    
    if (!Configured(delay))
        continue
    
    if Configured(toggle_key)
    {
        areTimersToggled[key] := false
        hotkeys_collector.AddHotkey("$" . toggle_key, Func("ToggleTimer").Bind(key))
        timers_to_toggle.Push(key)
    }    
    
    if (Configured(toggle_key) or (hold_keys.Length() > 0))
    {
        fn := Func("PressButton").Bind(key, hold_keys, not_hold_keys)
        SetTimer, %fn%, %delay% 
    }
}

IniRead, master_toggle, % config_name, autocasting, master_toggle
IniRead, master_hold, % config_name, autocasting, master_hold
if (Configured(master_toggle) and master_hold != master_toggle)
    hotkeys_collector.AddHotkey(master_toggle, Func("MasterToggle"))
   
if (Configured(master_hold) and master_hold != master_toggle)
    hotkeys_collector.AddHotkey(master_hold, Func("MasterHold"))
   
if (Configured(master_hold) and master_hold = master_toggle)
    hotkeys_collector.AddHotkey(master_hold, Func("Master"))

IniRead, suspend_key, % config_name, general, suspend_key
if Configured(suspend_key)
    Hotkey, %suspend_key%, SuspendHotkeys
    
IniRead, angle, % config_name, camera, angle, 60
IniRead, counter_clockwise, % config_name, camera, counter_clockwise
IniRead, clockwise, % config_name, camera, clockwise
IniRead, rotation_key, % config_name, camera, rotation_key
IniRead, camera_sleep, % config_name, camera, delay, 40

if Configured(angle, counter_clockwise, clockwise, rotation_key, camera_sleep)
{
    hotkeys_collector.AddHotkey("*" . counter_clockwise, Func("Counterclock").Bind(game_window_id, camera_sleep, rotation_key, angle))
    hotkeys_collector.AddHotkey("*" . clockwise, Func("Clock").Bind(game_window_id, camera_sleep, rotation_key, angle))
}

IniRead, capslock_remap, % config_name, general, capslock_remap
if Configured(capslock_remap)
    hotkeys_collector.AddHotkey("Capslock", Func("CapslockAction"))

IniRead, hold_to_hide_key, % config_name, hiding items, hold_to_hide_key
IniRead, gd_toggle_hide_key, % config_name, hiding items, gd_toggle_hide_key
if Configured(hold_to_hide_key, gd_toggle_hide_key)
    hotkeys_collector.AddHotkey("~*" . hold_to_hide_key, Func("HoldToHide"))
    
IniRead, temp_block_str, % config_name, autocasting, temp_block_keys
IniRead, temp_block_duration, % config_name, autocasting, temp_block_duration, 100
temp_block_keys := Configured(temp_block_str, temp_block_duration) ? StrSplit(temp_block_str, ",") : []
for not_used, key in temp_block_keys
    hotkeys_collector.AddHotkey("*" . key, Func("BlockAutocasting").Bind(temp_block_duration))
    
IniRead, combo_delay, % config_name, combo presses, delay, 200
Loop, 9
{
    IniRead, combo_str, % config_name, combo presses, combo%A_INDEX%
    IniRead, combo_delay_override, % config_name, combo presses, delay%A_INDEX%
    
    IniRead, initial_delay, % config_name, combo presses, initial_delay%A_INDEX%, false
    initial_delay := StrToBool(initial_delay)
    
    if (!Configured(combo_str, initial_delay) or (!Configured(combo_delay) and !Configured(combo_delay_override)))
        continue
    
    combo_keys := StrSplit(combo_str, [":", ","])
    combo_key := combo_keys.RemoveAt(1)
    combo_delay_override := Configured(combo_delay_override) ? combo_delay_override : combo_delay
    hotkeys_collector.AddHotkey("*$" . combo_key, Func("ComboPress").Bind(combo_delay_override, combo_keys, initial_delay))
}

new ComboHolds(config_name, hotkeys_collector)

SetTimer, MainLoop, 1000
MainLoop()
{
    global game_window_id, suspend_key, hotkeys_suspended_by_user

    if (!WinActive(game_window_id))
    {
        if (!A_IsSuspended)
            Suspend, On
        
        if Configured(suspend_key)
            Hotkey, %suspend_key%, Off
    }    
    else
    {
        if Configured(suspend_key)
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

/*
kluczyk
f::
    WinGetActiveStats, Title, Width, Height, X, Y
    MouseGetPos, xpos, ypos
    BlockInput, MouseMove
    MouseMove, 1270, 230, 0
    Sleep, 50 ;Sleep, 25 lowered it, needs testing in specific case
    Click
    Sleep, 50 ;not needed in most cases, test it
    MouseMove, xpos, ypos, 0
    BlockInput, MouseMoveOff
Return
*/

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
    global hold_allowed, game_window_id
    if (WinActive(game_window_id))
        hold_allowed := !MasterToggle()
}

SuspendHotkeys()
{
    Suspend
    global hotkeys_suspended_by_user
    hotkeys_suspended_by_user ^= true
}

CalculateX(angle, width)
{
    return (Abs(angle) - angle) * width/360
}

Rotate(camera_sleep, rotation_key, angle)
{
    WinGetActiveStats, Title, Width, Height, X, Y
    MouseGetPos, xpos, ypos 
    BlockInput, MouseMove
    MouseMove, CalculateX(angle, Width), Height-1, 0
    
    Sleep, %camera_sleep%
    
    Send {%rotation_key% down}
    MouseMove, CalculateX(-angle, Width), Height-1, 0
    BlockInput, MouseMoveOff
    
    Sleep, %camera_sleep%
    
    Send {%rotation_key% up}
    MouseMove, xpos, ypos, 0
}

HoldToHide()
{
    global game_window_id, gd_toggle_hide_key, hold_to_hide_key
    if (!WinActive(game_window_id))
        return
    
    Send {%gd_toggle_hide_key%}
    KeyWait, %hold_to_hide_key%
    Send {%gd_toggle_hide_key%}
}

Counterclock(game_window_id, camera_sleep, rotation_key, angle)
{
    if(WinActive(game_window_id))
        Rotate(camera_sleep, rotation_key, angle)
}

Clock(game_window_id, camera_sleep, rotation_key, angle)
{
    if(WinActive(game_window_id))
        Rotate(camera_sleep, rotation_key, -angle)
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

ComboPress(delay, keys, initial_delay)
{
    global game_window_id
    if(!WinActive(game_window_id))
        return

    keys := keys.Clone()
    
    if (!initial_delay)
    {
        first_key := keys.RemoveAt(1)
        Send {%first_key%}
    }
    
    fn := Func("ComboTimer").Bind(delay, keys)
    SetTimer, %fn%, -%delay%
}

ComboTimer(delay, keys)
{   
    global game_window_id
    if (!WinActive(game_window_id) or (keys.Length() = 0))
        return
    
    key := keys.RemoveAt(1)
    Send {%key%}
    SetTimer,, -%delay% 
}

