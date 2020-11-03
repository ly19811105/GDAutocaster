class Common
{
    Configured(keys*)
    {
        for not_used, key in keys
            if (key = "ERROR" or key = "")
                return false
            
        return true
    }

    StrToBool(str_bool)
    {
        if (str_bool = "true")
            return 1
            
        if (str_bool = "false")
            return 0
            
        return str_bool
    }
    
    Pressed(keys)
    {
        for not_used, key in keys
            if (!GetKeyState(key, "P"))
                return false
        
        return true
    }
    
    PressButtons(pressed_keys, inner_delay := 0)
    {
        if (inner_delay = 0)
            for not_used, key in pressed_keys
                Send {%key%}
                
        else if (pressed_keys.Length() > 0)
        {
            pressed_keys := pressed_keys.Clone()
            first_key := pressed_keys.RemoveAt(1)
            Send {%first_key%}
            
            fn := ObjBindMethod(Common, "PressButtonsTimer", pressed_keys, inner_delay)
            SetTimer, %fn%, -%inner_delay%
        }
    }
    
    PressButtonsTimer(pressed_keys, inner_delay)
    {
        global game_window_id
        if(!WinActive(game_window_id)
        or (pressed_keys.Length() = 0))
            return
    
        key := pressed_keys.RemoveAt(1)
        Send {%key%}
        SetTimer,, -%inner_delay% 
    }
        
    AnyPressed(keys)
    {
        for not_used, key in keys
            if (GetKeyState(key, "P"))
                return true
        
        return false
    }
}
