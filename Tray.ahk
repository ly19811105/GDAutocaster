class Tray
{
    load_config_action := ObjBindMethod(this, "LoadConfigAction")
    restart_action := ObjBindMethod(this, "RestartAction")
    exit_action := ObjBindMethod(this, "ExitAction")
    config_label := ObjBindMethod(this, "ConfigLabel")

    __New()
    {
        Menu, Tray, Icon , *, -1, 1
        Menu, Tray, NoStandard
        
        load_config_action := this.load_config_action
        Menu, Tray, Add, Load Config, % load_config_action
        
        restart_action := this.restart_action
        Menu, Tray, Add, Restart, % restart_action
        
        exit_action := this.exit_action
        Menu, Tray, Add, Exit, % exit_action
        
        config_label := this.config_label
        Menu, Tray, Insert, Load Config, Config not loaded, % config_label
        Menu, Tray, Insert, Load Config
        Menu, Tray, Disable, Config not loaded
        Menu, Tray, Default, Config not loaded
    }
    
    ConfigLabel()
    {
    }
    
    LoadConfigAction()
    {
        Run % A_ScriptFullPath
        ExitApp
    }
    
    RestartAction()
    {
        global config_name
        if (config_name = "")
        {
            this.LoadConfigAction()
            ExitApp
        }
        
        Run, %A_ScriptFullPath% "%config_name%"
    }

    ExitAction()
    {
        ExitApp
    }
    
    DisplayConfigName()
    {
        global config_name
        SplitPath, config_name,,,, config_shortname
        
        config_label := this.config_label
        Menu, Tray, Rename, Config not loaded, % config_shortname
    }
}