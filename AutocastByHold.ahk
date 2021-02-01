#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include DPActivator.ahk 
#Include HotkeysCollector.ahk

class AutocastByHold extends Common.ConfigSection
{
    spam_prevention := {}
    dp_activators := {}
    delayed_activators := {}

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _AUTOCAST_BY_HOLD_SECTION_NAME)
        
        this.SectionRead(delay, "delay", _AUTOCAST_BY_HOLD_IN_BETWEEN_DELAY)
        
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(cast_str, "cast" . A_INDEX)
            this.SectionRead(delay%A_INDEX%, "delay" . A_INDEX, delay)
            this.SectionRead(initial_delay, "initial_delay" . A_INDEX, _AUTOCAST_BY_HOLD_INITIAL_DELAY)
            this.SectionRead(double_press, "double_press" . A_INDEX, _AUTOCAST_BY_HOLD_DOUBLE_PRESS)
            this.SectionRead(inner_delay, "inner_delay" . A_INDEX, _AUTOCAST_BY_HOLD_INNER_DELAY)
            
            this.SectionRead(key_native_function
                , "key_native_function" . A_INDEX
                , _AUTOCAST_BY_HOLD_KEY_NATIVE_FUNCTION)
            
            if (!Common.Configured(cast_str
                , initial_delay
                , delay%A_INDEX%
                , double_press
                , inner_delay))
                continue
                
            cast_str := StrSplit(cast_str, ":")
            held_keys_str := cast_str.RemoveAt(1)
            held_keys := StrSplit(held_keys_str, ",")
            pressed_keys := StrSplit(cast_str[1], ",")
            first_key := held_keys[held_keys.Length()]
            
            this.spam_prevention[A_INDEX] := false
            
            first_function := ObjBindMethod(this
                , "HoldCast"
                , pressed_keys
                , delay%A_INDEX%
                , held_keys
                , A_INDEX
                , inner_delay
                , false)
                
            first_function_up := ObjBindMethod(this, "HoldCastUP", A_INDEX)
            
            if (initial_delay > 0)
            {
                delayed_activator := new DelayedActivator(first_function
                    , initial_delay
                    , first_function_up)
                    
                this.delayed_activators[A_INDEX] := delayed_activator
                
                first_function := ObjBindMethod(delayed_activator, "Press")
                first_function_up := ObjBindMethod(delayed_activator, "KillPressUP")
            }
            
            if (double_press)
            {
                this.SectionRead(time_gap
                    , "double_press_time_gap" . A_INDEX
                    , _DOUBLE_PRESS_TIME_GAP)
                    
                dp_activator := new DPActivator(first_function
                    , time_gap
                    , first_function_up)
                    
                this.dp_activators[A_INDEX] := dp_activator
            
                first_function := ObjBindMethod(dp_activator, "Press")
                first_function_up := ObjBindMethod(dp_activator, "PressUP")
            }
            
            hotkeys_collector.AddHotkey(first_key
                , first_function
                , !key_native_function)
                
            hotkeys_collector.AddHotkey(first_key . " UP"
                , first_function_up
                , !key_native_function)
        }
    }
    
    HoldCast(pressed_keys
        , delay
        , held_keys
        , index
        , inner_delay
        , ongoing)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or (!ongoing and this.spam_prevention[index])
        or !Common.Pressed(held_keys))
            return
            
        this.spam_prevention[index] := true
            
        Common.PressButtons(pressed_keys, inner_delay, held_keys)
        
        if (ongoing)
            SetTimer,, -%delay%
        else
        {
            fn := ObjBindMethod(this
                , "HoldCast"
                , pressed_keys
                , delay
                , held_keys
                , index
                , inner_delay
                , true)
            
            SetTimer, %fn%, -%delay%
        }
    }
    
    HoldCastUP(index)
    {
        this.spam_prevention[index] := false
    }
}
