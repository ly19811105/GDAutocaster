#include Common.ahk
#include Defaults.ahk
#Include HotkeysCollector.ahk

class AutocastByToggle extends Common.ConfigSection
{
    any_timer_on := 0
    timers := {}
    autocast_on_launch := false
    current_buttons := {}
    
    __New(config_name
        , hotkeys_collector
        , autocast_right_away
        , autocast_prev_state)
    {
        Common.ConfigSection.__New(config_name, _AUTOCAST_BY_TOGGLE_SECTION_NAME)
        this.SectionRead(delay, "delay", _AUTOCAST_BY_TOGGLE_DELAY)
        this.SectionRead(autocast_on_launch
            , "autocast_on_launch"
            , _AUTOCAST_BY_TOGGLE_ON_LAUNCH)
            
        this.autocast_on_launch := autocast_on_launch
        
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(cast_str, "cast" . A_INDEX)
            this.SectionRead(delay%A_INDEX%, "delay" . A_INDEX, delay)
            this.SectionRead(not_hold_keys_str, "not_hold_keys" . A_INDEX)
            this.SectionRead(reset_key, "reset_key" . A_INDEX)
            this.SectionRead(alternate%A_INDEX%
                , "alternate" . A_INDEX
                , _AUTOCAST_BY_TOGGLE_ALTERNATE)
                    
            toggle_key := StrSplit(cast_str, ":")[1]
            keys_pressed := StrSplit(cast_str, ":")[2]
            keys_pressed := StrSplit(keys_pressed, ",")
            
            not_hold_keys := Common.Configured(not_hold_keys_str) 
                ? StrSplit(not_hold_keys_str, ",") 
                : []
            
            if (Common.Configured(delay%A_INDEX%
                , not_hold_keys
                , toggle_key
                , keys_pressed
                , alternate%A_INDEX%))
            {
                if (alternate%A_INDEX%)
                    this.current_buttons[A_INDEX] := 1
            
                hotkeys_collector.AddHotkey(toggle_key, ObjBindMethod(this, "ToggleTimer", A_INDEX))
                    
                if (Common.Configured(reset_key))
                    hotkeys_collector.AddHotkey(reset_key, ObjBindMethod(this, "ResetTimer", A_INDEX))
                
                timer := {}
                timer.delay := delay%A_INDEX%
                timer.function := ObjBindMethod(this
                    , "PressButton"
                    , keys_pressed
                    , not_hold_keys
                    , alternate%A_INDEX% ? A_INDEX : 0)
                    
                this.timers[A_INDEX] := timer
            }
        }
        
        if (autocast_right_away or autocast_prev_state)
            this.ToggleAllTimers()
    }
    
    ToggleTimer(index)
    {
        global window_ids
        if (!Common.IfActive(window_ids))
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

    PressButton(keys_pressed, not_hold_keys, index)
    {
        global window_ids
        
        if (Common.IfActive(window_ids)
            and (not_hold_keys.Length() = 0 
                or !Common.AnyPressed(not_hold_keys)))
        {
            if (index)
            {
                key := keys_pressed[this.current_buttons[index]]
                Send {%key%}
                this.current_buttons[index] := 1 + Mod(this.current_buttons[index], keys_pressed.Length())
            }
            else
                Common.PressButtons(keys_pressed)
        }
    }
    
    ToggleAllTimers()
    {
        global window_ids
        if (!Common.IfActive(window_ids))
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
            for index, not_used in this.timers
                this.ToggleTimer(index)
        }
            
    }
    
    ResetTimer(index)
    {
        global window_ids
        if (!Common.IfActive(window_ids))
            return

        bit_mask := 2**index
        if (this.any_timer_on & bit_mask)
        {
            timer_function := this.timers[index].function
            SetTimer, % timer_function, Off
            SetTimer, % timer_function, On
        }
    }
}