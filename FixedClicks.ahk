#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class FixedClicks extends Common.ConfigSection
{
    spam_protection := []

    class Click
    {
        __New(x, y, is_left := true)
        {
            this.x := x
            this.y := y
            this.is_left := is_left
        }
    }

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _FIXED_CLICKS_SECTION_NAME)
        this.SectionRead(delay, "delay", _FIXED_CLICKS_DELAY)
        this.SectionRead(initial_delay, "initial_delay", _FIXED_CLICKS_INITIAL_DELAY)
        
        this.SectionRead(go_back, "go_back", _FIXED_CLICKS_GO_BACK)
        go_back := Common.StrToBool(go_back)
    
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
            
            key_native_function := Common.StrToBool(key_native_function)
            
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
            
            hotkey_modifiers := key_native_function 
                ? _HOTKEY_MODIFIERS 
                : _HOTKEY_MODIFIERS_NATIVE_FUNCTION_BLOCKED
            
            this.spam_protection.Push(0)
            
            hotkeys_collector.AddHotkey(hotkey_modifiers . button
                , ObjBindMethod(this
                    , "StartClicking"
                    , clicks
                    , delay%A_INDEX%
                    , initial_delay%A_INDEX%
                    , repeat
                    , translation
                    , A_INDEX
                    , go_back))
            
            hotkeys_collector.AddHotkey(hotkey_modifiers . button . " UP"
                , ObjBindMethod(this, "ClickingUP", A_INDEX))
        }
    }
    
    StartClicking(clicks, delay, initial_delay, repeat, translation, index, go_back)
    {
        global game_window_id
        if(!WinActive(game_window_id) or this.spam_protection[index])
            return
            
        this.spam_protection[index] := 1
        
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
    
    Clicking(clicks
        , delay
        , repeat
        , translation
        , clicks_copy
        , go_back
        , return_point
        , total_translation)
    {
        global game_window_id
        if(!WinActive(game_window_id))
            return
        
        click := clicks_copy.RemoveAt(1)
        MouseClick, % click.is_left ? "Left" : "Right"
            , % click.x + total_translation.x
            , % click.y + total_translation.y,, 0
        
        if (clicks_copy.Length() = 0)
        {
            if (repeat = 0)
            {
                if (go_back)
                    MouseMove, return_point.x, return_point.y, 0
                    
                Return
            }
            else
            {
                clicks_copy := clicks.Clone()
                repeat -= 1
                total_translation.x += translation.x
                total_translation.y += translation.y
            }
        }
        
        fn := ObjBindMethod(this
            , "Clicking"
            , clicks
            , delay
            , repeat
            , translation
            , clicks_copy
            , go_back
            , return_point
            , total_translation)
            
        SetTimer, %fn%, -%delay%
    }
    
    ClickingUP(index)
    {
        this.spam_protection[index] := 0
    }
}
