#include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class PeriodicCasts
{
    __New(config_name, hotkeys_collector)
    {
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, periodic casts, cast%A_INDEX%
            IniRead, delay, % config_name, periodic casts, delay%A_INDEX%, % _PERIODIC_CASTS_IN_BETWEEN_DELAY
            if (!Configured(cast_str, delay))
                continue
            
            keys := StrSplit(cast_str, [":", ","])
            key := keys.RemoveAt(1)
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key, ObjBindMethod(this, "PeriodicCast", key, keys, delay))
        }

    }
    
    PeriodicCast(periodic_hotkey, keys, delay)
    {
        global game_window_id
        if(!WinActive(game_window_id))
            return

        for not_used, key in keys
            Send {%key%}
        
        fn := ObjBindMethod(this, "PeriodicCastTimer", periodic_hotkey, keys)
        SetTimer, %fn%, %delay%
    }
    
    PeriodicCastTimer(periodic_hotkey, keys)
    {
        if (!GetKeyState(periodic_hotkey, "P"))
        {
            SetTimer,, Off
            Return
        }
        
        for not_used, key in keys
            Send {%key%}
    }
}
