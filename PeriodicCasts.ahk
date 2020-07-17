#include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class PeriodicCasts
{
    spam_prevention := []

    __New(config_name, hotkeys_collector)
    {
        IniRead, delay, % config_name, periodic casts, delay, % _PERIODIC_CASTS_IN_BETWEEN_DELAY
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, periodic casts, cast%A_INDEX%
            IniRead, delay%A_INDEX%, % config_name, periodic casts, delay%A_INDEX%
            IniRead, initial_delay, % config_name, periodic casts, initial_delay%A_INDEX%, % _PERIODIC_CASTS_INITIAL_DELAY
            if (!Common.Configured(cast_str, initial_delay))
                continue
                
            if (!Common.Configured(delay%A_INDEX%))
                delay%A_INDEX% := delay
            
            cast_str := StrSplit(cast_str, ":")
            held_keys_str := cast_str.RemoveAt(1)
            held_keys := StrSplit(held_keys_str, ",")
            pressed_keys := StrSplit(cast_str[1], ",")
            first_key := held_keys[1]
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key
                , ObjBindMethod(this, "PeriodicCast", pressed_keys, delay%A_INDEX%, held_keys, A_INDEX, initial_delay))
                
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key . " UP"
                , ObjBindMethod(this, "PeriodicCastUP", A_INDEX))    
            
            this.spam_prevention.Push(0)
        }

    }
    
    PeriodicCast(pressed_keys, delay, held_keys, index, initial_delay)
    {
        global game_window_id
        if(!WinActive(game_window_id) or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := 1
        
        if (!Common.Pressed(held_keys))
            return
        
        if (initial_delay = 0)
        {
            Common.PressButtons(pressed_keys)
            
            fn := ObjBindMethod(this, "PeriodicCastTimer", pressed_keys, held_keys)
            SetTimer, %fn%, %delay%
        }
        else
        {
            fn := ObjBindMethod(this, "PeriodicCastInitialTimer", pressed_keys, held_keys, delay)
            SetTimer, %fn%, -%initial_delay%
        }
    }
    
    PeriodicCastInitialTimer(pressed_keys, held_keys, delay)
    {
        if (!Common.Pressed(held_keys))
            Return
        
        Common.PressButtons(pressed_keys)
        
        fn := ObjBindMethod(this, "PeriodicCastTimer", pressed_keys, held_keys)
        SetTimer, %fn%, %delay%
    }
    
    PeriodicCastTimer(pressed_keys, held_keys)
    {
        if (!Common.Pressed(held_keys))
        {
            SetTimer,, Off
            Return
        }
        
        Common.PressButtons(pressed_keys)
    }
    
    PeriodicCastUP(index)
    {
        this.spam_prevention[index] := 0
    }
}
