#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include HotkeysCollector.ahk

class CenterCasts extends Common.ConfigSection
{
    spam_prevention := {}
    mouse_moving := false
    delayed_activators := {}

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _CENTER_CASTS_SECTION_NAME)
        
        this.SectionRead(screen_width, "screen_width", 0)
        this.SectionRead(screen_height, "screen_height", 0)
    
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(cast_str, "cast" . A_INDEX)
            this.SectionRead(off_center
                , "off_center" . A_INDEX
                , _CENTER_CASTS_OFF_CENTER)
                
            this.SectionRead(initial_delay
                , "initial_delay" . A_INDEX
                , _CENTER_CASTS_INITIAL_DELAY)
                
            this.SectionRead(delay
                , "delay" . A_INDEX
                , _CENTER_CASTS_DELAY)
                
            this.SectionRead(delay_after_cursor
                , "delay_after_cursor" . A_INDEX
                , _CENTER_CASTS_PAUSE_AFTER_MOVING_CURSOR)
        
            if (!Common.Configured(cast_str
                , off_center
                , initial_delay
                , delay
                , delay_after_cursor
                , screen_width
                , screen_height))
                continue
              
            keys := StrSplit(cast_str, [":", ","])
            key := keys.RemoveAt(1)
            
            this.spam_prevention[A_INDEX] := false
            
            first_function := ObjBindMethod(this
                , "CenterCast"
                , keys
                , off_center
                , delay
                , A_INDEX
                , delay_after_cursor
                , screen_width
                , screen_height)
                
            first_function_up := ObjBindMethod(this, "CenterCastUP", A_INDEX)
            
            if (initial_delay > 0)
            {
                delayed_activator := new DelayedActivator(first_function
                    , initial_delay
                    , first_function_up)
                    
                this.delayed_activators[A_INDEX] := delayed_activator
                
                first_function := ObjBindMethod(delayed_activator, "Press")
                first_function_up := ObjBindMethod(delayed_activator, "PressUP")
            }
            
            hotkeys_collector.AddHotkey(key, first_function)
            hotkeys_collector.AddHotkey(key . " UP", first_function_up)
        }
    }
    
    CenterCast(keys
        , off_center
        , delay
        , index
        , delay_after_cursor
        , screen_width
        , screen_height)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention[index]
        or this.mouse_moving)
            return
    
        this.spam_prevention[index] := true
        this.mouse_moving := true
    
        keys := keys.Clone()
        
        if (screen_width * screen_height = 0)
        {
            WinGetActiveStats, Title, Width, Height, X, Y
        }
        else
        {
            Width := screen_width
            Height := screen_height
        }
    
        Height += _CENTER_CASTS_HEIGHT_CORRECTION
        
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
            fn := ObjBindMethod(this, "CenterCast2", keys, xpos, ypos, delay, index)
            SetTimer, %fn%, -%delay_after_cursor%
        }
        else
            this.CenterCast2(keys, xpos, ypos, delay, index)
    }
    
    CenterCast2(keys, xpos, ypos, delay, index, ongoing := false)
    {
        key := keys.RemoveAt(1)
        Send {%key%}
        
        if (keys.Length() = 0)
        {
            if (ongoing)
                SetTimer,, Off
            
            MouseMove, xpos, ypos, 0
            BlockInput, MouseMoveOff
            this.mouse_moving := false
        }
        else if (!ongoing)
        {
            fn := ObjBindMethod(this
                , "CenterCast2"
                , keys
                , xpos
                , ypos
                , delay
                , index
                , true)
                
            SetTimer, %fn%, %delay%
        }
    }
    
    CenterCastUP(index)
    {
        this.spam_prevention[index] := false
    }
}
