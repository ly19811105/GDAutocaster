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
    
        if Common.Configured(angle
            , counter_clockwise
            , clockwise
            , rotation_key
            , camera_sleep)
        {
            hotkeys_collector.AddHotkey("*" . counter_clockwise
                , ObjBindMethod(this
                    , "Counterclock"
                    , camera_sleep
                    , rotation_key
                    , angle))
                    
            hotkeys_collector.AddHotkey("*" . clockwise
                , ObjBindMethod(this
                    , "Clock"
                    , camera_sleep
                    , rotation_key
                    , angle))
        }
    }

    Counterclock(camera_sleep, rotation_key, angle)
    {
        global game_window_id
        if(WinActive(game_window_id))
            this.Rotate(camera_sleep, rotation_key, angle)
    }

    Clock(camera_sleep, rotation_key, angle)
    {
        global game_window_id
        if(WinActive(game_window_id))
            this.Rotate(camera_sleep, rotation_key, -angle)
    }

    Rotate(camera_sleep, rotation_key, angle)
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
        MouseMove, this.CalculateX(-angle, Width), Height-1, 0
        BlockInput, MouseMoveOff
        
        Sleep, %camera_sleep%
        
        Send {%rotation_key% up}
        MouseMove, xpos, ypos, 0
    }
    
    CalculateX(angle, width)
    {
        return (Abs(angle) - angle) * width/360
    }
}
