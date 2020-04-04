Configured(keys*)
{
    for not_used, key in keys
        if (key = "ERROR" or key = "")
            return false
        
    return true
}

StrToBool(str_bool)
{
    if (str_bool = "true")
        return 1
        
    if (str_bool = "false")
        return 0
        
    return str_bool
}