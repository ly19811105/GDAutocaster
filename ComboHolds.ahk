#Include CommonFunctions.ahk
#Include HotkeysCollector.ahk

class ComboHolds
{
    just_pressed := false
    
    __New(config_name, hotkeys_collector)
    {
        Loop, 9
        {
            IniRead, combo_str, % config_name, combo holds, combo%A_INDEX%
            IniRead, double_press, % config_name, combo holds, double_press%A_INDEX%, 0
            
            if (double_press = "true")
                double_press := 1
            
            if (double_press = "false")
                double_press := 0
            
            if (!Configured(combo_str, double_press))
                continue
                
            combo_keys := StrSplit(combo_str, [":", ","])
            combo_key := combo_keys.RemoveAt(1)

            if (double_press)
            {
                IniRead, double_press_time_gap, % config_name, combo holds, double_press%A_INDEX%_time_gap, 250
                if (!Configured(double_press_time_gap))
                {
                    MsgBox, Missing "double_press_time_gap" in the config, i.e. double_press_time_gap=250 in [combo holds] section.
                    ExitApp
                }    
                
                hotkeys_collector.AddHotkey("*" . combo_key, ObjBindMethod(this, "ComboHoldDouble", combo_key, combo_keys, double_press_time_gap))
            }
            else
                hotkeys_collector.AddHotkey("*" . combo_key, ObjBindMethod(this, "ComboHold", combo_key, combo_keys))

            hotkeys_collector.AddHotkey("*" . combo_key . " UP", ObjBindMethod(this, "ComboHoldUp", combo_keys))
        }
    }
    
    ComboHold(combo_key, combo_keys)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
        
        KeyWait, %combo_key%, T0.05
        if ErrorLevel
        {
            for not_used, key in combo_keys
                Send {%key% down}
        }
    }

    ComboHoldUp(combo_keys)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
            
        for not_used, key in combo_keys
            Send {%key% up}
    }

    ComboHoldDouble(combo_key, combo_keys, double_press_time_gap)
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
            this.ComboHold(combo_key, combo_keys)

    }

    ComboHoldDoubleTimer()
    {
        ComboHolds.just_pressed := false
    }
}

