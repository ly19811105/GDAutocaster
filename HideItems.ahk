#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class HideItems
{
    toggle_pending := false
    already_hidden := false

    __New(config_name, hotkeys_collector)
    {
        IniRead, hold_to_hide_key, % config_name, hiding items, hold_to_hide_key
        IniRead, gd_toggle_hide_key, % config_name, hiding items, gd_toggle_hide_key
        IniRead, show_delay, % config_name, hiding items, show_delay, % _HOLD_TO_HIDE_ITEMS_TIME_BUFFER
        
        if Common.Configured(hold_to_hide_key, gd_toggle_hide_key, show_delay)
        {
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . hold_to_hide_key
                , ObjBindMethod(this, "HoldToHideItems", 1, show_delay, gd_toggle_hide_key))
            
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . hold_to_hide_key . " UP"
                , ObjBindMethod(this, "HoldToHideItems", 0, show_delay, gd_toggle_hide_key))
        }
    }
    
    HoldToHideItems(hiding, show_delay, gd_toggle_hide_key)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
            
        if (this.already_hidden and hiding)
            return
            
        if (hiding)
        {
            if (this.toggle_pending)
            {
                fn := ObjBindMethod(this, "ToggleItemDisplay", gd_toggle_hide_key)
                SetTimer, %fn%, Off
                this.toggle_pending := false
            }
            else
                this.ToggleItemDisplay(gd_toggle_hide_key)
        }
        else
        {
            this.toggle_pending := true
            fn := ObjBindMethod(this, "ToggleItemDisplay", gd_toggle_hide_key)
            SetTimer, %fn%, -%show_delay%
        }
        
        this.already_hidden := hiding
    }

    ToggleItemDisplay(gd_toggle_hide_key)
    {
        Send {%gd_toggle_hide_key%}
        this.toggle_pending := false
    }
}
