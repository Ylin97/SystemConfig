# Linux 系统配置项

## Shell 配置 

- 启用 `zsh` 作为用户登录 shell  
- 安装&配置 `zim` 或者 `oh-my-zsh` 
- 配置 `c/c++ vscodeTemplate`  
- 配置 `hitokoto` (每日一言)  

### 自定义配置

### bash/zsh

配置文件路径：`~/.bashrc`、`~/.zshrc`。

```bash
# >>> yalin settings >>>
# Platform type
if [[ -n "$MSYSTEM" ]]; then
    environment="MSYS2"
elif [[ -f /proc/version && $(cat /proc/version) =~ microsoft ]]; then
    environment="WSL"
elif [[ -f /proc/version && $(cat /proc/version) =~ Linux ]]; then
    environment="Linux"
else
    environment="Unknown"
fi

# hitokoto
if [[ "$environment" == "MSYS2" ]]; then
    python ~/Autorun/hitokoto_lolcat.py
elif [[ "$environment" == "WSL" || "$environment" == "Linux" ]]; then
    eval $HOME/.local/bin/hitokoto
fi

# Windows
if [[ "$environment" == "WSL" ]]; then
    export PATH="$PATH:/mnt/c/Users/yalin/AppData/Local/Microsoft/WindowsApps"
    export PATH="$PATH:/mnt/c/WINDOWS"
    export PATH="$PATH:/mnt/d/Program Files/Microsoft VS Code/bin"
fi

# Proxy setting
test -s ~/.proxyrc && . ~/.proxyrc || true
# <<< yalin settings <<<
```

**注意！Windows第一条环境变量要修改用户名！**

### fish (config.fish)

配置文件路径：`~/.config/fish/config.fish `。

```fish
# >>> yalin settings >>>
# Platform type
if set -q MSYSTEM
    set environment "MSYS2"
else if test -f /proc/version
    set kernel_version (cat /proc/version)
    if string match -q "*microsoft*" $kernel_version
        set environment "WSL"
    else if string match -q "*Linux*" $kernel_version
        set environment "Linux"
    else
        set environment "Unknown"
    end
else
    set environment "Unknown"
end

# hitokoto
if test "$environment" = "MSYS2"
    python ~/Autorun/hitokoto_lolcat.py
else if test "$environment" = "WSL" -o "$environment" = "Linux"
    eval $HOME/.local/bin/hitokoto_lolcat
end

# Windows PATH adjustments for WSL
if test "$environment" = "WSL"
    fish_add_path --append --path "/mnt/c/Users/ASUS/AppData/Local/Microsoft/WindowsApps"
    fish_add_path --append --path "/mnt/c/WINDOWS"
    fish_add_path --append --path "/mnt/d/Program Files/Microsoft VS Code/bin"
end

# Proxy setting
if test -s ~/.proxyrc
    source ~/.proxyrc
end
# <<< yalin settings <<<
```

**注意！Windows第一条环境变量要修改用户名！**

## 必装软件 

- linuxqq
- chrome
- clash-verge
- v2raya
- vscode
- mpv
- Miniconda