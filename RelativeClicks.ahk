#Include Clicker.ahk
#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class RelativeClicks extends Clicker
{
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _RELATIVE_CLICKS_SECTION_NAME)
        this.SectionRead(delay, "delay", _RELATIVE_CLICKS_DELAY)
    
        Loop % _MAX_NUMBER_OF_COMBINATIONS
        {
            this.SectionRead(button, "button" . A_INDEX)
            this.SectionRead(rows, "rows" . A_INDEX)
            this.SectionRead(columns, "columns" . A_INDEX)
            this.SectionRead(width, "width" . A_INDEX)
            this.SectionRead(height, "height" . A_INDEX)
        
            if (!Common.Configured(delay
                , button
                , rows
                , columns
                , width
                , height))
                continue

            this.spam_protection.Push(0)
                
            hotkeys_collector.AddHotkey(button . " UP"
                , ObjBindMethod(this, "ClickingUP", A_INDEX))

            hotkeys_collector.AddHotkey(button
                , ObjBindMethod(this
                    , "StartClicking"
                    , delay
                    , rows
                    , columns
                    , width
                    , height
                    , A_INDEX))
        }
    }
    
    StartClicking(delay
        , rows
        , columns
        , width
        , height
        , index)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or this.spam_protection[index])
            return
            
        this.spam_protection[index] := 1
        
        MouseGetPos, xpos, ypos
        
        clicks := []
        Loop % columns
            clicks.Push(new this.Click(xpos+(A_INDEX-1)*width, ypos))
        
        fn := ObjBindMethod(this
            , "Clicking"
            , clicks
            , delay
            , rows-1
            , new this.Click(0, height)
            , clicks.Clone()
            , true
            , new this.Click(xpos, ypos+rows*height)
            , new this.Click(0, 0))
            
        SetTimer, %fn%, -%delay%
    }
}
