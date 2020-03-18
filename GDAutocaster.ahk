#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 1000 
#MaxThreadsPerHotkey 1
#HotkeyModifierTimeout -1
#KeyHistory 50
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 3
Menu, Tray, Icon , *, -1, 1

areTimersToggled := {}
timers_to_toggle := []
hold_allowed := true
autocasting_allowed := true
hotkeys_suspended_by_user := false
hotkeyDictionary := {}
just_pressed := false

script_name := SubStr(A_ScriptName, 1, -4)
config_name := % script_name . ".ini"

If (!FileExist(config_name))
{
    MsgBox, %config_name% not found
    ExitApp
}

IniRead, window_identifier, % config_name, general, window_identifier, ahk_exe Grim Dawn.exe
if (!Configured(window_identifier))
{
    MsgBox, Missing "window_identifier" in the config, i.e. window_identifier=ahk_exe Grim Dawn.exe in [general] section.
    ExitApp
}

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
        AddHotkey("*" . toggle_key, Func("ToggleTimer").Bind(key))
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
    AddHotkey(master_toggle, Func("MasterToggle"))
   
if (Configured(master_hold) and master_hold != master_toggle)
    AddHotkey(master_hold, Func("MasterHold"))
   
if (Configured(master_hold) and master_hold = master_toggle)
    AddHotkey(master_hold, Func("Master"))

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
    AddHotkey("*" . counter_clockwise, Func("Counterclock").Bind(window_identifier, camera_sleep, rotation_key, angle))
    AddHotkey("*" . clockwise, Func("Clock").Bind(window_identifier, camera_sleep, rotation_key, angle))
}

IniRead, capslock_remap, % config_name, general, capslock_remap
if Configured(capslock_remap)
    AddHotkey("Capslock", Func("CapslockAction"))

IniRead, hold_to_hide_key, % config_name, hiding items, hold_to_hide_key
IniRead, gd_toggle_hide_key, % config_name, hiding items, gd_toggle_hide_key
if Configured(hold_to_hide_key, gd_toggle_hide_key)
    AddHotkey("~*" . hold_to_hide_key, Func("HoldToHide"))
    
IniRead, temp_block_str, % config_name, autocasting, temp_block_keys
IniRead, temp_block_duration, % config_name, autocasting, temp_block_duration, 100
temp_block_keys := Configured(temp_block_str, temp_block_duration) ? StrSplit(temp_block_str, ",") : []
for not_used, key in temp_block_keys
    AddHotkey("*" . key, Func("BlockAutocasting").Bind(temp_block_duration))
    
IniRead, combo_delay, % config_name, combo presses, delay, 200
Loop, 9
{
    IniRead, combo_str, % config_name, combo presses, combo%A_INDEX%
    IniRead, combo_delay_override, % config_name, combo presses, delay%A_INDEX%
    if (!Configured(combo_str) or (!Configured(combo_delay) and !Configured(combo_delay_override)))
        continue
    
    combo_keys := StrSplit(combo_str, [":", ","])
    combo_key := combo_keys.RemoveAt(1)
    combo_delay_override := Configured(combo_delay_override) ? combo_delay_override : combo_delay
    AddHotkey("*$" . combo_key, Func("ComboPress").Bind(combo_delay_override, combo_keys))
}

Loop, 9
{
    IniRead, combo_str, % config_name, combo holds, combo%A_INDEX%
    IniRead, double_press, % config_name, combo holds, double_press%A_INDEX%, 0
    
    if (double_press = "true")
        double_press := 1
    
    if (double_press = "false")
        double_press := 0
    
    if (!Configured(combo_str, double_press))
        continue
        
    combo_keys := StrSplit(combo_str, [":", ","])
    combo_key := combo_keys.RemoveAt(1)

    if (double_press)
    {
        IniRead, double_press_time_gap, % config_name, combo holds, double_press%A_INDEX%_time_gap, 250
        if (!Configured(double_press_time_gap))
        {
            MsgBox, Missing "double_press_time_gap" in the config, i.e. double_press_time_gap=250 in [combo holds] section.
            ExitApp
        }    
        
        AddHotkey("*" . combo_key, Func("ComboHoldDouble").Bind(combo_key, combo_keys, double_press_time_gap))
    }
    else
        AddHotkey("*" . combo_key, Func("ComboHold").Bind(combo_key, combo_keys))

    AddHotkey("*" . combo_key . " UP", Func("ComboHoldUp").Bind(combo_keys))
}

SetTimer, MainLoop, 1000
MainLoop()
{
    global window_identifier, suspend_key, hotkeys_suspended_by_user

    if (!WinActive(window_identifier))
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
    global areTimersToggled, window_identifier
    if (WinActive(window_identifier))
        areTimersToggled[key] ^= true
}

PressButton(key, hold_keys, not_hold_keys)
{
    global window_identifier, hold_allowed, areTimersToggled, autocasting_allowed
    if (!WinActive(window_identifier) or !autocasting_allowed)
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
    global areTimersToggled, timers_to_toggle, window_identifier
    if (!WinActive(window_identifier))
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
    global hold_allowed, window_identifier
    if (WinActive(window_identifier))
        hold_allowed := !hold_allowed
}

Master()
{
    global hold_allowed, window_identifier
    if (WinActive(window_identifier))
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
    global window_identifier, gd_toggle_hide_key, hold_to_hide_key
    if (!WinActive(window_identifier))
        return
    
    Send {%gd_toggle_hide_key%}
    KeyWait, %hold_to_hide_key%
    Send {%gd_toggle_hide_key%}
}

Counterclock(window_identifier, camera_sleep, rotation_key, angle)
{
    if(WinActive(window_identifier))
        Rotate(camera_sleep, rotation_key, angle)
}

Clock(window_identifier, camera_sleep, rotation_key, angle)
{
    if(WinActive(window_identifier))
        Rotate(camera_sleep, rotation_key, -angle)
}

CapslockAction()
{
    global window_identifier, capslock_remap
    if(WinActive(window_identifier))
        Send {%capslock_remap%}
}

AddHotkey(key, function)
{
    global hotkeyDictionary
    
    if (!hotkeyDictionary.HasKey(key))
    {
        hotkeyDictionary[key] := [function]
        fn := Func("HotkeyFunction").Bind(key)
        Hotkey, %key%, %fn%, On
    }
    else
        hotkeyDictionary[key].Push(function)
}

HotkeyFunction(key)
{
    global hotkeyDictionary
    For not_used, function in hotkeyDictionary[key]
        function.Call()
}

BlockAutocasting(duration)
{
    global autocasting_allowed, window_identifier
    if (WinActive(window_identifier))
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

Configured(keys*)
{
    for not_used, key in keys
        if (key = "ERROR" or key = "")
            return false
        
    return true
}

ComboPress(delay, keys)
{
    global window_identifier
    if(!WinActive(window_identifier))
        return

    keys := keys.Clone()
    first_key := keys.RemoveAt(1)
    Send {%first_key%}
    
    fn := Func("ComboTimer").Bind(delay, keys)
    SetTimer, %fn%, -%delay%
}

ComboTimer(delay, keys)
{   
    global window_identifier
    if (!WinActive(window_identifier) or (keys.Length() = 0))
        return
    
    key := keys.RemoveAt(1)
    Send {%key%}
    SetTimer,, -%delay% 
}

ComboHold(combo_key, combo_keys)
{
    global window_identifier
    if (!WinActive(window_identifier))
        return
    
    KeyWait, %combo_key%, T0.05
    if ErrorLevel
    {
        for not_used, key in combo_keys
            Send {%key% down}
    }
}

ComboHoldUp(combo_keys)
{
    global window_identifier
    if (!WinActive(window_identifier))
        return
        
    for not_used, key in combo_keys
        Send {%key% up}
}

ComboHoldDouble(combo_key, combo_keys, double_press_time_gap)
{
    global window_identifier, just_pressed
    if (!WinActive(window_identifier))
        return
        
    if (!just_pressed)
    {
        just_pressed := true    
        SetTimer, ComboHoldDoubleTimer, -%double_press_time_gap%
    }
    else
        ComboHold(combo_key, combo_keys)

}

ComboHoldDoubleTimer()
{
    global just_pressed
    just_pressed := false
}

