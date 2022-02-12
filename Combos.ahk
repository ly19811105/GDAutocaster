#Include Common.ahk
#Include Defaults.ahk
#Include DelayedActivator.ahk
#Include DPActivator.ahk
#Include HotkeysCollector.ahk

class Combos extends Common.ConfigSection
{
    pressed_down := {}
    combo_in_progress := {}
    dp_activators := {}
    delayed_activators := {}
    spam_protection := {}
    
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _COMBOS_SECTION_NAME)
        
        this.SectionRead(delay, "delay", _COMBOS_IN_BETWEEN_DELAY)
        this.SectionRead(initial_delay, "initial_delay", _COMBOS_INITIAL_DELAY)
        
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.SectionRead(combo_str, "combo" . A_INDEX)
            this.SectionRead(delay%A_INDEX%, "delay" . A_INDEX, delay)
            this.SectionRead(initial_delay%A_INDEX%, "initial_delay" . A_INDEX, initial_delay)
            this.SectionRead(stop_on_release, "stop_on_release" . A_INDEX, _COMBOS_STOP_ON_RELEASE)
            this.SectionRead(double_press, "double_press" . A_INDEX, _COMBOS_DOUBLE_PRESS)
            this.SectionRead(key_native_function
                , "key_native_function" . A_INDEX
                , _COMBOS_KEY_NATIVE_FUNCTION)
        
            if (!Common.Configured(combo_str
                , initial_delay%A_INDEX%
                , stop_on_release
                , delay%A_INDEX%
                , double_press
                , key_native_function))
                continue
            
            combo_keys_tmp := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys_tmp.RemoveAt(1)
            is_wheel := InStr(combo_key, _WHEEL_ID)
            
            combo_keys := []
            for index, key in combo_keys_tmp
            {
                temp_split := StrSplit(key, ["+", "!", "#", "^"])
                modifiers := SubStr(key, 1, temp_split.Length()-1)
                trimmed_key := SubStr(key, temp_split.Length())
                combo_keys.Push([modifiers, trimmed_key])
            }
                
            this.pressed_down[A_INDEX] := false
            this.combo_in_progress[A_INDEX] := false
            this.spam_protection[A_INDEX] := !is_wheel
            
            first_function := ObjBindMethod(this
                , "ComboPress"
                , delay%A_INDEX%
                , combo_keys
                , A_INDEX
                , combo_key
                , stop_on_release)
                
            first_function_up := ObjBindMethod(this, "ComboPressUP", A_INDEX)
                
            if (initial_delay%A_INDEX% > 0)
            {
                delayed_activator := new DelayedActivator(first_function
                    , initial_delay%A_INDEX%
                    , first_function_up
                    , !is_wheel)
                    
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
                    , first_function_up
                    , !is_wheel)
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
    
    ComboPress(delay
        , combo_keys
        , index
        , combo_key
        , stop_on_release)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or (this.spam_protection[index] and this.pressed_down[index])
        or this.combo_in_progress[index]
        or (stop_on_release and !GetKeyState(combo_key, "P")))
        {
            return
        }

        this.pressed_down[index] := true
        this.combo_in_progress[index] := true
        
        combo_keys := combo_keys.Clone()
        Common.PressModKeyPair(combo_keys.RemoveAt(1))

        fn := ObjBindMethod(this
            , "ComboLoop"
            , delay
            , combo_keys
            , index
            , combo_key
            , stop_on_release)
        
        SetTimer, %fn%, -%delay%
}
    
    ComboLoop(delay
        , combo_keys
        , index
        , combo_key
        , stop_on_release)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
        or (stop_on_release and !GetKeyState(combo_key, "P")))
        {
            this.combo_in_progress[index] := false
            return
        }

        Common.PressModKeyPair(combo_keys.RemoveAt(1))

        if (combo_keys.Length() = 0)
        {
            this.combo_in_progress[index] := false
            return
        }
        
        SetTimer,, -%delay%
    }

    ComboPressUP(index)
    {
        this.pressed_down[index] := false
    }
}






