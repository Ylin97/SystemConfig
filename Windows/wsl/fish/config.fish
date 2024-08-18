if status is-interactive
    # Commands to run in interactive sessions can go here
    # Esc-Esc to sudo
end

##{{{ Windows binary path setting
fish_add_path -aP /mnt/c/Users/yalin/AppData/Local/Microsoft/WindowsApps
fish_add_path -aP "/mnt/d/Program Files/Microsoft VS Code/bin"
fish_add_path -aP /mnt/c/WINDOWS
##}}} End Window binary path setting

##{{{ Hitokoto 
~/Autorun/hitokoto_lolcat.py
##}}} End Hitokoto

##{{{ Proxy setting
source $HOME/.config/fish/functions/terminal_proxy.fish
##}}} End Proxy setting
