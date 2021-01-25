#Include Common.ahk

class DPActivator extends Common.ConfigSection
{
    __New(function, time_gap, function_up)
    {
        this.just_pressed := false
        this.function := function
        this.time_gap := time_gap
        this.spam_prevention := false
        this.function_up := function_up
    }
        
    Press()
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention)
            return
            
        this.spam_prevention := true
            
        if (!this.just_pressed)
        {
            this.just_pressed := true
            fn := ObjBindMethod(this, "PressTimer")
            SetTimer, %fn%, % -this.time_gap
        }
        else
            this.function.Call()
    }
    
    PressTimer()
    {
        this.just_pressed := false
    }
    
    PressUP()
    {
        this.function_up.Call()
        this.spam_prevention := false
    }
}