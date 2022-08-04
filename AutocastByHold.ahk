#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include DPActivator.ahk 
#Include HotkeysCollector.ahk
#Include Timer.ahk

class AutocastByHold extends Common.ConfigSection
{
    pressing_timers := {}
    dp_activators := {}
    delayed_activators := {}
    timed_out := {}

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _AUTOCAST_BY_HOLD_SECTION_NAME)
        
        this.SectionRead(delay, "delay", _AUTOCAST_BY_HOLD_IN_BETWEEN_DELAY)
        this.SectionRead(key_native_function, "key_native_function", _AUTOCAST_BY_HOLD_KEY_NATIVE_FUNCTION)
        
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(cast_str, "cast" . A_INDEX)
            this.SectionRead(delay%A_INDEX%, "delay" . A_INDEX, delay)
            this.SectionRead(initial_delay, "initial_delay" . A_INDEX, _AUTOCAST_BY_HOLD_INITIAL_DELAY)
            this.SectionRead(double_press, "double_press" . A_INDEX, _AUTOCAST_BY_HOLD_DOUBLE_PRESS)
            this.SectionRead(inner_delay, "inner_delay" . A_INDEX, _AUTOCAST_BY_HOLD_INNER_DELAY)
            this.SectionRead(time_out, "time_out" . A_INDEX, _AUTOCAST_BY_HOLD_TIME_OUT)
            this.SectionRead(key_native_function%A_INDEX%, "key_native_function" . A_INDEX, key_native_function)
            
            if (!Common.Configured(cast_str
                , initial_delay
                , delay%A_INDEX%
                , double_press
                , inner_delay
                , time_out))
                continue
                
            cast_str := StrSplit(cast_str, ":")
            held_keys_str := cast_str.RemoveAt(1)
            held_keys := StrSplit(held_keys_str, ",")
            pressed_keys := StrSplit(cast_str[1], ",")
            first_key := held_keys[held_keys.Length()]
            
            this.timed_out[A_INDEX] := false
            
            key_pressed_function := ObjBindMethod(this
                , "Start"
                , held_keys
                , A_INDEX)
                
            this.pressing_timers[A_INDEX] := new Timer(delay%A_INDEX%
                , ObjBindMethod(this
                    , "PressingButtons"
                    , held_keys
                    , pressed_keys
                    , inner_delay
                    , time_out
                    , A_INDEX))
            
            key_released_function := ObjBindMethod(this.pressing_timers[A_INDEX], "Stop")
            
            if (initial_delay > 0)
            {
                delayed_activator := new DelayedActivator(key_pressed_function
                    , initial_delay
                    , key_released_function)
                    
                this.delayed_activators[A_INDEX] := delayed_activator
                
                key_pressed_function := ObjBindMethod(delayed_activator, "Press")
                key_released_function := ObjBindMethod(delayed_activator, "KillPressUP")
            }
            
            if (double_press)
            {
                this.SectionRead(time_gap
                    , "double_press_time_gap" . A_INDEX
                    , _DOUBLE_PRESS_TIME_GAP)
                    
                dp_activator := new DPActivator(key_pressed_function
                    , time_gap
                    , key_released_function)
                    
                this.dp_activators[A_INDEX] := dp_activator
            
                key_pressed_function := ObjBindMethod(dp_activator, "Press")
                key_released_function := ObjBindMethod(dp_activator, "PressUP")
            }
            
            hotkeys_collector.AddHotkey(first_key
                , key_pressed_function
                , !key_native_function%A_INDEX%)
                
            hotkeys_collector.AddHotkey(first_key . " UP"
                , key_released_function
                , !key_native_function%A_INDEX%)
        }
    }
    
    Start(held_keys, index)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or this.pressing_timers[index].isOn
        or !Common.Pressed(held_keys))
            return
        
        this.pressing_timers[index].Start()
    }
    
    PressingButtons(held_keys, pressed_keys, inner_delay, time_out, index)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or !Common.Pressed(held_keys))
            Return
    
        if (time_out <= 0)
        {
            Common.PressButtons(pressed_keys, inner_delay, held_keys)
        }
        else if (!this.timed_out[index])
        {
            this.timed_out[index] := true
            
            fn := ObjBindMethod(this, "TimeIn", index)
            SetTimer,  %fn%, -%time_out%
            
            Common.PressButtons(pressed_keys, inner_delay, held_keys)
        }   
    }
    
    TimeIn(index)
    {
        this.timed_out[index] := false
    }
}
