#Include Defaults.ahk

class HotkeysCollector
{
    functionDictionary := {}
    
    AddHotkey(key, function, block_native := false)
    {
        if (!this.functionDictionary.HasKey(key))
        {
            this.functionDictionary[key] := [function]
            fn := ObjBindMethod(this, "CallFunctions", key)
            
            modifiers := block_native 
                ? _HOTKEY_MODIFIERS_NATIVE_FUNCTION_BLOCKED
                : _HOTKEY_MODIFIERS
                
            Hotkey, % modifiers . key, %fn%, On
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

