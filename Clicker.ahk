#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Clicker extends Common.ConfigSection
{
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _CLICKER_SECTION_NAME)
    
        Loop % _MAX_NUMBER_OF_COMBINATIONS
        {
            this.SectionRead(coordX, "X" . A_INDEX)    
            this.SectionRead(coordY, "Y" . A_INDEX)
            this.SectionRead(button, "button" . A_INDEX)
            this.SectionRead(delay, "delay" . A_INDEX, _CLICKER_DELAY)
            
            if (!Common.Configured(coordX, coordY, button, delay))
                return
                
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . button
                , ObjBindMethod(this, "ClickPixel", coordX, coordY, delay))
        }
    }
    
    ClickPixel(coordX, coordY, delay)
    {
        WinGetActiveStats, Title, Width, Height, X, Y
        MouseGetPos, xpos, ypos
        BlockInput, MouseMove
        MouseMove, %coordX%, %coordY%, 0
        
        fn := ObjBindMethod(this, "ClickPixel2", delay, xpos, ypos)
        SetTimer, %fn%, -%delay%
    }
    
    ClickPixel2(delay, xpos, ypos)
    {
        Click
        
        fn := ObjBindMethod(this, "ClickPixel3", xpos, ypos)
        SetTimer, %fn%, -%delay%
    }
    
    ClickPixel3(xpos, ypos)
    {
        MouseMove, xpos, ypos, 0
        BlockInput, MouseMoveOff
    }
}
