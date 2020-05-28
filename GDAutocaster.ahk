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
combo_presses_spam_protection := []
hotkeys_inactive_fix := false

config_name := % StrSplit(A_ScriptName, ".")[1] . "." . _CONFIG_FILE_EXTENSION
If (!FileExist(config_name))
{
    MsgBox, %config_name% not found
    ExitApp
}

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
    
IniRead, angle, % config_name, camera, angle, % _CAMERA_ANGLE
IniRead, counter_clockwise, % config_name, camera, counter_clockwise
IniRead, clockwise, % config_name, camera, clockwise
IniRead, rotation_key, % config_name, camera, rotation_key
IniRead, camera_sleep, % config_name, camera, delay, % _CAMERA_DELAY

if Common.Configured(angle, counter_clockwise, clockwise, rotation_key, camera_sleep)
{
    hotkeys_collector.AddHotkey("*" . counter_clockwise, Func("Counterclock").Bind(game_window_id, camera_sleep, rotation_key, angle))
    hotkeys_collector.AddHotkey("*" . clockwise, Func("Clock").Bind(game_window_id, camera_sleep, rotation_key, angle))
}

IniRead, capslock_remap, % config_name, general, capslock_remap
if Common.Configured(capslock_remap)
    hotkeys_collector.AddHotkey("Capslock", Func("CapslockAction"))

IniRead, temp_block_str, % config_name, autocasting, temp_block_keys
IniRead, temp_block_duration, % config_name, autocasting, temp_block_duration, % _AUTOCASTING_TEMPORARY_BLOCK_DURATION
temp_block_keys := Common.Configured(temp_block_str, temp_block_duration) ? StrSplit(temp_block_str, ",") : []
for not_used, key in temp_block_keys
    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key, Func("BlockAutocasting").Bind(temp_block_duration))
    
IniRead, combo_delay, % config_name, combo presses, delay, % _COMBOS_IN_BETWEEN_DELAY
Loop, %_MAX_NUMBER_OF_COMBINATIONS%
{
    IniRead, combo_str, % config_name, combo presses, combo%A_INDEX%
    IniRead, combo_delay_override, % config_name, combo presses, delay%A_INDEX%
    IniRead, initial_delay, % config_name, combo presses, initial_delay%A_INDEX%, % _COMBOS_INITIAL_DELAY
    IniRead, stop_on_release, % config_name, combo presses, stop_on_release%A_INDEX%, % _COMBOS_STOP_ON_RELEASE
    
    initial_delay := Common.StrToBool(initial_delay)
    stop_on_release := Common.StrToBool(stop_on_release)
    
    if (!Common.Configured(combo_str, initial_delay, stop_on_release) or (!Common.Configured(combo_delay) and !Common.Configured(combo_delay_override)))
        continue
    
    combo_keys := StrSplit(combo_str, [":", ","])
    combo_key := combo_keys.RemoveAt(1)
    combo_delay_override := Common.Configured(combo_delay_override) ? combo_delay_override : combo_delay
    
    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key
        , Func("ComboPress").Bind(combo_delay_override, combo_keys, initial_delay, A_INDEX, combo_key, stop_on_release))
    
    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key . " UP", Func("ComboPressUP").Bind(A_INDEX))
    
    combo_presses_spam_protection.Push(0)
}

new CenterCasts(config_name, hotkeys_collector)
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

CalculateX(angle, width)
{
    return (Abs(angle) - angle) * width/360
}

Rotate(camera_sleep, rotation_key, angle)
{
    static resolution_read := false
    static Width
    static Height
    
    if (!resolution_read)
    {
        WinGetActiveStats, Title, Width, Height, X, Y
        resolution_read := true
    }
    
    SetKeyDelay, -1

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

ComboPress(delay, keys, initial_delay, index, key, stop_on_release)
{
    global game_window_id, combo_presses_spam_protection
    if(!WinActive(game_window_id) or combo_presses_spam_protection[index])
        return
        
    combo_presses_spam_protection[index] := 1

    keys := keys.Clone()
    
    if (!initial_delay)
    {
        first_key := keys.RemoveAt(1)
        Send {%first_key%}
    }
    
    fn := Func("ComboTimer").Bind(delay, keys, key, stop_on_release)
    SetTimer, %fn%, -%delay%
}

ComboTimer(delay, keys, key, stop_on_release)
{   
    global game_window_id
    if (!WinActive(game_window_id) or (keys.Length() = 0) or (stop_on_release and !GetKeyState(key, "P")))
        return
    
    key := keys.RemoveAt(1)
    Send {%key%}
    SetTimer,, -%delay% 
}

ComboPressUP(index)
{
    global combo_presses_spam_protection
    combo_presses_spam_protection[index] := 0
}

