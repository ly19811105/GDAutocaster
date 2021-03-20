#Include Common.ahk

class DPActivator extends Common.ConfigSection
{
    __New(function
        , time_gap
        , function_up
        , spam_protection := true)
    {
        this.just_pressed := false
        this.function := function
        this.time_gap := time_gap
        this.spam_protection := spam_protection
        this.pressed_down := false
        this.function_up := function_up
    }
        
    Press()
    {
        global window_ids
        if (!Common.IfActive(window_ids)
        or (this.spam_protection and this.pressed_down))
            return
            
        this.pressed_down := true
            
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
        this.pressed_down := false
    }
}