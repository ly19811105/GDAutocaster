#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include HotkeysCollector.ahk

class CenterCasts extends Common.ConfigSection
{
    pressed_down := {}
    spam_protection := {}
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
            
            is_wheel := InStr(key, _WHEEL_ID)
            this.spam_protection[A_INDEX] := !is_wheel
            this.pressed_down[A_INDEX] := false
            
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
                    , first_function_up
                    , !is_wheel)
                    
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
        or (this.spam_protection[index] and this.pressed_down[index])
        or this.mouse_moving)
            return
    
        this.pressed_down[index] := true
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
        dist := sqrt((xpos - Width/2)**2 + (ypos - Height/2)**2)
        
        if (off_center and dist != 0)
        {
            center_x := Width/2 + _CENTER_CASTS_DISTANCE * (xpos - Width/2) / dist
            center_y := Height/2 + _CENTER_CASTS_DISTANCE * (ypos - Height/2) / dist
        }
        else
        {
            center_x := Width/2
            center_y := Height/2
        }
        
        BlockInput, MouseMove
        Common.MoveMouse(center_x, center_y)
    
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
            
            Common.MoveMouse(xpos, ypos)  
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
        this.pressed_down[index] := false
    }
}
