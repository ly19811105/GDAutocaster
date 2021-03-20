#Include Common.ahk

class DelayedActivator
{
    __New(function
        , delay
        , function_up
        , spam_protection := true)
    {
        this.function := function
        this.function_up := function_up
        this.delay := delay
        this.pressed_down := false
        this.spam_protection := spam_protection
    }
        
    Press()
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or (this.spam_protection and this.pressed_down))
            return
            
        this.pressed_down := true
            
        fn := this.function
        SetTimer, %fn%, % -this.delay
    }
    
    PressUP()
    {
        this.function_up.Call()
        this.pressed_down := false
    }
    
    KillPressUP()
    {
        fn := this.function
        SetTimer, %fn%, Off
        this.PressUP()
    }
}