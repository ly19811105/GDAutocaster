#include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Combos
{
    spam_protection := []
    just_pressed := []
    
    __New(config_name, hotkeys_collector)
    {
        IniRead, delay, % config_name, combo presses, delay, % _COMBOS_IN_BETWEEN_DELAY
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, combo_str, % config_name, combo presses, combo%A_INDEX%
            IniRead, delay_override, % config_name, combo presses, delay%A_INDEX%, % delay
            IniRead, initial_delay, % config_name, combo presses, initial_delay%A_INDEX%, % _COMBOS_INITIAL_DELAY
            IniRead, stop_on_release, % config_name, combo presses, stop_on_release%A_INDEX%, % _COMBOS_STOP_ON_RELEASE
            IniRead, double_press, % config_name, combo presses, double_press%A_INDEX%, % _COMBOS_DOUBLE_PRESS
            
            double_press := Common.StrToBool(double_press)
            initial_delay := Common.StrToBool(initial_delay)
            stop_on_release := Common.StrToBool(stop_on_release)
            
            if (!Common.Configured(combo_str, initial_delay, stop_on_release, delay_override, double_press))
                continue
            
            combo_keys := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys.RemoveAt(1)
            
            if (!double_press)
            {
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key
                    , ObjBindMethod(this, "ComboPress", delay_override, combo_keys, initial_delay, A_INDEX, combo_key, stop_on_release))
            }
            else
            {
                IniRead, double_press_time_gap, % config_name, combo presses, double_press%A_INDEX%_time_gap, % _COMBOS_DOUBLE_PRESS_TIME_GAP
                
                if (Common.Configured(double_press_time_gap))
                    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key
                        , ObjBindMethod(this, "ComboDouble", double_press_time_gap, delay_override, combo_keys, initial_delay, A_INDEX, combo_key, stop_on_release))
            }
                
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key . " UP", ObjBindMethod(this, "ComboPressUP", A_INDEX))
            this.spam_protection.Push(0)
            this.just_pressed.Push(false)
        }
    }
    
    ComboPress(delay, keys, initial_delay, index, key, stop_on_release)
    {
        global game_window_id
        if(!WinActive(game_window_id) or this.spam_protection[index])
            return
            
        this.spam_protection[index] := 1

        keys := keys.Clone()
        
        if (!initial_delay)
        {
            first_key := keys.RemoveAt(1)
            Send {%first_key%}
        }
        
        fn := ObjBindMethod(this, "ComboTimer", delay, keys, key, stop_on_release)
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
        this.spam_protection[index] := 0
    }
    
    ComboDouble(double_press_time_gap, delay, keys, initial_delay, index, key, stop_on_release)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
            
        if (!this.just_pressed[index])
        {
            this.just_pressed[index] := true
            fn := ObjBindMethod(this, "ComboDoubleTimer", index)
            SetTimer, %fn%, -%double_press_time_gap%
        }
        else
            this.ComboPress(delay, keys, initial_delay, index, key, stop_on_release)
    }
    
    ComboDoubleTimer(index)
    {
        this.just_pressed[index] := false
    }
}






