#Include Defaults.ahk

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
                
            Common.StrToBool(output_var)
            return Common.Configured(output_var)
        }
    }
    
    AnyPressed(keys)
    {
        for not_used, key in keys
            if (!InStr(key, _WHEEL_ID) and GetKeyState(key, "P"))
                return true
        
        return false
    }
    
    PressButtonsTimer(pressed_keys, inner_delay, held_keys)
    {
        global window_ids
        if(!Common.IfActive(window_ids)
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
            if (!InStr(key, _WHEEL_ID) and !GetKeyState(key, "P"))
                return false
        
        return true
    }
    
    StrToBool(ByRef str_bool)
    {
        if (str_bool = "true")
            str_bool := 1
            
        if (str_bool = "false")
            str_bool := 0
    }
    
    IfActive(window_ids)
    {
        for not_used, id in window_ids
            if (WinActive(id))
                return id
                
        return ""
    }
    
    IfExist(window_ids)
    {
        for not_used, id in window_ids
            if (WinExist(id))
                return true
                
        return false
    }
    
    MoveMouse(X, Y)
    {
        DllCall("SetCursorPos", "int", X, "int", Y)
    }
    
    PressModKeyPair(pair)
    {
        modifier := pair[1]
        key := pair[2]
        Send %modifier%{%key%}
    }
    
    LogToFile(lines*)
    {
        for index, line in lines
            FileAppend, %line%`n, % _LOG_PATH
            
        FileAppend, `n, % _LOG_PATH 
    }
}
