#Include Common.ahk

class Clicker extends Common.ConfigSection
{
    spam_protection := {}

    class Click
    {
        __New(x, y, is_left := true)
        {
            this.x := x
            this.y := y
            this.is_left := is_left
        }
    }

    Clicking(clicks
        , delay
        , repeat
        , translation
        , clicks_copy
        , go_back
        , return_point
        , total_translation)
    {
        global window_ids
        if(!Common.IfActive(window_ids))
            return
        
        click := clicks_copy.RemoveAt(1)
        MouseClick, % click.is_left ? "Left" : "Right"
            , % click.x + total_translation.x
            , % click.y + total_translation.y,, 0
        
        if (clicks_copy.Length() = 0)
        {
            if (repeat = 0)
            {
                if (go_back)
                    MouseMove, return_point.x, return_point.y, 0
                    
                Return
            }
            else
            {
                clicks_copy := clicks.Clone()
                repeat -= 1
                total_translation.x += translation.x
                total_translation.y += translation.y
            }
        }
        
        fn := ObjBindMethod(this
            , "Clicking"
            , clicks
            , delay
            , repeat
            , translation
            , clicks_copy
            , go_back
            , return_point
            , total_translation)
            
        SetTimer, %fn%, -%delay%
    }
    
    ClickingUP(index)
    {
        this.spam_protection[index] := false
    }
}