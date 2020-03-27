class HotkeysCollector
{
    functionDictionary := {}
    
    AddHotkey(key, function)
    {
        if (!this.functionDictionary.HasKey(key))
        {
            this.functionDictionary[key] := [function]
            fn := ObjBindMethod(this, "CallFunctions", key)
            Hotkey, %key%, %fn%, On
        }
        else
            this.functionDictionary[key].Push(function)
    }

    CallFunctions(key)
    {
        For not_used, function in this.functionDictionary[key]
            function.Call()
    }
}

