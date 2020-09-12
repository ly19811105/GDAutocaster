#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class ComboHolds
{
    just_pressed := false
    hold_states := []
    
    __New(config_name, hotkeys_collector)
    {
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            this.hold_states.Push(false)
            
            IniRead, combo_str, % config_name, combo holds, combo%A_INDEX%
            IniRead, delay, % config_name, combo holds, delay%A_INDEX%, % _COMBO_HOLDS_DELAY_FROM_PRESS_TO_HOLD
            
            IniRead, double_press, % config_name, combo holds, double_press%A_INDEX%, % _COMBO_HOLDS_HOLD_ON_DOUBLE_PRESS
            double_press := Common.StrToBool(double_press)
            
            if (!Common.Configured(combo_str, double_press, delay))
                continue
                
            combo_keys := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys.RemoveAt(1)

            if (double_press)
            {
                IniRead, double_press_time_gap, % config_name, combo holds, double_press%A_INDEX%_time_gap, % _COMBO_HOLDS_DOUBLE_PRESS_TIME_GAP
                if (Common.Configured(double_press_time_gap))
                    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key
                        , ObjBindMethod(this, "ComboHoldDouble", combo_keys, double_press_time_gap, delay, A_INDEX))
                
            }
            else
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key, ObjBindMethod(this, "ComboHold", combo_keys, delay, A_INDEX))

            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . combo_key . " UP", ObjBindMethod(this, "ComboHoldUp", combo_keys, A_INDEX))
        }
    }
    
    ComboHold(combo_keys, delay, index)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
        
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
