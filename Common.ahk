class Common
{
    class ConfigSection
    {
        __New(config_name, section_name)
        {
            this.config_name := config_name
            this.section_name := section_name
        }
        
        SectionRead(ByRef output_var, key, default_value = "ERROR")
        {
            IniRead
                , output_var
                , % this.config_name
                , % this.section_name
                , % key
                , % default_value
        }
    }
    
    AnyPressed(keys)
    {
        for not_used, key in keys
            if (GetKeyState(key, "P"))
                return true
        
        return false
    }
    
    PressButtonsTimer(pressed_keys, inner_delay, held_keys)
    {
        global game_window_id
        if(!WinActive(game_window_id)
        or (pressed_keys.Length() = 0)
        or !Common.Pressed(held_keys))
            return
    
        key := pressed_keys.RemoveAt(1)
        Send {%key%}
        SetTimer,, -%inner_delay% 
    }
        
    Configured(keys*)
    {
        for not_used, key in keys
            if (key = "ERROR" or key = "")
                return false
            
        return true
    }

    PressButtons(pressed_keys, inner_delay := 0, held_keys := 0)
    {
        ; [] cannot be a default argument unfortunately, watch out
    
        if (inner_delay = 0)
            for not_used, key in pressed_keys
                Send {%key%}
                
        else if (pressed_keys.Length() > 0)
        {
            pressed_keys := pressed_keys.Clone()
            first_key := pressed_keys.RemoveAt(1)
            Send {%first_key%}
            
            fn := ObjBindMethod(Common
                , "PressButtonsTimer"
                , pressed_keys
                , inner_delay
                , held_keys)
                
            SetTimer, %fn%, -%inner_delay%
        }
    }
    
    Pressed(keys)
    {
        for not_used, key in keys
            if (!GetKeyState(key, "P"))
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
}
