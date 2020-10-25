#include Common.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class AutocastByToggle
{
    any_timer_on := 0
    timers := []
    
    __New(config_name, hotkeys_collector, autocast_right_away)
    {
        IniRead, delay, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, delay, % _AUTOCAST_BY_TOGGLE_DELAY
        
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, cast%A_INDEX%
            IniRead, delay%A_INDEX%, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, delay%A_INDEX%, % delay
            IniRead, not_hold_keys_str, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, not_hold_keys%A_INDEX%
            IniRead, reset_key, % config_name, % _AUTOCAST_BY_TOGGLE_SECTION_NAME, reset_key%A_INDEX%
            
            toggle_key := StrSplit(cast_str, ":")[1]
            key_pressed := StrSplit(cast_str, ":")[2]
            
            not_hold_keys := Common.Configured(not_hold_keys_str) ? StrSplit(not_hold_keys_str, ",") : []
            
            if (Common.Configured(delay%A_INDEX%, not_hold_keys, toggle_key, key_pressed))
            {
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . toggle_key, ObjBindMethod(this, "ToggleTimer", A_INDEX))
                    
                if (Common.Configured(reset_key))
                    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . reset_key, ObjBindMethod(this, "ResetTimer", A_INDEX))
                
                timer := {}
                timer.function := ObjBindMethod(this, "PressButton", key_pressed, not_hold_keys)
                timer.delay := delay%A_INDEX%
                this.timers.Push(timer)
            }
        }
        
        if (autocast_right_away)
            this.toggleAllTimers()
    }
    
    ToggleTimer(index)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return

        bit_mask := 2**index
        this.any_timer_on ^= bit_mask
        
        timer_function := this.timers[index].function
        timer_delay := this.timers[index].delay
        
        if (this.any_timer_on & bit_mask)
            SetTimer, % timer_function, % timer_delay
        else
            SetTimer, % timer_function, Off
            
    }

    PressButton(key_pressed, not_hold_keys)
    {
        global game_window_id
        if (WinActive(game_window_id)
        and (not_hold_keys.Length() = 0 or !Common.AnyPressed(not_hold_keys)))
            send {%key_pressed%}
    }
    
    toggleAllTimers()
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
        
        if (this.any_timer_on)
        {
            this.any_timer_on := 0
        
            for not_used, timer in this.timers
            {
                timer_function := timer.function
                SetTimer, % timer_function, Off
            }
        }
        else
        {
            this.any_timer_on := 2 ** (_MAX_NUMBER_OF_COMBINATIONS + 1) - 1
            
            for not_used, timer in this.timers
            {
                timer_function := timer.function
                timer_delay := timer.delay
                
                SetTimer, % timer_function, % timer_delay
            }
        }
            
    }
    
    ResetTimer(index)
    {
        timer_function := this.timers[index].function
        SetTimer, % timer_function, Off
        SetTimer, % timer_function, On
    }
}