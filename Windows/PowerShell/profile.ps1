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

#region 每日一言
function hitokoto 
{
    #D:\\Miniconda3\\python -u $HOME\hitokoto.py | lolcat
    D:\\Miniconda3\\python -u $HOME\hitokoto_lolcat.py
}

hitokoto
#endregion 每日一言

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


#region 获取Windows的IP用于设置wsl2代理
function Get-IP
{
    # 设置文件路径
    $filePath = "D:\wslShare\.windows_ip_info"

    # 如果文件不存在，创建文件
    if (-not (Test-Path $filePath)) {
        New-Item -Path $filePath -ItemType File
    }

    # 设置文件为隐藏属性
    Set-ItemProperty -Path $filePath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)

    Get-NetIPAddress -AddressFamily IPv4 | select InterfaceAlias, IPv4Address | Set-Content -Path $filePath -Encoding utf8
}

Get-IP
#endregion

#region proxy setting
$host_ip = "127.0.0.1"
function setproxy_http
{
    param (
        $port = "Unknown"
    )
    $Env:https_proxy = "http://${host_ip}:$port"
    $Env:http_proxy  = "http://${host_ip}:$port"

    git config --global https.proxy "http://${host_ip}:$port"
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

function setproxy { setproxy_http 7897 }
function setproxy-v { setproxy_http 10809 }
function setproxy-c { setproxy_http 7897 }
function setproxy-sv { setproxy_socks 10808 }
function setproxy-sc { setproxy_socks 7897 }
#endregion

#region OPENAI SETTING
$Env:OPENAI_API_BASE="https://chat.openai.com/v1"
$Env:OPENAI_API_HOST="https://chat.openai.com"
#$Env:OPENAI_API_KEY=""

function askgpt {
    sgpt @args
}

function chatgpt {
    D:\Miniconda3\envs\chatgpt\python.exe -u 'D:\Portable Program Files\gpt-cli\gpt.py' @args
}
#endregion

#region ModernCpp
function New-CppProject {
    <#
      初始化 CMake + Ninja + vcpkg + VS Code 项目
      默认模板：$env:USERPROFILE\.vscode\template\ModernCpp
    #>

    param(
        [string]$TemplatePath = "$env:USERPROFILE\.vscode\template\ModernCpp",
        [string]$ProjectNameRaw = (Split-Path -Leaf (Get-Location))
    )

    #──────────────── 0. 规范化项目名 ────────────────
    $ProjectName = $ProjectNameRaw.ToLower() -replace '[ _]', '-' -replace '[^a-z0-9\-]', ''
    if ($ProjectName -ne $ProjectNameRaw) {
        Write-Host "⚠️ 项目名 [$ProjectNameRaw] 已规范化为 [$ProjectName] 以符合 vcpkg 要求。" -ForegroundColor DarkYellow
    }

    #──────────────── 1. 可用工具检测 ────────────────
    $tools = @{
        git   = (Get-Command git   -EA SilentlyContinue)
        cmake = (Get-Command cmake -EA SilentlyContinue)
        vcpkg = (Get-Command vcpkg -EA SilentlyContinue)
    }

    foreach ($kvp in $tools.GetEnumerator()) {
        if (-not $kvp.Value) { Write-Warning "未找到 $($kvp.Key)，相关步骤将被跳过。" }
    }

    #──────────────── 2. 复制模板 ───────────────────
    if (-not (Test-Path $TemplatePath)) {
        Write-Error "模板路径 [$TemplatePath] 不存在"; return
    }

    Copy-Item "$TemplatePath\\*" . -Recurse -Force -EA Stop

    #──────────────── 3. 占位符替换 & 文件重命名 ──
    # 1) 替换文件内容中的 example → 项目名
    Get-ChildItem -Recurse -File -Include *.cpp,*.h,*.txt,*.cmake,CMakeLists.txt,vcpkg.json |
        ForEach-Object {
            (Get-Content $_.FullName) -replace '\bexample\b', $ProjectName |
                Set-Content $_.FullName
        }

    # 2) 头文件改名
    $oldHeader = "src\include\example.h"
    if (Test-Path $oldHeader) {
        $newLeaf   = "$ProjectName.h"               # 仅文件名
        $newHeader = "src\include\$newLeaf"         # 完整路径备用

        Rename-Item -Path $oldHeader -NewName $newLeaf   # 在同目录重命名

        # 同步 main.cpp 的 #include "…"
        $includeNew = '"' + $newLeaf + '"'
        (Get-Content "src\source\main.cpp") `
            -replace '"example\.h"', $includeNew |
            Set-Content "src\source\main.cpp"
    }

    #──────────────── 4. vcpkg manifest ─────────────
    if ($tools.vcpkg) {
        $vcpkgExe     = $tools.vcpkg.Source
        $haveManifest = Test-Path vcpkg.json

        if ($haveManifest) {
            Write-Host "已存在 vcpkg.json，跳过 vcpkg new。" -ForegroundColor DarkYellow
        }
        else {
            $nameArg = "--name=$ProjectName"
            $versionArg = "--version=0.1.0"

            $vcpkgArgs = @(
                "new",
                $nameArg,
                $versionArg
            )

            Write-Host "▶ 运行: $vcpkgExe $($vcpkgArgs -join ' ')" -ForegroundColor Yellow
            & $vcpkgExe @vcpkgArgs
        }
    }

    #──────────────── 5. Git 初始提交 ───────────────
    if ($tools.git) {
        if (-not (Test-Path '.git')) { git init | Out-Null }
        git add . 2>$null
        git commit -m "Initialized $ProjectName project." 2>$null
    }

    #──────────────── 6. 打开 VS Code ───────────────
    if (Get-Command code -EA SilentlyContinue) {
        $main = "src\\source\\main.cpp"
        & code ($main -as [string])
    }

    Write-Host "✅ [$ProjectName] 初始化完成！" -ForegroundColor Green
}
#endregion
