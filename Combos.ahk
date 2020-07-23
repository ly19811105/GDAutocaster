#include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Combos
{
    spam_protection := []
    
    __New(config_name, hotkeys_collector)
    {
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
                , ObjBindMethod(this, "ComboPress", combo_delay_override, combo_keys, initial_delay, A_INDEX, combo_key, stop_on_release))
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key . " UP", ObjBindMethod(this, "ComboPressUP", A_INDEX))
            
            this.spam_protection.Push(0)
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
}






