#include CommonFunctions.ahk
#Include HotkeysCollector.ahk

class PeriodicCasts
{
    __New(config_name, hotkeys_collector)
    {
        Loop, 9
        {
            IniRead, cast_str, % config_name, periodic casts, cast%A_INDEX%
            IniRead, delay, % config_name, periodic casts, delay%A_INDEX%, 1000
            if (!Configured(cast_str, delay))
                continue
            
            keys := StrSplit(cast_str, [":", ","])
            key := keys.RemoveAt(1)
            
            hotkeys_collector.AddHotkey("~*$" . key, ObjBindMethod(this, "PeriodicCast", key, keys, delay))
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
