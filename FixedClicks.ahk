#Include Clicker.ahk
#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class FixedClicks extends Clicker
{
    spam_protection := {}

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _FIXED_CLICKS_SECTION_NAME)
        
        this.SectionRead(delay, "delay", _FIXED_CLICKS_DELAY)
        this.SectionRead(initial_delay, "initial_delay", _FIXED_CLICKS_INITIAL_DELAY)
        this.SectionRead(go_back, "go_back", _FIXED_CLICKS_GO_BACK)
    
        Loop % _MAX_NUMBER_OF_COMBINATIONS
        {
            this.SectionRead(clicks_str, "clicks" . A_INDEX)
            this.SectionRead(button, "button" . A_INDEX)
            this.SectionRead(delay%A_INDEX%, "delay" . A_INDEX, delay)
            this.SectionRead(repeat, "repeat" . A_INDEX, _FIXED_CLICKS_REPEAT)
            
            this.SectionRead(translation_str
                , "translation" . A_INDEX
                , _FIXED_CLICKS_TRANSLATION)
            
            this.SectionRead(key_native_function
                , "key_native_function" . A_INDEX
                , _FIXED_CLICKS_KEY_NATIVE_FUNCTION)
            
            this.SectionRead(initial_delay%A_INDEX%
                , "initial_delay" . A_INDEX
                , _FIXED_CLICKS_INITIAL_DELAY)
            
            clicks_str := StrSplit(clicks_str, ["(", "["])
            
            clicks := []
            for index, click in clicks_str
            {
                if (Common.Configured(click))
                {
                    is_left := (SubStr(click, 0) = ")")
                    coords := StrSplit(click, [","], ")]")
                    clicks.Push(new this.Click(coords[1], coords[2], is_left))
                }
            }
            
            translation := new this.Click(StrSplit(translation_str, ",")[1]
                , StrSplit(translation_str, ",")[2])
                
            if (!Common.Configured(clicks
                , button
                , delay%A_INDEX%
                , initial_delay%A_INDEX%
                , key_native_function
                , repeat
                , translation))
                continue
            
            is_wheel := InStr(button, "Wheel")
            this.spam_protection[A_INDEX] := !is_wheel 
            this.pressed_down[A_INDEX] := false
            
            hotkeys_collector.AddHotkey(button
                , ObjBindMethod(this
                    , "StartClicking"
                    , clicks
                    , delay%A_INDEX%
                    , initial_delay%A_INDEX%
                    , repeat
                    , translation
                    , A_INDEX
                    , go_back)
                , !key_native_function)
            
            hotkeys_collector.AddHotkey(button . " UP"
                , ObjBindMethod(this, "ClickingUP", A_INDEX)
                , !key_native_function)
        }
    }
    
    StartClicking(clicks
        , delay
        , initial_delay
        , repeat
        , translation
        , index
        , go_back)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or (this.spam_protection[index] and this.pressed_down[index]))
            return
            
        this.pressed_down[index] := true
        
        if (go_back)
        {
            MouseGetPos, xpos, ypos
            return_point := new this.Click(xpos, ypos)
        }
        
        fn := ObjBindMethod(this
            , "Clicking"
            , clicks
            , delay
            , repeat
            , translation
            , clicks.Clone()
            , go_back
            , return_point
            , new this.Click(0, 0))
            
        SetTimer, %fn%, -%initial_delay%
    }
}
