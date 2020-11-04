#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Clicker extends Common.ConfigSection
{
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _CLICKER_SECTION_NAME)
    
        this.SectionRead(coordX, "X")    
        this.SectionRead(coordY, "Y")
        this.SectionRead(button, "button")
        
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
