#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class HideItems
{
    hidden := false

    __New(config_name, hotkeys_collector)
    {
        IniRead, hiding_buttons_str, % config_name, hide items, hiding_buttons
        IniRead, ingame_hide_button, % config_name, hide items, ingame_hide_button
        IniRead, hide_duration, % config_name, hide items, hide_duration, % _HIDE_ITEMS_DURATION
        
        hiding_buttons := StrSplit(hiding_buttons_str, [","])
        
        if Common.Configured(hiding_buttons, ingame_hide_button, hide_duration)
            for not_used, key in hiding_buttons
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key
                    , ObjBindMethod(this, "Hide", ingame_hide_button, hide_duration))
        
        this.showFunction := ObjBindMethod(this, "Show", hiding_buttons, ingame_hide_button, hide_duration)
    }
    
    Hide(ingame_hide_button, hide_duration)
    {
        if (!this.hidden)
        {
            Send {%ingame_hide_button%}
            this.hidden := true
        }
        
        fn := this.showFunction
        SetTimer, %fn%, -%hide_duration%
    }
    
    Show(hiding_buttons, ingame_hide_button, hide_duration)
    {
        any_button_pressed := false
        
        for not_used, key in hiding_buttons
        if (GetKeyState(key, "P"))
        {
            any_button_pressed := true
            break
        }
        
        if (any_button_pressed)
        {
            fn := this.showFunction
            SetTimer, %fn%, -%hide_duration%
        }
        else
        {
            Send {%ingame_hide_button%}
            this.hidden := false
        }
    }
}
