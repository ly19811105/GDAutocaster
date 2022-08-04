#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include HotkeysCollector.ahk
#Include Timer.ahk

class CenterCasts extends Common.ConfigSection
{
    pressed_down := {}
    spam_protection := {}
    mouse_moving := false
    delayed_activators := {}
    pressing_timers := {}
    center_x := 0
    center_y := 0

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _CENTER_CASTS_SECTION_NAME)
        
        this.SectionRead(screen_width, "screen_width", 0)
        this.SectionRead(screen_height, "screen_height", 0)
        this.SectionRead(off_center, "off_center", _CENTER_CASTS_OFF_CENTER)
        
        this.SectionRead(center_str, "center")
        if (Common.Configured(center_str))
        {
            this.center_x := StrSplit(center_str, ",")[1]
            this.center_y := StrSplit(center_str, ",")[2]
        }
    
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(cast_str, "cast" . A_INDEX)
            this.SectionRead(off_center%A_INDEX%
                , "off_center" . A_INDEX
                , off_center)
                
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
                , off_center%A_INDEX%
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
            
            key_pressed_function := ObjBindMethod(this
                , "MoveToCenter"
                , keys
                , off_center%A_INDEX%
                , delay
                , A_INDEX
                , delay_after_cursor
                , screen_width
                , screen_height)
                
            key_released_function := ObjBindMethod(this, "PressUP", A_INDEX)
            
            this.pressing_timers[A_INDEX] := new Timer(delay
                , ObjBindMethod(this, "PressButton", keys))
            
            if (initial_delay > 0)
            {
                delayed_activator := new DelayedActivator(key_pressed_function
                    , initial_delay
                    , key_released_function
                    , !is_wheel)
                    
                this.delayed_activators[A_INDEX] := delayed_activator
                
                key_pressed_function := ObjBindMethod(delayed_activator, "Press")
                key_released_function := ObjBindMethod(delayed_activator, "PressUP")
            }
            
            hotkeys_collector.AddHotkey(key, key_pressed_function)
            hotkeys_collector.AddHotkey(key . " UP", key_released_function)
        }
    }
    
    MoveToCenter(keys
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
    
        MouseGetPos, xpos, ypos
        
        if (this.center_x != 0 or this.center_y != 0)
        {
            center_x := this.center_x
            center_y := this.center_y
        }
        else
        {
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
            
            center_x := Width/2
            center_y := Height/2
        }
 
        if (off_center)
        {
            dist := sqrt((xpos - center_x)**2 + (ypos - center_y)**2)
            if (dist != 0)
            {
                center_x += _CENTER_CASTS_DISTANCE * (xpos - center_x) / dist
                center_y += _CENTER_CASTS_DISTANCE * (ypos - center_y) / dist
            }
        }
        
        BlockInput, MouseMove
        Common.MoveMouse(center_x, center_y)

        this.pressing_timers[index].Loop(keys.Length()
            , delay_after_cursor
            , ObjBindMethod(this, "GoBack", xpos, ypos))
    }
    
    PressButton(keys, i)
    {
        key := keys[i]
        Send {%key%}
    }
    
    GoBack(xpos, ypos)
    {
        Common.MoveMouse(xpos, ypos)  
        BlockInput, MouseMoveOff
        this.mouse_moving := false
    }
    
    PressUP(index)
    {
        this.pressed_down[index] := false
    }
}
