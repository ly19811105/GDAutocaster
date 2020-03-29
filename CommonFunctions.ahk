Configured(keys*)
{
    for not_used, key in keys
        if (key = "ERROR" or key = "")
            return false
        
    return true
}