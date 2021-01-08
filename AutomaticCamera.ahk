#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class AutomaticCamera extends Common.ConfigSection
{
    spam_protection := false

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
        
        if (Common.Configured(rotate_left
            , rotate_right
            , rotate_key
            , delay
            , ignore_area_shape
            , ignore_area_size
            , ignore_segment_angle))
        {
        
            hotkeys_collector.AddHotkey(rotate_key
                , ObjBindMethod(this
                    , "HoldButton"
                    , rotate_left
                    , rotate_right
                    , initial_delay
                    , rotate_key
                    , delay
                    , ignore_area_shape
                    , ignore_area_size
                    , ignore_segment_angle))
                    
            hotkeys_collector.AddHotkey(rotate_key . " UP"
                , ObjBindMethod(this
                    , "RotateUp"
                    , rotate_left
                    , rotate_right))
        }
    }
    
    HoldButton(rotate_left
        , rotate_right
        , initial_delay
        , rotate_key
        , delay
        , ignore_area_shape
        , ignore_area_size
        , ignore_segment_angle)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_protection)
            return

        this.spam_protection := true
        
        fn := ObjBindMethod(this
            , "Rotate"
            , rotate_left
            , rotate_right
            , rotate_key
            , delay
            , ignore_area_shape
            , ignore_area_size
            , ignore_segment_angle)
        
        SetTimer, %fn%, -%initial_delay%
    }

    Rotate(rotate_left
        , rotate_right
        , rotate_key
        , delay
        , ignore_area_shape
        , ignore_area_size
        , ignore_segment_angle)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or !GetKeyState(rotate_key, "P"))
        {
            SetTimer,, Off
            return
        }
        
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
        
        SetTimer,, -%delay%
    }

    RotateUp(rotate_left, rotate_right)
    {
        Send {%rotate_left% up}
        Send {%rotate_right% up}
        
        this.spam_protection := false
    }
}

