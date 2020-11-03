#include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class AutocastByHold
{
    spam_prevention := []
    just_pressed := []

    __New(config_name, hotkeys_collector)
    {
        IniRead, delay, % config_name, % _AUTOCAST_BY_HOLD_SECTION_NAME, delay, % _AUTOCAST_BY_HOLD_IN_BETWEEN_DELAY
        Loop, %_MAX_NUMBER_OF_COMBINATIONS%
        {
            IniRead, cast_str, % config_name, % _AUTOCAST_BY_HOLD_SECTION_NAME, cast%A_INDEX%
            IniRead, delay%A_INDEX%, % config_name, % _AUTOCAST_BY_HOLD_SECTION_NAME, delay%A_INDEX%, % delay
            IniRead, initial_delay, % config_name, % _AUTOCAST_BY_HOLD_SECTION_NAME, initial_delay%A_INDEX%, % _AUTOCAST_BY_HOLD_INITIAL_DELAY
            IniRead, double_press, % config_name, % _AUTOCAST_BY_HOLD_SECTION_NAME, double_press%A_INDEX%, % _AUTOCAST_BY_HOLD_DOUBLE_PRESS
            IniRead, inner_delay, % config_name, % _AUTOCAST_BY_HOLD_SECTION_NAME, inner_delay%A_INDEX%, % _AUTOCAST_BY_HOLD_INNER_DELAY
            
            double_press := Common.StrToBool(double_press)
            
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
            
            if (!double_press)
            {
                hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key
                    , ObjBindMethod(this
                        , "HoldCast"
                        , pressed_keys
                        , delay%A_INDEX%
                        , held_keys
                        , A_INDEX
                        , initial_delay
                        , inner_delay))
            }
            else
            {
                IniRead
                    , double_press_time_gap
                    , % config_name
                    , % _AUTOCAST_BY_HOLD_SECTION_NAME
                    , double_press%A_INDEX%_time_gap
                    , % _AUTOCAST_BY_HOLD_DOUBLE_PRESS_TIME_GAP
                
                if (Common.Configured(double_press_time_gap))
                    hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key
                        , ObjBindMethod(this
                            , "HoldCastDouble"
                            , double_press_time_gap
                            , pressed_keys
                            , delay%A_INDEX%
                            , held_keys
                            , A_INDEX
                            , initial_delay
                            , inner_delay))
            }
                
            hotkeys_collector.AddHotkey(_HOTKEY_MODIFIERS . first_key . " UP"
                , ObjBindMethod(this, "HoldCastUP", A_INDEX))    
            
            this.spam_prevention.Push(0)
            this.just_pressed.Push(false)
        }

    }
    
    HoldCast(pressed_keys, delay, held_keys, index, initial_delay, inner_delay)
    {
        global game_window_id
        if(!WinActive(game_window_id) or this.spam_prevention[index])
            return
            
        this.spam_prevention[index] := 1
        
        if (!Common.Pressed(held_keys))
            return
        
        if (initial_delay = 0)
        {
            Common.PressButtons(pressed_keys, inner_delay)
            
            fn := ObjBindMethod(this, "HoldCastTimer", pressed_keys, held_keys, inner_delay)
            SetTimer, %fn%, %delay%
        }
        else
        {
            fn := ObjBindMethod(this, "HoldCastInitialTimer", pressed_keys, held_keys, delay, inner_delay)
            SetTimer, %fn%, -%initial_delay%
        }
    }
    
    HoldCastInitialTimer(pressed_keys, held_keys, delay, inner_delay)
    {
        if (!Common.Pressed(held_keys))
            Return
        
        Common.PressButtons(pressed_keys, inner_delay)
        
        fn := ObjBindMethod(this, "HoldCastTimer", pressed_keys, held_keys, inner_delay)
        SetTimer, %fn%, %delay%
    }
    
    HoldCastTimer(pressed_keys, held_keys, inner_delay)
    {
        if (!Common.Pressed(held_keys))
        {
            SetTimer,, Off
            Return
        }
        
        Common.PressButtons(pressed_keys, inner_delay)
    }
    
    HoldCastUP(index)
    {
        this.spam_prevention[index] := 0
    }
    
    HoldCastDouble(double_press_time_gap, pressed_keys, delay, held_keys, index, initial_delay, inner_delay)
    {
        global game_window_id
        if (!WinActive(game_window_id))
            return
            
        if (!this.just_pressed[index])
        {
            this.just_pressed[index] := true
            fn := ObjBindMethod(this, "HoldCastDoubleTimer", index)
            SetTimer, %fn%, -%double_press_time_gap%
        }
        else
            this.HoldCast(pressed_keys, delay, held_keys, index, initial_delay, inner_delay)
    }
    
    HoldCastDoubleTimer(index)
    {
        this.just_pressed[index] := false
    }
}
