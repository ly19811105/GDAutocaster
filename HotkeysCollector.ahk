#Include Defaults.ahk

class HotkeysCollector
{
    functionDict := {}
    
    AddHotkey(key, function, block_native := false)
    {
        if (!this.functionDict.HasKey(key))
        {
            this.functionDict[key]
                := {functions: [function]
                    , native_function: !block_native}
            
            fn := ObjBindMethod(this, "CallFunctions", key)
            
            modifiers := block_native 
                ? _HOTKEY_MODIFIERS_NATIVE_FUNCTION_BLOCKED
                : _HOTKEY_MODIFIERS
                
            Hotkey, % modifiers . key, %fn%, On
        }
        else
        {
            if (block_native = this.functionDict[key]["native_function"])
            {
                MsgBox,
                (LTrim
                Some functions bound to %key% differ in
                whether they allow %key% native function.
                )
                
                ExitApp
            }
            
            this.functionDict[key]["functions"].Push(function)
        }
    }

    CallFunctions(key)
    {
        For not_used, function in this.functionDict[key]["functions"]
            function.Call()
    }
}

