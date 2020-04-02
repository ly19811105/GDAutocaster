#Include CommonFunctions.ahk
#Include HotkeysCollector.ahk

class CenterCasts
{
    __New(config_name, hotkeys_collector)
    {
        Loop, 9
        {
            IniRead, cast_str, % config_name, center casts, cast%A_INDEX% 
            if (!Configured(cast_str))
                continue
                
            keys := StrSplit(cast_str, ":")
            hotkeys_collector.AddHotkey("*" . keys[1], ObjBindMethod(this, "CenterCast", keys[2]))
        }
    }
    
    CenterCast(key)
    {
        WinGetActiveStats, Title, Width, Height, X, Y
        MouseGetPos, xpos, ypos
        BlockInput, MouseMove
        MouseMove, Width/2, Height/2+25, 0
        Sleep, 10
        Send {%key%}
        MouseMove, xpos, ypos, 0
        BlockInput, MouseMoveOff
    }
}
