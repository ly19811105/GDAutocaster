#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include DPActivator.ahk
#Include HotkeysCollector.ahk

class ComboHolds extends Common.ConfigSection
{
    dp_activators := {}
    spam_prevention := {}
    delayed_activators := {}
    
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
            
            this.spam_prevention[A_INDEX] := false
            
            first_function := ObjBindMethod(this
                , "ComboHold"
                , combo_keys
                , A_INDEX)
            
            first_function_up := ObjBindMethod(this, "ComboHoldUp", combo_keys, A_INDEX)
            
            if (initial_delay%A_INDEX% > 0)
            {
                delayed_activator := new DelayedActivator(first_function
                    , initial_delay%A_INDEX%
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
            
            hotkeys_collector.AddHotkey(combo_key
                , first_function
                , !key_native_function)

            hotkeys_collector.AddHotkey(combo_key . " UP"
                , first_function_up
                , !key_native_function)
        }
    }
    
    ComboHold(combo_keys, index)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := true
        
        for not_used, key in combo_keys
            Send {%key% down}
    }

    ComboHoldUp(combo_keys, index)
    {
        Loop % combo_keys.Length()
        {
            key := combo_keys[combo_keys.Length() - A_INDEX + 1]
            Send {%key% up}
        }
        
        this.spam_prevention[index] := false
    }
}
