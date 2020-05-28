#include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class PeriodicCasts
{
    spam_prevention := []

    __New(config_name, hotkeys_collector)
    {
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, periodic casts, cast%A_INDEX%
            IniRead, delay, % config_name, periodic casts, delay%A_INDEX%, % _PERIODIC_CASTS_IN_BETWEEN_DELAY
            if (!Common.Configured(cast_str, delay))
                continue
            
            cast_str := StrSplit(cast_str, ":")
            held_keys_str := cast_str.RemoveAt(1)
            held_keys := StrSplit(held_keys_str, ",")
            pressed_keys := StrSplit(cast_str[1], ",")
            first_key := held_keys.RemoveAt(1)
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key
                , ObjBindMethod(this, "PeriodicCast", first_key, pressed_keys, delay, held_keys, A_INDEX))
                
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key . " UP"
                , ObjBindMethod(this, "PeriodicCastUP", A_INDEX))    
            
            this.spam_prevention.Push(0)
        }

    }
    
    PeriodicCast(first_key, pressed_keys, delay, held_keys, index)
    {
        global game_window_id
        if(!WinActive(game_window_id) or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := 1
            
        for not_used, key in held_keys
            if (!GetKeyState(key, "P"))
                return

        for not_used, key in pressed_keys
            Send {%key%}
        
        fn := ObjBindMethod(this, "PeriodicCastTimer", first_key, pressed_keys)
        SetTimer, %fn%, %delay%
    }
    
    PeriodicCastTimer(first_key, pressed_keys)
    {
        if (!GetKeyState(first_key, "P"))
        {
            SetTimer,, Off
            Return
        }
        
        for not_used, key in pressed_keys
            Send {%key%}
    }
    
    PeriodicCastUP(index)
    {
        this.spam_prevention[index] := 0
    }
}
