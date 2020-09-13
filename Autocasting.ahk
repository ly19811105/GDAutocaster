#include Common.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class Autocasting
{
    areTimersToggled := {}
    timers_to_toggle := []
    hold_allowed := true
    autocasting_allowed := true
    
    __New(config_name, hotkeys_collector)
    {
        IniRead, pressed_buttons, % config_name, autocasting, pressed_buttons, % _AUTOCASTING_PRESSED_BUTTONS
        pressed_buttons := Common.Configured(pressed_buttons) ? StrSplit(pressed_buttons, ",") : []
        
        for not_used, key in pressed_buttons
        {
            IniRead, delay, % config_name, % key, delay, % _AUTOCASTING_DELAY
            IniRead, toggle_key, % config_name, % key, toggle_key
            IniRead, hold_keys_str, % config_name, % key, hold_keys
            IniRead, not_hold_keys_str, % config_name, % key, not_hold_keys
            
            hold_keys := Common.Configured(hold_keys_str) ? StrSplit(hold_keys_str, ",") : [] 
            not_hold_keys := Common.Configured(not_hold_keys_str) ? StrSplit(not_hold_keys_str, ",") : []
            
            if (!Common.Configured(delay))
                continue
            
            if Common.Configured(toggle_key)
            {
                this.areTimersToggled[key] := false
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . toggle_key, ObjBindMethod(this, "ToggleTimer", key))
                this.timers_to_toggle.Push(key)
            }    
            
            if (Common.Configured(toggle_key) or (hold_keys.Length() > 0))
            {
                fn := ObjBindMethod(this, "PressButton", key, hold_keys, not_hold_keys)
                SetTimer, %fn%, %delay% 
            }
        }
        
        IniRead, master_toggle, % config_name, autocasting, master_toggle
        IniRead, master_hold, % config_name, autocasting, master_hold
        if (Common.Configured(master_toggle) and master_hold != master_toggle)
            hotkeys_collector.AddHotkey(master_toggle, ObjBindMethod(this, "MasterToggle"))
           
        if (Common.Configured(master_hold) and master_hold != master_toggle)
            hotkeys_collector.AddHotkey(master_hold, ObjBindMethod(this, "MasterHold"))
           
        if (Common.Configured(master_hold) and master_hold = master_toggle)
            hotkeys_collector.AddHotkey(master_hold, ObjBindMethod(this, "Master"))
            
        IniRead, temp_block_str, % config_name, autocasting, temp_block_keys
        IniRead, temp_block_duration, % config_name, autocasting, temp_block_duration, % _AUTOCASTING_TEMPORARY_BLOCK_DURATION
        temp_block_keys := Common.Configured(temp_block_str, temp_block_duration) ? StrSplit(temp_block_str, ",") : []
        
        for not_used, key in temp_block_keys
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . key, ObjBindMethod(this, "BlockAutocasting", temp_block_duration))
    }
    
    ToggleTimer(key)
    {
        global game_window_id
        if (WinActive(game_window_id))
            this.areTimersToggled[key] ^= true
    }

    PressButton(key, hold_keys, not_hold_keys)
    {
        global game_window_id
        if (!WinActive(game_window_id) or !this.autocasting_allowed)
            return
        
        if (this.hold_allowed and ((not_hold_keys.Length() > 0) and Common.Pressed(not_hold_keys)))
            return
        
        if (this.areTimersToggled[key] or (this.hold_allowed and (hold_keys.Length() > 0) and Common.Pressed(hold_keys)))
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

    MasterHold()
    {
        global game_window_id
        if (WinActive(game_window_id))
            this.hold_allowed := !this.hold_allowed
    }

    Master()
    {
        global game_window_id
        if (WinActive(game_window_id) and this.areTimersToggled.Length() > 0)
            this.hold_allowed := !this.MasterToggle()
        else
            this.MasterHold()
    }
    
    BlockAutocasting(duration)
    {
        global game_window_id
        if (WinActive(game_window_id))
        {
            this.autocasting_allowed := false
            fn := ObjBindMethod(this, "BlockAutocastingOff")
            SetTimer, %fn%, -%duration%
        }
    }

    BlockAutocastingOff()
    {
        this.autocasting_allowed := true
    }
}