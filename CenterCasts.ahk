#Include CommonFunctions.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class CenterCasts
{
    spam_prevention := []

    __New(config_name, hotkeys_collector)
    {
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, center casts, cast%A_INDEX%
            IniRead, closer_not_center, % config_name, center casts, closer_not_center, % _CENTER_CASTS_CLOSER_NOT_CENTER
            IniRead, initial_delay, % config_name, center casts, initial_delay, % _CENTER_CASTS_INITIAL_DELAY
            IniRead, delay, % config_name, center casts, delay, % _CENTER_CASTS_DELAY
            closer_not_center := Common.StrToBool(closer_not_center)
            
            if (!Common.Configured(cast_str, closer_not_center, initial_delay, delay))
                continue
              
            keys := StrSplit(cast_str, [":", ","])
            key := keys.RemoveAt(1)
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key
                , ObjBindMethod(this, "CenterCast", keys, closer_not_center, initial_delay, delay, A_INDEX))
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key . " UP"
                , ObjBindMethod(this, "CenterCastUP", A_INDEX))
            
            this.spam_prevention.Push(0)
        }
    }
    
    CenterCast(keys, closer_not_center, initial_delay, delay, index)
    {
        global game_window_id
        if (!WinActive(game_window_id) or this.spam_prevention[index])
            return
    
        this.spam_prevention[index] := 1
    
        keys := keys.Clone()
        if (initial_delay > 0)
        {
            fn := ObjBindMethod(this, "CenterCast2", keys, closer_not_center, delay)
            SetTimer, %fn%, -%initial_delay%
        }
        else
            this.CenterCast2(keys, closer_not_center, delay)
    }
    
    CenterCast2(keys, closer_not_center, delay)
    {
        static resolution_read := false
        static Width
        static Height
        
        if (!resolution_read)
        {
            WinGetActiveStats, Title, Width, Height, X, Y
            Height += _CENTER_CASTS_HEIGHT_CORRECTION
            resolution_read := true
        }
        
        MouseGetPos, xpos, ypos
        
        if (closer_not_center)
        {
            dist := sqrt((xpos - Width/2)**2 + (ypos - Height/2)**2)
            BlockInput, MouseMove
            
            if (dist = 0)
                MouseMove, Width/2, Height/2, 0
            else
                MouseMove, Width/2 + _CENTER_CASTS_DISTANCE * (xpos - Width/2) / dist
                         , Height/2 + _CENTER_CASTS_DISTANCE * (ypos - Height/2) / dist, 0
        }
        else
        {
            BlockInput, MouseMove
            MouseMove, Width/2, Height/2, 0
        }
    
        Sleep, %_CENTER_CASTS_PAUSE_AFTER_MOVING_CURSOR%
        key := keys.RemoveAt(1)
        Send {%key%}
        
        if (keys.Length() = 0)
        {
            MouseMove, xpos, ypos, 0
            BlockInput, MouseMoveOff
        }
        else
        {
            fn := ObjBindMethod(this, "CenterCast3", keys, xpos, ypos)
            SetTimer, %fn%, %delay%
        }
    }
    
    CenterCast3(keys, xpos, ypos)
    {
        key := keys.RemoveAt(1)
        Send {%key%}
        
        if (keys.Length() = 0)
        {
            SetTimer,, Off
            MouseMove, xpos, ypos, 0
            BlockInput, MouseMoveOff
        }
    }
    
    CenterCastUP(index)
    {
        this.spam_prevention[index] := 0
    }
}
