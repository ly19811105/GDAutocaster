#Include Common.ahk
#Include Defaults.ahk
#Include DPActivator.ahk
#Include HotkeysCollector.ahk

class ComboHolds extends Common.ConfigSection
{
    dp_activators := {}
    hold_states := {}
    spam_prevention := {}
    
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _COMBO_HOLDS_SECTION_NAME)
        
        this.SectionRead(initial_delay, "initial_delay", _COMBO_HOLDS_DELAY_FROM_PRESS_TO_HOLD)
    
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(combo_str, "combo" . A_INDEX)
            
            this.SectionRead(initial_delay%A_INDEX%
                , "initial_delay" . A_INDEX
                , initial_delay)
                
            this.SectionRead(key_native_function
                , "key_native_function" . A_INDEX
                , _COMBO_HOLDS_KEY_NATIVE_FUNCTION)
                
            this.SectionRead(double_press
                , "double_press" . A_INDEX
                , _COMBO_HOLDS_HOLD_ON_DOUBLE_PRESS)

            double_press := Common.StrToBool(double_press)
            key_native_function := Common.StrToBool(key_native_function)
            
            if (!Common.Configured(combo_str
                , double_press
                , initial_delay%A_INDEX%
                , key_native_function))
                continue
                
            combo_keys := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys.RemoveAt(1)
            
            this.hold_states[A_INDEX] := false
            this.spam_prevention[A_INDEX] := false
            
            combo_hold := ObjBindMethod(this
                , "ComboHold"
                , combo_keys
                , initial_delay%A_INDEX%
                , A_INDEX)
                
            combo_hold_up := ObjBindMethod(this, "ComboHoldUp", combo_keys, A_INDEX)
            
            if (!double_press)
            {
                hotkeys_collector.AddHotkey(combo_key
                    , combo_hold
                    , !key_native_function)

                hotkeys_collector.AddHotkey(combo_key . " UP"
                    , combo_hold_up
                    , !key_native_function)
            }
            else
            {
                this.SectionRead(time_gap
                    , "double_press_time_gap" . A_INDEX
                    , _DOUBLE_PRESS_TIME_GAP)
                    
                dp_activator := new DPActivator(combo_hold, time_gap, combo_hold_up)
                this.dp_activators[A_INDEX] := dp_activator
                
                hotkeys_collector.AddHotkey(combo_key
                    , ObjBindMethod(dp_activator, "Press")
                    , !key_native_function)
                    
                hotkeys_collector.AddHotkey(combo_key . " UP"
                    , ObjBindMethod(dp_activator, "PressUP")
                    , !key_native_function)
            }
        }
    }
    
    ComboHold(combo_keys, initial_delay, index)
    {
        global window_ids
        
        if (!Common.IfActive(window_ids)
        or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := true
        
        this.hold_states[index] := true
        fn := ObjBindMethod(this, "StillHeld", index, combo_keys)
        SetTimer, %fn%, -%initial_delay%
    }

    ComboHoldUp(combo_keys, index)
    {
        global window_ids
        if (!Common.IfActive(window_ids))
            return
        
        this.hold_states[index] := false
        
        for not_used, key in combo_keys
            Send {%key% up}
            
        this.spam_prevention[index] := false
    }

    StillHeld(index, combo_keys)
    {
        if (!this.hold_states[index])
            return
        
        for not_used, key in combo_keys
            Send {%key% down}
    }
}
