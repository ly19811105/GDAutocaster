#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include HotkeysCollector.ahk
#Include Timer.ahk

class AutomaticCamera extends Common.ConfigSection
{
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _AUTOMATIC_CAMERA_SECTION_NAME)
        
        this.SectionRead(rotate_left, "rotate_left")
        this.SectionRead(rotate_right, "rotate_right")
        this.SectionRead(initial_delay
            , "initial_delay"
            , _AUTOMATIC_CAMERA_INITIAL_DELAY)
        
        this.SectionRead(delay, "delay", _AUTOMATIC_CAMERA_DELAY)
        this.SectionRead(rotate_key, "rotate_key")
        this.SectionRead(ignore_area_shape
            , "ignore_area_shape"
            , _AUTOMATIC_CAMERA_IGNORE_AREA_SHAPE)
        
        this.SectionRead(ignore_area_size
            , "ignore_area_size"
            , _AUTOMATIC_CAMERA_IGNORE_AREA_SIZE)
        
        this.SectionRead(ignore_segment_angle
            , "ignore_segment_angle"
            , _AUTOMATIC_CAMERA_IGNORE_SEGMENT_ANGLE)
        
        if (!Common.Configured(rotate_left
            , rotate_right
            , rotate_key
            , delay
            , ignore_area_shape
            , ignore_area_size
            , ignore_segment_angle
            , initial_delay))
            return
        
        this.rotate_timer := new Timer(delay
            , ObjBindMethod(this
                , "Rotation"
                , rotate_left
                , rotate_right
                , ignore_area_shape
                , ignore_area_size
                , ignore_segment_angle))
        
        key_pressed_function := ObjBindMethod(this, "Start", rotate_key)
        key_released_function := ObjBindMethod(this
            , "RotateButtonUP"
            , rotate_left
            , rotate_right)
        
        if (initial_delay > 0)
        {
            this.delayed_activator := new DelayedActivator(key_pressed_function
                , initial_delay
                , key_released_function)
                
            key_pressed_function := ObjBindMethod(this.delayed_activator, "Press")
            key_released_function := ObjBindMethod(this.delayed_activator, "KillPressUP")
        }
    
        hotkeys_collector.AddHotkey(rotate_key, key_pressed_function)
        hotkeys_collector.AddHotkey(rotate_key . " UP", key_released_function)
    }
    
    Start(rotate_key)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.rotate_timer.isOn
        or !GetKeyState(rotate_key, "P"))
            return

        this.rotate_timer.Start()
    }
    
    Rotation(rotate_left
        , rotate_right
        , ignore_area_shape
        , ignore_area_size
        , ignore_segment_angle)
    {
        Send {%rotate_left% UP}
        Send {%rotate_right% UP}
        
        WinGetActiveStats, Title, Width, Height, X, Y
        MouseGetPos, xpos, ypos 
        xpos := xpos - Width/2 ;vector from the middle of the screen to the cursor
        ypos := Height/2 - ypos
        radius := ignore_area_size * Height / 200
        
        ; ignore_segment_angle degrees from 12 o'clock
        ; -> 2x ignore_segment_angle no rotation sector 
        if ( !( (ypos > 0) and (Abs(ATan(xpos / ypos)) * 57.29578 < ignore_segment_angle) )
        and !( (ignore_area_shape = _AUTOMATIC_CAMERA_SHAPE_CIRCLE) 
                and (xpos*xpos + ypos*ypos < radius*radius) )
        and !( (ignore_area_shape = _AUTOMATIC_CAMERA_SHAPE_RECTANGLE)
                and ( (Abs(xpos) < Width * ignore_area_size / 200)
                       and (Abs(ypos) < radius) ) ) ) 
        {
            if xpos > 0 ;right half of screen -> rotate right
                Send {%rotate_right% down}
            else ;left half of screen -> rotate left
                Send {%rotate_left% down}
        }
    }

    RotateButtonUP(rotate_left, rotate_right)
    {
        Send {%rotate_left% up}
        Send {%rotate_right% up}
        
        this.rotate_timer.Stop()
    }
}

