#include Common.ahk
#Include Defaults.ahk
#Include DPActivator.ahk 
#Include HotkeysCollector.ahk

class AutocastByHold extends Common.ConfigSection
{
    spam_prevention := {}
    dp_activators := {}

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
            
            double_press := Common.StrToBool(double_press)
            key_native_function := Common.StrToBool(key_native_function)
            
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
            
            hold_cast := ObjBindMethod(this
                , "HoldCast"
                , pressed_keys
                , delay%A_INDEX%
                , held_keys
                , A_INDEX
                , initial_delay
                , inner_delay)
                
            hold_cast_up := ObjBindMethod(this, "HoldCastUP", A_INDEX)
            
            if (!double_press)
            {
                hotkeys_collector.AddHotkey(first_key
                    , hold_cast
                    , !key_native_function)
                    
                hotkeys_collector.AddHotkey(first_key . " UP"
                    , hold_cast_up
                    , !key_native_function)
            }
            else 
            {
                this.SectionRead(time_gap
                    , "double_press_time_gap" . A_INDEX
                    , _DOUBLE_PRESS_TIME_GAP)
                    
                dp_activator := new DPActivator(hold_cast, time_gap, hold_cast_up)
                this.dp_activators[A_INDEX] := dp_activator
            
                hotkeys_collector.AddHotkey(first_key
                    , ObjBindMethod(dp_activator, "Press")
                    , !key_native_function)
                    
                hotkeys_collector.AddHotkey(first_key . " UP"
                    , ObjBindMethod(dp_activator, "PressUP")
                    , !key_native_function)
            }
        }
    }
    
    HoldCast(pressed_keys
        , delay
        , held_keys
        , index
        , initial_delay
        , inner_delay)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := true
        
        if (!Common.Pressed(held_keys))
            return
        
        fn := ObjBindMethod(this
            , "HoldCastTimer"
            , pressed_keys
            , held_keys
            , delay
            , inner_delay)
        
        if (initial_delay = 0)
        {
            Common.PressButtons(pressed_keys, inner_delay, held_keys)
            SetTimer, %fn%, -%delay%
        }
        else
            SetTimer, %fn%, -%initial_delay%
    }
    
    HoldCastTimer(pressed_keys, held_keys, delay, inner_delay)
    {
        if (!Common.Pressed(held_keys))
            Return
        
        Common.PressButtons(pressed_keys, inner_delay, held_keys)
        
        fn := ObjBindMethod(this
            , "HoldCastTimer"
            , pressed_keys
            , held_keys
            , delay
            , inner_delay)
        
        SetTimer, %fn%, -%delay%
    }
    
    HoldCastUP(index)
    {
        this.spam_prevention[index] := false
    }
}
