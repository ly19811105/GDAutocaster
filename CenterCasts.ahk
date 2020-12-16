#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class CenterCasts extends Common.ConfigSection
{
    spam_prevention := []
    mouse_moving := false

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _CENTER_CASTS_SECTION_NAME)
    
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(cast_str, "cast" . A_INDEX)
            this.SectionRead(off_center, "off_center", _CENTER_CASTS_OFF_CENTER)
            this.SectionRead(initial_delay, "initial_delay", _CENTER_CASTS_INITIAL_DELAY)
            this.SectionRead(delay, "delay", _CENTER_CASTS_DELAY)
            this.SectionRead(delay_after_cursor, "delay_after_cursor", _CENTER_CASTS_PAUSE_AFTER_MOVING_CURSOR)
        
            off_center := Common.StrToBool(off_center)
            
            if (!Common.Configured(cast_str
                , off_center
                , initial_delay
                , delay))
                continue
              
            keys := StrSplit(cast_str, [":", ","])
            key := keys.RemoveAt(1)
            
            hotkeys_collector.AddHotkey(key
                , ObjBindMethod(this
                    , "CenterCast"
                    , keys
                    , off_center
                    , initial_delay
                    , delay
                    , A_INDEX
                    , delay_after_cursor))
            
            hotkeys_collector.AddHotkey(key . " UP"
                , ObjBindMethod(this, "CenterCastUP", A_INDEX))
            
            this.spam_prevention.Push(0)
        }
    }
    
    CenterCast(keys
        , off_center
        , initial_delay
        , delay
        , index
        , delay_after_cursor)
    {
        global window_ids
        
        if (!Common.IfActive(window_ids)
        or this.spam_prevention[index]
        or this.mouse_moving)
            return
    
        this.spam_prevention[index] := 1
    
        keys := keys.Clone()
        if (initial_delay > 0)
        {
            fn := ObjBindMethod(this
                , "CenterCast2"
                , keys
                , off_center
                , index
                , delay
                , delay_after_cursor)
                
            SetTimer, %fn%, -%initial_delay%
        }
        else
            this.CenterCast2(keys
                , off_center
                , index
                , delay
                , delay_after_cursor)
    }
    
    CenterCast2(keys, off_center, index, delay, delay_after_cursor)
    {
        if (this.mouse_moving)
            return
            
        this.mouse_moving := true
    
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
        
        if (off_center)
        {
            dist := sqrt((xpos - Width/2)**2 + (ypos - Height/2)**2)
            BlockInput, MouseMove
            
            if (dist = 0)
                MouseMove, Width/2, Height/2, 0
            else
                MouseMove, Width/2 + _CENTER_CASTS_DISTANCE * (xpos - Width/2) / dist
                         , Height/2 + _CENTER_CASTS_DISTANCE * (ypos - Height/2) / dist
                         , 0
        }
        else
        {
            BlockInput, MouseMove
            MouseMove, Width/2, Height/2, 0
        }
    
        if (delay_after_cursor > 0)
        {
            fn := ObjBindMethod(this, "CenterCast2b", keys, xpos, ypos, delay, index)
            SetTimer, %fn%, -%delay_after_cursor%
        }
        else
            this.CenterCast2b(keys, xpos, ypos, delay, index)
    }
    
    CenterCast2b(keys, xpos, ypos, delay, index)
    {
        key := keys.RemoveAt(1)
        Send {%key%}
        
        if (keys.Length() = 0)
        {
            MouseMove, xpos, ypos, 0
            BlockInput, MouseMoveOff
            this.mouse_moving := false
        }
        else
        {
            fn := ObjBindMethod(this, "CenterCast3", keys, xpos, ypos, index)
            SetTimer, %fn%, %delay%
        }
    }
    
    CenterCast3(keys, xpos, ypos, index)
    {
        key := keys.RemoveAt(1)
        Send {%key%}
        
        if (keys.Length() = 0)
        {
            SetTimer,, Off
            MouseMove, xpos, ypos, 0
            BlockInput, MouseMoveOff
            this.mouse_moving := false
        }
    }
    
    CenterCastUP(index)
    {
        this.spam_prevention[index] := 0
    }
}
