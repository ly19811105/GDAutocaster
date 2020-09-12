#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Clicker
{
    __New(config_name, hotkeys_collector)
    {
        IniRead, coordX, % config_name, clicker, X 
        IniRead, coordY, % config_name, clicker, Y
        IniRead, button, % config_name, clicker, button
        
        if (!Common.Configured(coordX, coordY, button))
            return
            
        hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . button
            , ObjBindMethod(this, "ClickPixel", coordX, coordY))
    }
    
    ClickPixel(coordX, coordY)
    {
        WinGetActiveStats, Title, Width, Height, X, Y
        MouseGetPos, xpos, ypos
        BlockInput, MouseMove
        MouseMove, %coordX%, %coordY%, 0
        Sleep % _CLICKER_DELAY
        Click
        Sleep % _CLICKER_DELAY
        MouseMove, xpos, ypos, 0
        BlockInput, MouseMoveOff
    }
}
