#include CommonFunctions.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class Camera
{
  __New(config_name, hotkeys_collector)
    {
        IniRead, angle, % config_name, camera, angle, % _CAMERA_ANGLE
        IniRead, counter_clockwise, % config_name, camera, counter_clockwise
        IniRead, clockwise, % config_name, camera, clockwise
        IniRead, rotation_key, % config_name, camera, rotation_key
        IniRead, camera_sleep, % config_name, camera, delay, % _CAMERA_DELAY

        if Common.Configured(angle, counter_clockwise, clockwise, rotation_key, camera_sleep)
        {
            hotkeys_collector.AddHotkey("*" . counter_clockwise, ObjBindMethod(this, "Counterclock", camera_sleep, rotation_key, angle))
            hotkeys_collector.AddHotkey("*" . clockwise, ObjBindMethod(this, "Clock", camera_sleep, rotation_key, angle))
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
