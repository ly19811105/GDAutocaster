#include Common.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class Autocasting
{
    areTimersToggled := {}
    timers_to_toggle := []
    
    __New(config_name, hotkeys_collector, autocasting_right_away)
    {
        IniRead, pressed_buttons, % config_name, autocasting, pressed_buttons, % _AUTOCASTING_PRESSED_BUTTONS
        pressed_buttons := Common.Configured(pressed_buttons) ? StrSplit(pressed_buttons, ",") : []
        
        for not_used, key in pressed_buttons
        {
            IniRead, delay, % config_name, % key, delay, % _AUTOCASTING_DELAY
            IniRead, toggle_key, % config_name, % key, toggle_key
            IniRead, not_hold_keys_str, % config_name, % key, not_hold_keys
            
            not_hold_keys := Common.Configured(not_hold_keys_str) ? StrSplit(not_hold_keys_str, ",") : []
            
            if (Common.Configured(delay, toggle_key))
            {
                this.areTimersToggled[key] := false
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . toggle_key, ObjBindMethod(this, "ToggleTimer", key))
                this.timers_to_toggle.Push(key)
                
                fn := ObjBindMethod(this, "PressButton", key, not_hold_keys)
                SetTimer, %fn%, %delay% 
            }
        }
        
        IniRead, master_toggle, % config_name, autocasting, master_toggle
        if (Common.Configured(master_toggle))
        {
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . master_toggle, ObjBindMethod(this, "MasterToggle"))
            if (autocasting_right_away)
                this.MasterToggle()
        }
    }
    
    ToggleTimer(key)
    {
        global game_window_id
        if (WinActive(game_window_id))
            this.areTimersToggled[key] ^= true
    }

    PressButton(key, not_hold_keys)
    {
        global game_window_id
        
        if (WinActive(game_window_id)
        and this.areTimersToggled[key]
        and (not_hold_keys.Length() = 0 or !Common.AnyPressed(not_hold_keys)))
            send {%key%}
    }
    
    MasterToggle()
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
        
        areTimersOn := this.AreTimersOn() 
        
        if (areTimersOn)
        {
            this.timers_to_toggle := []
            For key, state in this.areTimersToggled
            {
                if (state)
                {
                    this.timers_to_toggle.Push(key)
                    this.ToggleTimer(key)
                }
            }
        }
        else
        {
            For not_used, key in this.timers_to_toggle
                this.ToggleTimer(key)
        }
        
        return areTimersOn
    }
    
    AreTimersOn()
    {
        for not_used, state in this.areTimersToggled 
            if (state)
                return true
        
        return false
    }
}