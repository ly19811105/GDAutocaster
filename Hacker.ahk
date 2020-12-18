#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Hacker extends Common.ConfigSection
{
    spam_prevention := false
    speed_index := 1

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _HACKER_SECTION_NAME)
    
        this.SectionRead(key, "speed_toggle")
        this.SectionRead(speeds_str, "speeds", _HACKER_DEFAULT_SPEEDS)
        
        if (Common.Configured(key, speeds_str))
        {
            speeds := StrSplit(speeds_str, ",")
            
            hotkeys_collector.AddHotkey(key
                , ObjBindMethod(this
                    , "toggleSpeed"
                    , speeds))
                    
            hotkeys_collector.AddHotkey(key . " UP"
                , ObjBindMethod(this, "toggleSpeedUP"))
        }
        
    }
    
    toggleSpeed(speeds)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention)
            return
    
        this.spam_prevention := true
        speed := speeds[this.speed_index]
        
        RunWait, %A_ScriptDir%\%_HACKER_PROGRAM_NAME% %_HACKER_SPEED_CODE% %speed%,,Hide
        
        this.speed_index += 1
        if (this.speed_index > speeds.Length())
            this.speed_index := 1
    }
    
    toggleSpeedUP()
    {
        this.spam_prevention := false
    }
}