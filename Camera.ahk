#include Common.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class Camera extends Common.ConfigSection
{
  __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _CAMERA_SECTION_NAME)
    
        this.SectionRead(angle, "angle", _CAMERA_ANGLE)
        this.SectionRead(counter_clockwise, "counter_clockwise")
        this.SectionRead(clockwise, "clockwise")
        this.SectionRead(rotation_key, "rotation_key")
        this.SectionRead(camera_sleep, "delay", _CAMERA_DELAY)
        this.SectionRead(drag_delay, "drag_delay", _CAMERA_DRAG_DELAY)
    
        if Common.Configured(angle
            , counter_clockwise
            , clockwise
            , rotation_key
            , camera_sleep
            , drag_delay)
        {
            hotkeys_collector.AddHotkey(counter_clockwise
                , ObjBindMethod(this
                    , "Counterclock"
                    , camera_sleep
                    , rotation_key
                    , angle
                    , drag_delay))
                    
            hotkeys_collector.AddHotkey(clockwise
                , ObjBindMethod(this
                    , "Clock"
                    , camera_sleep
                    , rotation_key
                    , angle
                    , drag_delay))
        }
    }

    Counterclock(camera_sleep, rotation_key, angle, drag_delay)
    {
        global window_ids
        if(Common.IfActive(window_ids))
            this.Rotate(camera_sleep, rotation_key, angle, drag_delay)
    }

    Clock(camera_sleep, rotation_key, angle, drag_delay)
    {
        global window_ids
        if(Common.IfActive(window_ids))
            this.Rotate(camera_sleep, rotation_key, -angle, drag_delay)
    }

    Rotate(camera_sleep, rotation_key, angle, drag_delay)
    {
        static resolution_read := false
        static Width
        static Height
        
        if (!resolution_read)
        {
            WinGetActiveStats, Title, Width, Height, X, Y
            resolution_read := true
        }
        
        SetKeyDelay, -1

        MouseGetPos, xpos, ypos 
        BlockInput, MouseMove
        MouseMove, this.CalculateX(angle, Width), Height-1, 0
        
        Sleep, %camera_sleep%
        
        Send {%rotation_key% down}
        MouseMove, this.CalculateX(-angle, Width), Height-1, drag_delay
        
        Sleep, %camera_sleep%
        
        Send {%rotation_key% up}
        MouseMove, xpos, ypos, 0
        BlockInput, MouseMoveOff
    }
    
    CalculateX(angle, width)
    {
        return (Abs(angle) - angle) * _CAMERA_WIDTH_ANGLE_RATIO
    }
}
