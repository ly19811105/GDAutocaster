#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class ComboHolds extends Common.ConfigSection
{
    just_pressed := false
    hold_states := []
    spam_prevention := []
    
    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _COMBO_HOLDS_SECTION_NAME)
    
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.hold_states.Push(false)
        
            this.SectionRead(combo_str, "combo" . A_INDEX)
            
            this.SectionRead(delay
                , "delay" . A_INDEX
                , _COMBO_HOLDS_DELAY_FROM_PRESS_TO_HOLD)
                
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
                , delay
                , key_native_function))
                continue
                
            combo_keys := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys.RemoveAt(1)
            
            hotkey_modifiers := key_native_function 
                ? _HOTKEY_MODIFIERS 
                : _HOTKEY_MODIFIERS_NATIVE_FUNCTION_BLOCKED

            if (double_press)
            {
                this.SectionRead(double_press_time_gap
                    , "double_press" . A_INDEX . "_time_gap"
                    , _COMBO_HOLDS_DOUBLE_PRESS_TIME_GAP)
            
                if (Common.Configured(double_press_time_gap))
                    hotkeys_collector.AddHotkey(hotkey_modifiers . combo_key
                        , ObjBindMethod(this
                            , "ComboHoldDouble"
                            , combo_keys
                            , double_press_time_gap
                            , delay
                            , A_INDEX))
            }
            else
                hotkeys_collector.AddHotkey(hotkey_modifiers . combo_key
                    , ObjBindMethod(this
                        , "ComboHold"
                        , combo_keys
                        , delay
                        , A_INDEX))

            hotkeys_collector.AddHotkey(hotkey_modifiers . combo_key . " UP"
                , ObjBindMethod(this, "ComboHoldUp", combo_keys, A_INDEX))
            
            this.spam_prevention.Push(0)
        }
    }
    
    ComboHold(combo_keys, delay, index)
    {
        global game_window_id
        
        if (!WinActive(game_window_id)
        or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := true
        
        this.hold_states[index] := true
        fn := ObjBindMethod(this, "StillHeld", index, combo_keys)
        SetTimer, %fn%, -%delay%
    }

    ComboHoldUp(combo_keys, index)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
        
        this.hold_states[index] := false
        
        for not_used, key in combo_keys
            Send {%key% up}
            
        this.spam_prevention[index] := false
    }

    ComboHoldDouble(combo_keys, double_press_time_gap, delay, index)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
            
        if (!ComboHolds.just_pressed)
        {
            ComboHolds.just_pressed := true
            fn := ObjBindMethod(this, "ComboHoldDoubleTimer")
            SetTimer, %fn%, -%double_press_time_gap%
        }
        else
            this.ComboHold(combo_keys, delay, index)

    }

    ComboHoldDoubleTimer()
    {
        ComboHolds.just_pressed := false
    }
    
    StillHeld(index, combo_keys)
    {
        if (!this.hold_states[index])
            return
        
        for not_used, key in combo_keys
            Send {%key% down}
    }
}
