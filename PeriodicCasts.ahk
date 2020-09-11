#include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class PeriodicCasts
{
    spam_prevention := []
    just_pressed := []

    __New(config_name, hotkeys_collector)
    {
        IniRead, delay, % config_name, periodic casts, delay, % _PERIODIC_CASTS_IN_BETWEEN_DELAY
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, periodic casts, cast%A_INDEX%
            IniRead, delay%A_INDEX%, % config_name, periodic casts, delay%A_INDEX%, % delay
            IniRead, initial_delay, % config_name, periodic casts, initial_delay%A_INDEX%, % _PERIODIC_CASTS_INITIAL_DELAY
            IniRead, double_press, % config_name, periodic casts, double_press%A_INDEX%, % _PERIODIC_CASTS_DOUBLE_PRESS 
            double_press := Common.StrToBool(double_press)
            
            if (!Common.Configured(cast_str, initial_delay, delay%A_INDEX%, double_press))
                continue
                
            cast_str := StrSplit(cast_str, ":")
            held_keys_str := cast_str.RemoveAt(1)
            held_keys := StrSplit(held_keys_str, ",")
            pressed_keys := StrSplit(cast_str[1], ",")
            first_key := held_keys[held_keys.Length()]
            
            if (!double_press)
            {
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key
                    , ObjBindMethod(this, "PeriodicCast", pressed_keys, delay%A_INDEX%, held_keys, A_INDEX, initial_delay))
            }
            else
            {
                IniRead, double_press_time_gap, % config_name, periodic casts, double_press%A_INDEX%_time_gap, % _PERIODIC_CASTS_DOUBLE_PRESS_TIME_GAP
                
                if (Common.Configured(double_press_time_gap))
                    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key
                        , ObjBindMethod(this, "PeriodicCastDouble", double_press_time_gap, pressed_keys, delay%A_INDEX%, held_keys, A_INDEX, initial_delay))
            }
                
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key . " UP"
                , ObjBindMethod(this, "PeriodicCastUP", A_INDEX))    
            
            this.spam_prevention.Push(0)
            this.just_pressed.Push(false)
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
    
    PeriodicCastDouble(double_press_time_gap, pressed_keys, delay, held_keys, index, initial_delay)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
            
        if (!this.just_pressed[index])
        {
            this.just_pressed[index] := true
            fn := ObjBindMethod(this, "PeriodicCastDoubleTimer", index)
            SetTimer, %fn%, -%double_press_time_gap%
        }
        else
            this.PeriodicCast(pressed_keys, delay, held_keys, index, initial_delay)
    }
    
    PeriodicCastDoubleTimer(index)
    {
        this.just_pressed[index] := false
    }
}
