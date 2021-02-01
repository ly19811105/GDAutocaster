#Include Common.ahk
#Include Defaults.ahk
#Include HotkeysCollector.ahk

class Hacker extends Common.ConfigSection
{
    spam_prevention := false
    speed_index := 1
    stats_state := 0

    __New(config_name, hotkeys_collector)
    {
        Common.ConfigSection.__New(config_name, _HACKER_SECTION_NAME)
    
        this.SectionRead(speed_toggle, "speed_toggle")
        this.SectionRead(speeds_str, "speeds", _HACKER_DEFAULT_SPEEDS)
        this.SectionRead(hacker_dir, "hacker_dir", A_ScriptDir)
        this.SectionRead(stats_toggle, "stats_toggle")
        this.SectionRead(freeze_tributes, "freeze_tributes", _FREEZE_TRIBUTES)
        
        if (!Common.Configured(hacker_dir))
            return
        
        if (Common.Configured(speed_toggle, speeds_str))
        {
            speeds := StrSplit(speeds_str, ",")
            
            hotkeys_collector.AddHotkey(speed_toggle
                , ObjBindMethod(this
                    , "ToggleSpeed"
                    , speeds
                    , hacker_dir))
                    
            hotkeys_collector.AddHotkey(speed_toggle . " UP"
                , ObjBindMethod(this, "ButtonUP"))
        }
        
        if (Common.Configured(freeze_tributes) and freeze_tributes)
            this.FreezeTributes(hacker_dir)
            
        if (Common.Configured(stats_toggle))
        {
            hotkeys_collector.AddHotkey(stats_toggle
                , ObjBindMethod(this, "ToggleStats", hacker_dir))
                
            hotkeys_collector.AddHotkey(stats_toggle . " UP"
                , ObjBindMethod(this, "ButtonUP"))
        }
    }
    
    ToggleSpeed(speeds, hacker_dir)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention)
            return
    
        this.spam_prevention := true
        
        speed := speeds[this.speed_index]
        RunWait, %hacker_dir%\%_HACKER_PROGRAM_NAME% %_HACKER_SPEED_CODE% %speed%,,Hide
        
        this.speed_index += 1
        if (this.speed_index > speeds.Length())
            this.speed_index := 1
    }
    
    FreezeTributes(hacker_dir)
    {
        global window_ids
        if (!Common.IfActive(window_ids))
            return
    
        RunWait, %hacker_dir%\%_HACKER_PROGRAM_NAME% %_HACKER_FREEZE_CODE%,,Hide
    }
    
    ToggleStats(hacker_dir)
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention)
            return
    
        this.spam_prevention := true
        
        this.stats_state ^= 1
        stats_state := this.stats_state
        RunWait, %hacker_dir%\%_HACKER_PROGRAM_NAME% %_HACKER_STATS_CODE% %stats_state%,,Hide
    }
    
    ButtonUP()
    {
        this.spam_prevention := false
    }
}
