#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include DPActivator.ahk
#Include HotkeysCollector.ahk

class ToggleHolds extends Common.ConfigSection
{
    dp_activators := {}
    spam_prevention := {}
    delayed_activators := {}
    states := {}
    
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _TOGGLE_HOLDS_SECTION_NAME)

        this.SectionRead(initial_delay, "initial_delay", _TOGGLE_HOLDS_INITIAL_DELAY)
        this.SectionRead(key_native_function
            , "key_native_function"
            , _TOGGLE_HOLDS_KEY_NATIVE_FUNCTION)
                
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(toggle_str, "toggle" . A_INDEX)
            
            this.SectionRead(initial_delay%A_INDEX%
                , "initial_delay" . A_INDEX
                , initial_delay)
                
            this.SectionRead(key_native_function%A_INDEX%
                , "key_native_function" . A_INDEX
                , key_native_function)
                
            this.SectionRead(double_press
                , "double_press" . A_INDEX
                , _TOGGLE_HOLDS_ON_DOUBLE_PRESS)

            if (!Common.Configured(toggle_str
                , double_press
                , initial_delay%A_INDEX%
                , key_native_function%A_INDEX%))
                continue        
                
            toggle_keys := StrSplit(toggle_str, [":", ","])
            toggle_key := toggle_keys.RemoveAt(1)
            
            this.spam_prevention[A_INDEX] := false
            this.states[A_INDEX] := false
            
            first_function := ObjBindMethod(this
                , "ToggleHold"
                , toggle_keys
                , A_INDEX)
            
            first_function_up := ObjBindMethod(this, "ToggleHoldUp", A_INDEX)
            
            if (initial_delay%A_INDEX% > 0)
            {
                delayed_activator := new DelayedActivator(first_function
                    , initial_delay%A_INDEX%
                    , first_function_up)
                    
                this.delayed_activators[A_INDEX] := delayed_activator
                
                first_function := ObjBindMethod(delayed_activator, "Press")
                first_function_up := ObjBindMethod(delayed_activator, "PressUP")
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
            
            hotkeys_collector.AddHotkey(toggle_key
                , first_function
                , !key_native_function)

            hotkeys_collector.AddHotkey(toggle_key . " UP"
                , first_function_up
                , !key_native_function)
        }
    }
    
    ToggleHold(toggle_keys, index)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := true
        
        direction := this.states[index] ? "up" : "down"
        for not_used, key in toggle_keys
            Send {%key% %direction%}
            
        this.states[index] ^= true
    }

    ToggleHoldUp(index)
    {
        this.spam_prevention[index] := false
    }
}
