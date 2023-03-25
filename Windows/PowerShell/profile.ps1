# 设置控制台输入输出文本编码为 utf-8
# 参考 https://stackoverflow.com/questions/57131654/using-utf-8-encoding-chcp-65001-in-command-prompt-windows-powershell-window
#$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

function Init-conda
{
    #region conda initialize
    # !! Contents within this block are managed by 'conda init' !!
    (& "D:\Miniconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | Invoke-Expression
    #endregion
}

# 每日一言
D:\\Miniconda3\\python $HOME\hitokoto_lolcat.py

#region project initialize
function Init-project
{
    param (
        $ProjectType = 'Unknown'
    )
    $TemplatePathRoot = $HOME + "\.vscode\projectTemplate"
    $ResourcePath = switch ( $ProjectType ) 
    {
        'c' {
            $TemplatePathRoot + "\c\*"
        }
        'cpp' {
            $TemplatePathRoot + "\cpp\*"
        }
        default {
            "Unknown"
        }
    }
    Copy-Item -Path $ResourcePath -Destination "." -Recurse 
    if ( $? ) {
        if ( Get-Command "git" -errorAction SilentlyContinue ) {
            git init
            git add .
            git commit -m "Initialized a project."
        } else {
            Write-Host "WARN: 'git' command not found."
        }
        # open main file in vscode
        $MainFile = ".\source\main." + $ProjectType
        Code $MainFile
    }
}

function Reset-Vscode-Config
{
    param (
        $ProjectType = "Unknown"
    )
    
    $CurrentConfigPath = ".\.vscode"
    $TemplatePathRoot = $HOME + "\.vscode\projectTemplate"
    
    # remove the old configuration files
    $TRUE_FALSE = ( Test-Path $CurrentConfigPath )
    if ( $TRUE_FALSE -eq "True" ) {
        remove-Item -Recurse -Force $CurrentConfigPath
    }
    
    $ResourcePath = switch ( $ProjectType ) 
    {
        'c' {
            $TemplatePathRoot + "\c\.vscode"
        }
        'cpp' {
            $TemplatePathRoot + "\cpp\.vscode"
        }
        default {
            "Unknown"
        }
    }
    # reset configuration
    if ( $ResourcePath -ne 'Unknown') {
        Copy-Item -Path $ResourcePath -Destination "." -Recurse
        if ( $? ) {
            $msg = "Reset workspace's configuration for a " + $ProjectType +  " project seccussfully!"
            Write-Host $msg
        } else {
            Write-Host "Error: can't reset workspace configuration, please try again!"
        }
    }
}

function Init-c
{
    Init-project 'c'
}

function Init-cpp
{
    Init-project 'cpp'
}

function Reset-c
{
    Reset-Vscode-Config 'c'
}

function Reset-cpp
{
    Reset-Vscode-Config 'cpp'
}
#endregion


# 获取Windows的IP用于设置wsl2代理
Get-NetIPAddress -AddressFamily IPv4 | select InterfaceAlias, IPv4Address | Out-File D:\Code\wslWorkspace\.windows_ip_info -encoding utf8

#region proxy setting
$host_ip = "127.0.0.1"
function setproxy_http
{
    param (
        $port = "Unknown"
    )
    $Env:https_proxy = "${host_ip}:$port"
    $Env:http_proxy  = "${host_ip}:$port"

    git config --global https.proxy "https://${host_ip}:$port"
    git config --global http.proxy "http://${host_ip}:$port"
}

function setproxy_socks
{
    param (
        $port = "Unknown"
    )
    $Env:https_proxy = "socks5://${host_ip}:$port"
    $Env:http_proxy  = "socks5://${host_ip}:$port"

    git config --global https.proxy "socks5://${host_ip}:$port"
    git config --global http.proxy "socks5://${host_ip}:$port"
}

function unsetproxy
{
    $Env:https_proxy = ''
    $Env:http_proxy  = ''

    git config --global --unset http.proxy
    git config --global --unset https.proxy

}

function setproxy { setproxy_http 7890 }
function setproxy-v { setproxy_http 20172 }
function setproxy-c { setproxy_http 7890 }
function setproxy-sv { setproxy_socks 20170 }
function setproxy-sc { setproxy_socks 7890 }
#endregion