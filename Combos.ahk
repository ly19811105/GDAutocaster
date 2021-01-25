#Include Common.ahk
#Include Defaults.ahk
#Include DPActivator.ahk
#Include HotkeysCollector.ahk

class Combos extends Common.ConfigSection
{
    spam_protection := {}
    combo_in_progress := {}
    dp_activators := {}
    
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
        
            double_press := Common.StrToBool(double_press)
            stop_on_release := Common.StrToBool(stop_on_release)
            key_native_function := Common.StrToBool(key_native_function)
            
            if (!Common.Configured(combo_str
                , initial_delay%A_INDEX%
                , stop_on_release
                , delay%A_INDEX%
                , double_press
                , key_native_function))
                continue
            
            combo_keys := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys.RemoveAt(1)
                
            this.spam_protection[A_INDEX] := false
            this.combo_in_progress[A_INDEX] := false
            
            combo_press := ObjBindMethod(this
                , "ComboPress"
                , delay%A_INDEX%
                , combo_keys
                , initial_delay%A_INDEX%
                , A_INDEX
                , combo_key
                , stop_on_release)
                
            combo_press_up := ObjBindMethod(this, "ComboPressUP", A_INDEX)
            
            if (!double_press)
            {
                hotkeys_collector.AddHotkey(combo_key
                    , combo_press
                    , !key_native_function)
                    
                hotkeys_collector.AddHotkey(combo_key . " UP"
                    , combo_press_up
                    , !key_native_function)
            }
            else 
            {
                this.SectionRead(time_gap
                    , "double_press_time_gap" . A_INDEX
                    , _DOUBLE_PRESS_TIME_GAP)
                    
                dp_activator := new DPActivator(combo_press, time_gap, combo_press_up)
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
    
    ComboPress(delay
        , keys
        , initial_delay
        , index
        , key
        , stop_on_release)
    {
        global window_ids
        
        if(!Common.IfActive(window_ids)
        or this.spam_protection[index]
        or this.combo_in_progress[index])
            return
            
        this.spam_protection[index] := true
        this.combo_in_progress[index] := true

        keys := keys.Clone()
        
        if (!initial_delay)
        {
            first_key := keys.RemoveAt(1)
            Send {%first_key%}
            
            next_delay := delay
        }
        else
            next_delay := initial_delay
        
        fn := ObjBindMethod(this
            , "ComboTimer"
            , delay
            , keys
            , key
            , stop_on_release
            , index)
        
        SetTimer, %fn%, -%next_delay%
    }
    
    ComboTimer(delay
        , keys
        , key
        , stop_on_release
        , index)
    {   
        global window_ids
        
        if (!Common.IfActive(window_ids)
        or (keys.Length() = 0)
        or (stop_on_release and !GetKeyState(key, "P")))
        {
            this.combo_in_progress[index] := false
            return
        }
        
        key := keys.RemoveAt(1)
        Send {%key%}
        SetTimer,, -%delay% 
    }

    ComboPressUP(index)
    {
        this.spam_protection[index] := false
    }
}






