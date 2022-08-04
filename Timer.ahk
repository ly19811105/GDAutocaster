class Timer
{
    isOn := false

    __New(delay, function)
    {
        this.delay := delay
        this.function := function
    }
    
    Start()
    {
        this.function.Call()
    
        this.isOn := true
        function := this.function
        delay := this.delay
        
        SetTimer, % function, % delay
    }
    
    Stop()
    {
        function := this.function
        SetTimer, % function, Off
        this.isOn := false
    }
    
    Loop(N, initial_delay := 0, loop_finish := 0)
    {
        this.isOn := true
        
        if (initial_delay > 0)
        {
            fn := ObjBindMethod(this, "LoopPrivate", N, 1, loop_finish)
            SetTimer, %fn%, -%initial_delay%
        }
        else
            this.LoopPrivate(N, 1, loop_finish)
    }
    
    LoopPrivate(N, i, loop_finish)
    {
        this.function.Call(i)
        
        if (i < N)
        {
            fn := ObjBindMethod(this, "LoopPrivate", N, i+1, loop_finish)
            delay := this.delay
            SetTimer, %fn%, -%delay%
        }
        else
        {
            if IsObject(loop_finish)
                loop_finish.Call()
                
            this.isOn := false
        }
    }
}