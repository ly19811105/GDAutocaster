#include Common.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class AutocastByToggle
{
    are_timers_toggled := {}
    timers_to_toggle := []
    
    __New(config_name, hotkeys_collector, autocast_right_away)
    {
        IniRead, delay, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, delay, % _AUTOCAST_BY_TOGGLE_DELAY
        
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, key, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, key%A_INDEX%
            IniRead, delay%A_INDEX%, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, delay%A_INDEX%, % delay
            IniRead, toggle_key, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, toggle_key%A_INDEX%
            IniRead, not_hold_keys_str, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, not_hold_keys%A_INDEX%
            
            not_hold_keys := Common.Configured(not_hold_keys_str) ? StrSplit(not_hold_keys_str, ",") : []
            
            if (Common.Configured(delay%A_INDEX%))
            {
                this.are_timers_toggled[key] := false
                this.timers_to_toggle.Push(key)
                
                if (Common.Configured(toggle_key))
                    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . toggle_key, ObjBindMethod(this, "ToggleTimer", key))
                
                fn := ObjBindMethod(this, "PressButton", key, not_hold_keys)
                SetTimer, %fn%, % delay%A_INDEX% 
            }
        }
        
        IniRead, master_toggle, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, master_toggle
        if (Common.Configured(master_toggle))
        {
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . master_toggle, ObjBindMethod(this, "MasterToggle"))
            if (autocast_right_away)
                this.MasterToggle()
        }
    }
    
    ToggleTimer(key)
    {
        global game_window_id
        if (WinActive(game_window_id))
            this.are_timers_toggled[key] ^= true
    }

    PressButton(key, not_hold_keys)
    {
        global game_window_id
        
        if (WinActive(game_window_id)
        and this.are_timers_toggled[key]
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
            For key, state in this.are_timers_toggled
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
        for not_used, state in this.are_timers_toggled 
            if (state)
                return true
        
        return false
    }
}