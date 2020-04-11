#Include CommonFunctions.ahk
#Include HotkeysCollector.ahk

class CenterCasts
{
    spam_prevention := []

    __New(config_name, hotkeys_collector)
    {
        Loop, 9
        {
            IniRead, cast_str, % config_name, center casts, cast%A_INDEX%
            IniRead, inq_seal, % config_name, center casts, inq_seal, false
            IniRead, initial_delay, % config_name, center casts, initial_delay, 0
            IniRead, delay, % config_name, center casts, delay, 200
            inq_seal := StrToBool(inq_seal)
            
            if (!Configured(cast_str, inq_seal, initial_delay, delay))
                continue
              
            keys := StrSplit(cast_str, [":", ","])
            key := keys.RemoveAt(1)
            
            hotkeys_collector.AddHotkey("~*$" . key, ObjBindMethod(this, "CenterCast", keys, inq_seal, initial_delay, delay, A_INDEX))
            hotkeys_collector.AddHotkey("~*$" . key . " UP", ObjBindMethod(this, "CenterCastUP", A_INDEX))
            
            this.spam_prevention.Push(0)
        }
    }
    
    CenterCast(keys, inq_seal, initial_delay, delay, index)
    {
        global game_window_id
        if (!WinActive(game_window_id) or this.spam_prevention[index])
            return
    
        this.spam_prevention[index] := 1
    
        keys := keys.Clone()
        if (initial_delay > 0)
        {
            fn := ObjBindMethod(this, "CenterCast2", keys, inq_seal, delay)
            SetTimer, %fn%, -%initial_delay%
        }
        else
            this.CenterCast2(keys, inq_seal, delay)
    }
    
    CenterCast2(keys, inq_seal, delay)
    {
        static resolution_read := false
        static Width
        static Height
        static length := 75
        
        if (!resolution_read)
        {
            WinGetActiveStats, Title, Width, Height, X, Y
            Height += 60
            resolution_read := true
        }
        
        MouseGetPos, xpos, ypos
        
        if (inq_seal)
        {
            dist := sqrt((xpos - Width/2)**2 + (ypos - Height/2)**2)
            BlockInput, MouseMove
            
            if (dist = 0)
                MouseMove, Width/2, Height/2, 0
            else
                MouseMove, Width/2 + length * (xpos - Width/2) / dist, Height/2 + length * (ypos - Height/2) / dist, 0
        }
        else
        {
            BlockInput, MouseMove
            MouseMove, Width/2, Height/2, 0
        }
    
        Sleep, 10
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
