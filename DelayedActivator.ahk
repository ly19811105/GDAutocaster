#Include Common.ahk

class DelayedActivator
{
    __New(function, delay, function_up)
    {
        this.function := function
        this.function_up := function_up
        this.delay := delay
        this.spam_prevention := false
    }
        
    Press()
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or this.spam_prevention)
            return
            
        this.spam_prevention := true
            
        fn := this.function
        SetTimer, %fn%, % -this.delay
    }
    
    PressUP()
    {
        this.function_up.Call()
        this.spam_prevention := false
    }
    
    KillPressUP()
    {
        fn := this.function
        SetTimer, %fn%, Off
        this.PressUP()
    }
}